import 'dart:isolate';
import 'dart:typed_data';

import 'package:falcon_gui/live_view/models/live_view_isolate_config.dart';

class PlotDrawer {
  static const int kAllocatedSampleBufferSize = 1024 * 1024;

  static final Map<String, Float64List> _historyBuffers = {};
  static final Map<String, Uint64List> _historyTimestamps =
      {}; // Circular timeline database
  static final Map<String, int> _historyWriteIndices = {};

  static void processNewBatch({
    required Uint8List raw,
    required SendPort sendPort,
    required Map<String, LiveViewRenderParams> renderParams,
    required int visibleSamples,
  }) {
    final byteData = ByteData.sublistView(raw);
    final totalLength = raw.length;
    var offset = 0;
    final accumulatedBuffers = <String, TransferableTypedData>{};

    while (offset < totalLength) {
      final addrLen = byteData.getUint8(offset++);
      final upstreamAddress = String.fromCharCodes(
        Uint8List.sublistView(raw, offset, offset + addrLen),
      );
      offset += addrLen;

      final payloadLen = byteData.getUint32(offset, Endian.little);
      offset += 4;
      final nextBlockOffset = offset + payloadLen;

      var streamOffset = offset;

      while (streamOffset < nextBlockOffset) {
        final typeLen = byteData.getUint8(streamOffset++);
        final typeName = String.fromCharCodes(
          Uint8List.sublistView(raw, streamOffset, streamOffset + typeLen),
        );
        streamOffset += typeLen;

        if (typeName == 'TimeSeriesType<double>') {
          final bufferSize = byteData.getUint32(streamOffset, Endian.little);
          streamOffset += 4;
          final nchannels = byteData.getUint32(streamOffset, Endian.little);
          streamOffset += 4;

          if (nchannels > 0 && bufferSize > 0) {
            final history = _historyBuffers.putIfAbsent(
              upstreamAddress,
              () => Float64List(kAllocatedSampleBufferSize * nchannels),
            );
            final tsHistory = _historyTimestamps.putIfAbsent(
              upstreamAddress,
              () => Uint64List(kAllocatedSampleBufferSize),
            );
            var writeIdx = _historyWriteIndices[upstreamAddress] ?? 0;

            final signalByteLength = bufferSize * nchannels * 8;
            final signalDataView = ByteData.sublistView(
              raw,
              streamOffset,
              streamOffset + signalByteLength,
            );
            streamOffset += signalByteLength;

            // Extract the hardware timestamps from your original model array structure
            final tsDataView = ByteData.sublistView(
              raw,
              streamOffset,
              streamOffset + (bufferSize * 8),
            );
            streamOffset += bufferSize * 8;

            // 1. Synchronized Ingestion
            for (var i = 0; i < bufferSize; i++) {
              final localRowOffset = i * nchannels * 8;
              final destRowOffset = writeIdx * nchannels;

              for (var ch = 0; ch < nchannels; ch++) {
                history[destRowOffset + ch] = signalDataView.getFloat64(
                  localRowOffset + (ch * 8),
                  Endian.little,
                );
              }

              // Map the clock stamp directly to this sequence window position
              tsHistory[writeIdx] = tsDataView.getUint64(i * 8, Endian.little);

              writeIdx = (writeIdx + 1) % kAllocatedSampleBufferSize;
            }
            _historyWriteIndices[upstreamAddress] = writeIdx;
          }
        } else {
          break;
        }
      }

      offset = nextBlockOffset;

      // 2. Render Loop with Timestamp Synchronization
      final p = renderParams[upstreamAddress] ?? const LiveViewRenderParams();
      final cols = p.renderWidth <= 0 ? 1000 : p.renderWidth.floor();
      final viewHeight = p.renderHeight <= 0 ? 250.0 : p.renderHeight;

      final writeIdx = _historyWriteIndices[upstreamAddress] ?? 0;
      final history = _historyBuffers[upstreamAddress];
      final tsHistory = _historyTimestamps[upstreamAddress];

      if (history != null && tsHistory != null && cols > 0) {
        final int totalChannels = history.length ~/ kAllocatedSampleBufferSize;
        final vertexBuffer = Float32List(cols * 4 * totalChannels);

        // Capture the hardware time of the latest sample that just arrived
        final lastWrittenIdx =
            (writeIdx - 1 + kAllocatedSampleBufferSize) %
            kAllocatedSampleBufferSize;
        final latestTime = tsHistory[lastWrittenIdx];

        // Deduce sample rate directly from real time differences to ensure precision
        final oldestInViewIdx =
            (writeIdx - visibleSamples + kAllocatedSampleBufferSize) %
            kAllocatedSampleBufferSize;
        final oldestTime = tsHistory[oldestInViewIdx];

        // Compute time quantum per pixel column
        final totalTimeSpan = latestTime - oldestTime;
        final timePerPixel = totalTimeSpan / cols;

        final rowHeight = viewHeight / totalChannels;
        final halfRow = rowHeight / 2;

        // Linear Search Strategy over circular bounds to align columns to strict time slots
        var historySearchIdx = oldestInViewIdx;

        for (var col = 0; col < cols; col++) {
          final int chOffsetBase = col * 4;
          final double x1 = col.toDouble();
          final double x2 = (col + 1).toDouble();

          // Target exact window time limits for this vertical pixel slot
          final targetTime1 = oldestTime + (col * timePerPixel).floor();
          final targetTime2 = oldestTime + ((col + 1) * timePerPixel).floor();

          // Walk forward until we match the closest actual sample timestamps
          while (tsHistory[historySearchIdx] < targetTime1 &&
              historySearchIdx != lastWrittenIdx) {
            historySearchIdx =
                (historySearchIdx + 1) % kAllocatedSampleBufferSize;
          }
          final idx1 = historySearchIdx;

          while (tsHistory[historySearchIdx] < targetTime2 &&
              historySearchIdx != lastWrittenIdx) {
            historySearchIdx =
                (historySearchIdx + 1) % kAllocatedSampleBufferSize;
          }
          final idx2 = historySearchIdx;

          final int flatIdx1 = idx1 * totalChannels;
          final int flatIdx2 = idx2 * totalChannels;

          for (var ch = 0; ch < totalChannels; ch++) {
            final int chOffset = (ch * cols * 4) + chOffsetBase;
            final double rowCenterY = (ch * rowHeight) + halfRow;

            final double y1 =
                rowCenterY - (history[flatIdx1 + ch] * p.yScaleMultiplier);
            final double y2 =
                rowCenterY - (history[flatIdx2 + ch] * p.yScaleMultiplier);

            vertexBuffer[chOffset] = x1;
            vertexBuffer[chOffset + 1] = y1;
            vertexBuffer[chOffset + 2] = x2;
            vertexBuffer[chOffset + 3] = y2;
          }
        }
        accumulatedBuffers[upstreamAddress] = TransferableTypedData.fromList([
          vertexBuffer,
        ]);
      }
    }

    if (accumulatedBuffers.isNotEmpty) {
      sendPort.send(LiveViewRenderData(batchRenderBuffers: accumulatedBuffers));
    }
  }
}

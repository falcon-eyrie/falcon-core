import 'dart:typed_data';

class SignalParser {
  static const int kAllocatedSampleBufferSize = 1024 * 1024;

  static final Map<String, Float64List> historyBuffers = {};
  static final Map<String, Uint64List> historyTimestamps = {};
  static final Map<String, int> historyWriteIndices = {};
  static final List<int> capturedEventTimestamps = [];

  static void parseRawPacket(Uint8List raw) {
    final byteData = ByteData.sublistView(raw);
    final totalLength = raw.length;
    var offset = 0;

    capturedEventTimestamps.clear();

    while (offset < totalLength) {
      final addrLen = byteData.getUint8(offset++);
      final upstreamAddress = String.fromCharCodes(
        Uint8List.sublistView(raw, offset, offset + addrLen),
      );
      offset += addrLen;

      final payloadLen = byteData.getUint32(offset, Endian.little);
      offset += 4;
      final envelopeEnd = offset + payloadLen;

      while (offset < envelopeEnd && offset < totalLength) {
        final typeLen = byteData.getUint8(offset++);
        final typeName = String.fromCharCodes(
          Uint8List.sublistView(raw, offset, offset + typeLen),
        );
        offset += typeLen;

        if (typeName == 'TimeSeriesType<double>') {
          final nsamples = byteData.getUint32(offset, Endian.little);
          offset += 4;
          final ncolumns = byteData.getUint32(offset, Endian.little);
          offset += 4;

          const byteWidth = 8;
          final signalBytes = nsamples * ncolumns * byteWidth;
          final tsBytes = nsamples * 8;

          if (ncolumns > 0 &&
              nsamples > 0 &&
              (offset + signalBytes + tsBytes <= totalLength)) {
            _ingestMatrixData(
              streamKey: upstreamAddress,
              nsamples: nsamples,
              ncolumns: ncolumns,
              byteWidth: byteWidth,
              signalData: ByteData.sublistView(
                raw,
                offset,
                offset + signalBytes,
              ),
              tsData: ByteData.sublistView(
                raw,
                offset + signalBytes,
                offset + signalBytes + tsBytes,
              ),
            );
          }
          offset += signalBytes + tsBytes;
        } else if (typeName == 'EventType') {
          final tsLen = byteData.getUint8(offset++);
          if (tsLen == 8) {
            capturedEventTimestamps.add(
              byteData.getUint64(offset, Endian.little),
            );
          }
          offset += tsLen;

          final eventLen = byteData.getUint16(offset, Endian.little);
          offset += 2 + eventLen;
        }
      }
      offset = envelopeEnd;
    }
  }

  static void _ingestMatrixData({
    required String streamKey,
    required int nsamples,
    required int ncolumns,
    required int byteWidth,
    required ByteData signalData,
    required ByteData tsData,
  }) {
    final history = historyBuffers.putIfAbsent(
      streamKey,
      () => Float64List(kAllocatedSampleBufferSize * ncolumns),
    );
    final tsHistory = historyTimestamps.putIfAbsent(
      streamKey,
      () => Uint64List(kAllocatedSampleBufferSize),
    );
    var writeIdx = historyWriteIndices[streamKey] ?? 0;

    for (var i = 0; i < nsamples; i++) {
      final localRowOffset = i * ncolumns * byteWidth;
      final destRowOffset = writeIdx * ncolumns;

      for (var ch = 0; ch < ncolumns; ch++) {
        final srcOffset = localRowOffset + (ch * byteWidth);
        if (byteWidth == 8) {
          history[destRowOffset + ch] = signalData.getFloat64(
            srcOffset,
            Endian.little,
          );
        } else if (byteWidth == 4) {
          history[destRowOffset + ch] = signalData.getFloat32(
            srcOffset,
            Endian.little,
          );
        } else {
          history[destRowOffset + ch] = signalData
              .getUint8(srcOffset)
              .toDouble();
        }
      }

      tsHistory[writeIdx] = tsData.getUint64(i * 8, Endian.little);
      writeIdx = (writeIdx + 1) % kAllocatedSampleBufferSize;
    }
    historyWriteIndices[streamKey] = writeIdx;
  }
}

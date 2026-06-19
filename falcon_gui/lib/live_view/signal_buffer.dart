import 'dart:typed_data';

import 'package:falcon_gui/live_view/falcon_ws_message.dart';

const int kAllocatedSampleBufferSize = 1024 * 1024;

class SignalBuffer {
  SignalBuffer({
    required this.nchannels,
    this.bufferSize = kAllocatedSampleBufferSize,
  }) : _flatBuffer = Float64List(bufferSize * nchannels),
       _timestampBuffer = Uint64List(
         bufferSize,
       );

  final int bufferSize;
  final int nchannels;
  final Float64List _flatBuffer;
  final Uint64List _timestampBuffer;

  final List<EventPayload> events = [];

  int _writeSampleIndex = 0;
  bool isBufferFull = false;

  Float64List get dataView => _flatBuffer;
  Uint64List get timestampView => _timestampBuffer;
  int get latestWriteIndex => _writeSampleIndex;

  void appendSignalBuffer(MultiChannelSignalPayload payload) {
    if (payload.nchannels != nchannels) return;

    final incomingSamples = payload.bufferSize;
    final incomingByteView = payload.multichannelBuffers;
    final incomingTimestamps = payload.timestamps;

    var incomingSampleRow = 0;
    var samplesLeftToCopy = incomingSamples;

    while (samplesLeftToCopy > 0) {
      final spaceToEnd = bufferSize - _writeSampleIndex;
      final samplesToCopyNow = samplesLeftToCopy < spaceToEnd
          ? samplesLeftToCopy
          : spaceToEnd;

      for (var s = 0; s < samplesToCopyNow; ++s) {
        final currentIncomingRow = incomingSampleRow + s;
        final currentDestRow = _writeSampleIndex + s;

        _timestampBuffer[currentDestRow] =
            incomingTimestamps[currentIncomingRow];

        // Cache the base offsets outside the inner channel loop
        // This saves millions of multiplication operations per second
        final srcRowByteOffset = currentIncomingRow * nchannels * 8;
        final destRowElementIndex = currentDestRow * nchannels;

        for (var ch = 0; ch < nchannels; ++ch) {
          // Direct, safe little-endian extraction with
          // zero indexing math overhead
          _flatBuffer[destRowElementIndex + ch] = incomingByteView.getFloat64(
            srcRowByteOffset + (ch * 8),
            Endian.little,
          );
        }
      }

      _writeSampleIndex = (_writeSampleIndex + samplesToCopyNow) % bufferSize;
      incomingSampleRow += samplesToCopyNow;
      samplesLeftToCopy -= samplesToCopyNow;

      if (_writeSampleIndex == 0) {
        isBufferFull = true;
      }
    }
  }
}

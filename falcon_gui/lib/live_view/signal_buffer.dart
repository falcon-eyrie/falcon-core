import 'dart:typed_data';

import 'package:falcon_gui/live_view/falcon_ws_message.dart';

const int kAllocatedSampleBufferSize = 16 * 1024 * 1024;

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
  Uint64List get timestampView => _timestampBuffer; // Public accessor
  int get latestWriteIndex => _writeSampleIndex;

  void appendSignalBuffer(MultiChannelSignalPayload payload) {
    if (payload.nchannels != nchannels) return;

    final incomingSamples = payload.bufferSize;
    final incomingByteView = payload.multichannelBuffers;
    final incomingTimestamps =
        payload.timestamps; // Get the synchronized timestamps

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

        for (var ch = 0; ch < nchannels; ++ch) {
          final srcByteOffset = ((currentIncomingRow * nchannels) + ch) * 8;
          final destElementIndex = (currentDestRow * nchannels) + ch;

          _flatBuffer[destElementIndex] = incomingByteView.getFloat64(
            srcByteOffset,
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

  void appendEvent(EventPayload payload) {
    final availableSamples = isBufferFull ? bufferSize : _writeSampleIndex;
    if (availableSamples != 0) {
      // Find the index of the most recently written data row
      final lastWrittenIndex =
          (_writeSampleIndex - 1 + bufferSize) % bufferSize;

      // Assign the exact hardware timestamp to the event
      payload.closestSampleTimestamp = _timestampBuffer[lastWrittenIndex];
    }

    events.add(payload);
    // if (events.length > 5000) {
    //   events.removeRange(0, 1000);
    // }
  }
}

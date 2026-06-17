import 'dart:typed_data';

class FalconWSMessage {
  const FalconWSMessage({
    required this.upstreamAddress,
    required this.payload,
  });

  factory FalconWSMessage.fromBytes(Uint8List rawBytes) {
    final byteData = ByteData.sublistView(rawBytes);
    var offset = 0;

    final addrLen = byteData.getUint8(offset++);
    final upstreamAddress = String.fromCharCodes(
      rawBytes.sublist(offset, offset + addrLen),
    );
    offset += addrLen;

    final typeLen = byteData.getUint8(offset++);
    final typeName = String.fromCharCodes(
      rawBytes.sublist(offset, offset + typeLen),
    );
    offset += typeLen;

    final payload = switch (typeName) {
      'TimeSeriesType<double>' => MultiChannelSignalPayload.fromBytes(
        byteData,
        rawBytes,
        offset,
      ),
      'EventType' => EventPayload.fromBytes(
        rawBytes,
        offset,
      ),
      _ => UnknownPayload.fromBytes(rawBytes, offset),
    };

    return FalconWSMessage(
      upstreamAddress: upstreamAddress,
      payload: payload,
    );
  }

  final String upstreamAddress;
  final FalconWSPayloadData payload;
}

sealed class FalconWSPayloadData {
  const FalconWSPayloadData();
}

/// Multi-channel time-series payload.
/// Channels are interleaved sequentially by sample row.
///
/// Matrix Layout:
///         | Ch 0 | Ch 1 | ...
///  Row 0  |  [0]  |  [1]  | ...
///  Row 1  |  [2]  |  [3]  | ...
///
/// Formula: index = (row * nchannels) + channel
class MultiChannelSignalPayload extends FalconWSPayloadData {
  const MultiChannelSignalPayload({
    required this.bufferSize,
    required this.nchannels,
    required this.multichannelBuffers,
    required this.timestamps,
  });

  factory MultiChannelSignalPayload.fromBytes(
    ByteData byteData,
    Uint8List rawBytes,
    int initialOffset,
  ) {
    var offset = initialOffset;

    final bufferSize = byteData.getUint32(offset, Endian.little);
    offset += 4;
    final nchannels = byteData.getUint32(offset, Endian.little);
    offset += 4;

    final signalByteLength = bufferSize * nchannels * 8;

    final multichannelBuffers = ByteData.sublistView(
      rawBytes,
      offset,
      offset + signalByteLength,
    );
    offset += signalByteLength;

    final timestamps = Uint64List(bufferSize);
    const sizeofUint64 = 8;

    for (var k = 0; k < bufferSize; ++k) {
      timestamps[k] = byteData.getUint64(offset, Endian.little);
      offset += sizeofUint64;
    }

    return MultiChannelSignalPayload(
      bufferSize: bufferSize,
      nchannels: nchannels,
      multichannelBuffers: multichannelBuffers,
      timestamps: timestamps,
    );
  }

  /// The total number of consecutive data samples collected per stream channel.
  final int bufferSize;

  /// The total number of independent streams or hardware channels recorded.
  final int nchannels;

  /// A flat, continuous binary view containing all channel data points.
  /// Values are packed sequentially in memory by sample rows.
  final ByteData multichannelBuffers;

  /// High-resolution 64-bit timestamps synchronized with each sample collection interval.
  final Uint64List timestamps;
}

class EventPayload extends FalconWSPayloadData {
  EventPayload({required this.eventName});

  factory EventPayload.fromBytes(Uint8List rawBytes, int initialOffset) {
    return EventPayload(
      eventName: String.fromCharCodes(rawBytes.sublist(initialOffset + 2)),
    );
  }

  final String eventName;

  // Add this mutable field to lock it to the data stream timeline
  int closestSampleTimestamp = 0;
}

class UnknownPayload extends FalconWSPayloadData {
  const UnknownPayload({required this.rawPayload});

  factory UnknownPayload.fromBytes(Uint8List rawBytes, int initialOffset) {
    return UnknownPayload(
      rawPayload: rawBytes.sublist(initialOffset),
    );
  }

  final Uint8List rawPayload;
}

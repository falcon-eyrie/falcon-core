class FalconLog {
  FalconLog({
    required this.timestamp,
    required this.type,
    required this.message,
  });

  factory FalconLog.fromZmqParts(List<String> logMessage) {
    return FalconLog(
      type: FalconLogType.fromString(logMessage[0]),
      timestamp: _parseTimestamp(logMessage[1]),
      message: logMessage[2],
    );
  }

  // Parsing logic for the timestamp, including the fractional part
  static DateTime _parseTimestamp(String timestampStr) {
    // example input "2026/01/12 16:26:28 803049"
    // Split the timestamp into date-time and fractional part
    try {
      final parts = timestampStr.split(' ');
      final dateTimeStr = '${parts[0]} ${parts[1]}'; // "2026/01/12 16:26:28"
      final fractionStr = parts[2]; // "803026" (microseconds)

      // Replace '/' with '-' for DateTime.parse compatibility
      final dateTime = DateTime.parse(
        dateTimeStr.replaceAll('/', '-'),
      );

      // Convert the fractional part into microseconds
      final microseconds = int.parse(fractionStr);

      // Return the DateTime with added microseconds
      return dateTime.add(Duration(microseconds: microseconds));
    } catch (_) {
      return DateTime(1970);
    }
  }

  final DateTime timestamp;
  final FalconLogType type;
  final String message;

  @override
  String toString() {
    return '[$timestamp] [$type] $message';
  }
}

enum FalconLogType {
  state,
  update,
  error,
  warning,
  info,
  fatal,
  unknown;

  factory FalconLogType.fromString(String typeStr) {
    switch (typeStr.toUpperCase()) {
      case 'STATE':
        return FalconLogType.state;
      case 'UPDATE':
        return FalconLogType.update;
      case 'ERROR':
        return FalconLogType.error;
      case 'WARNING':
        return FalconLogType.warning;
      case 'INFO':
        return FalconLogType.info;
      case 'FATAL':
        return FalconLogType.fatal;
      default:
        return FalconLogType.unknown;
    }
  }

  @override
  String toString() {
    switch (this) {
      case FalconLogType.state:
        return 'State';
      case FalconLogType.update:
        return 'Update';
      case FalconLogType.error:
        return 'Error';
      case FalconLogType.warning:
        return 'Warning';
      case FalconLogType.info:
        return 'Info';
      case FalconLogType.fatal:
        return 'Fatal';
      case FalconLogType.unknown:
        return 'Unknown';
    }
  }
}

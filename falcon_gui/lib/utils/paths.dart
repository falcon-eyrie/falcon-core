import 'dart:io';

String get ubuntuHomePath {
  return Platform.environment['HOME'] ?? '';
}

Directory get defaultGraphsDirectory =>
    Directory('$ubuntuHomePath/falcon/resources/graphs')
      ..createSync(recursive: true);

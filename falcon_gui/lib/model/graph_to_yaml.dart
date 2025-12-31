import 'package:falcon_gui/model/falcon_graph.dart';

extension FalconGraphYaml on FalconGraph {
  String toYaml() {
    final buffer = StringBuffer();

    for (final entry in processors.entries) {
      final processor = entry.value;
      final ui = processor.uiMetadata;

      buffer
        ..writeln('${processor.id}:')
        ..writeln('    class: ${processor.className}');

      if (processor.options.isNotEmpty) {
        buffer.writeln('    options:');
        for (final optEntry in processor.options.entries) {
          buffer.writeln(
            '        ${optEntry.key}: ${_yamlValue(optEntry.value.value)}',
          );
        }
      }

      buffer
        ..writeln('    ui:')
        ..writeln(
          '        position: { x: ${ui.position.dx}, y: ${ui.position.dy} }',
        )
        ..writeln(
          '        lastModified: "${ui.lastModified.toIso8601String()}"',
        );
      if (ui.color != null) {
        buffer.writeln(
          '        color: "#${ui.color!.toARGB32()}"',
        );
      }

      buffer.writeln();
    }

    if (connections.isNotEmpty) {
      buffer.writeln('connections:');
      for (final conn in connections) {
        buffer.writeln(
          '    ${conn.fromProcessor}.${conn.fromPort} = '
          '${conn.toProcessor}.${conn.toPort}',
        );
      }
    }

    return buffer.toString().trimRight();
  }

  String _yamlValue(Object? value) {
    if (value is String) {
      return '"${value.replaceAll('"', r'\"')}"';
    }
    if (value is bool || value is num) {
      return value.toString();
    }
    if (value == null) {
      return 'null';
    }
    return '"$value"';
  }
}

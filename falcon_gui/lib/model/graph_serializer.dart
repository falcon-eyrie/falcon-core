import 'package:falcon_gui/model/falcon_graph.dart';
import 'package:falcon_gui/state/processor_definitions.dart';
import 'package:flutter/material.dart';
import 'package:yaml/yaml.dart';

extension FalconGraphSerializerX on FalconGraph {
  String toYaml() {
    final buffer = StringBuffer();

    for (final processor in processors.values) {
      if (processor.isTemplate) continue;

      final ui = processor.uiMetadata;

      buffer
        ..writeln('${processor.id}:')
        ..writeln('    class: ${processor.className}');

      if (processor.options.isNotEmpty) {
        buffer.writeln('    options:');
        for (final entry in processor.options.entries) {
          buffer.writeln(
            '        ${entry.key}: ${_yamlScalar(entry.value.value)}',
          );
        }
      }

      buffer
        ..writeln('    ui:')
        ..writeln(
          '        position: { x: ${ui.position.dx.toInt()}, '
          'y: ${ui.position.dy.toInt()} }',
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

  String _yamlScalar(Object? value) {
    if (value is String) return '"${value.replaceAll('"', r'\"')}"';
    if (value is num || value is bool) return value.toString();
    if (value == null) return 'null';
    return '"$value"';
  }

  static FalconGraph fromYaml(String yamlString) {
    final doc = loadYaml(yamlString) as YamlMap;

    final processors = <String, Processor>{};
    final connections = <Connection>[];

    for (final entry in doc.entries) {
      final key = entry.key as String;

      if (key == 'connections') {
        final list = entry.value as YamlList;
        for (final line in list.cast<String>()) {
          final parts = line.split('=');
          final left = parts[0].trim().split('.');
          final right = parts[1].trim().split('.');

          connections.add(
            Connection(
              fromProcessor: left[0],
              fromPort: left[1],
              toProcessor: right[0],
              toPort: right[1],
            ),
          );
        }
        continue;
      }

      final map = entry.value as YamlMap;
      final className = map['class'] as String;

      final templateProcessor = processorDefinitions.values.firstWhere(
        (t) => t.className == className,
        orElse: () => throw FalconGraphYamlParserException(
          'Invalid processor class: $className. '
          'Only template processors are allowed.',
        ),
      );

      final options = <String, OptionValue<dynamic>>{};
      final optMap = map['options'] as YamlMap?;

      // Ensure all template options are provided
      for (final optEntry in templateProcessor.options.entries) {
        final name = optEntry.key;
        final templateOption = optEntry.value;
        if (optMap == null || !optMap.containsKey(name)) {
          throw FalconGraphYamlParserException(
            'Missing required option "$name" for processor "$className".',
          );
        }
        options[name] = _optionFromScalar(templateOption, optMap[name]);
      }

      var position = Offset.zero;
      var lastModified = DateTime(1970);
      Color? color;

      final uiMap = map['ui'] as YamlMap?;
      if (uiMap != null) {
        final pos = uiMap['position'] as YamlMap?;
        if (pos != null) {
          position = Offset(
            (pos['x'] as num).toDouble(),
            (pos['y'] as num).toDouble(),
          );
        }
        if (uiMap['lastModified'] != null) {
          lastModified = DateTime.parse(uiMap['lastModified'] as String);
        }
        if (uiMap['color'] != null) {
          final hex = (uiMap['color'] as String).replaceFirst('#', '');
          color = Color(int.parse(hex, radix: 16));
        }
      }

      processors[key] = Processor(
        id: key,
        className: className,
        options: options,
        inputPorts: List.of(templateProcessor.inputPorts),
        outputPorts: List.of(templateProcessor.outputPorts),
        uiMetadata: UIMetadata(
          position: position,
          lastModified: lastModified,
          color: color,
        ),
      );
    }

    return FalconGraph(
      processors: processors,
      connections: connections,
    );
  }
}

class FalconGraphYamlParserException implements Exception {
  FalconGraphYamlParserException(this.message);
  final String message;

  @override
  String toString() => 'FalconGraphYamlParserException: $message';
}

OptionValue<dynamic> _optionFromScalar(
  OptionValue<dynamic> templateOption,
  dynamic value,
) {
  if (templateOption is IntOption) {
    return IntOption(
      value: value as int,
      displayName: templateOption.displayName,
    );
  }
  if (templateOption is DoubleOption) {
    return DoubleOption(
      value: value as double,
      displayName: templateOption.displayName,
    );
  }
  if (templateOption is BoolOption) {
    return BoolOption(
      value: value as bool,
      displayName: templateOption.displayName,
    );
  }
  if (templateOption is StringOption) {
    return StringOption(
      value: value as String,
      displayName: templateOption.displayName,
    );
  }
  if (templateOption is OneOfOption) {
    final v = value as String;
    if (!templateOption.allowed.contains(v)) {
      throw FalconGraphYamlParserException(
        'Value "$v" is not allowed for option "${templateOption.displayName}".',
      );
    }
    return OneOfOption(
      value: v,
      allowed: templateOption.allowed,
      displayName: templateOption.displayName,
    );
  }
  throw FalconGraphYamlParserException(
    'Unsupported option type for "${templateOption.displayName}".',
  );
}

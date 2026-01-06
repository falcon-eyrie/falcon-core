import 'package:falcon_gui/model/falcon_graph.dart';
import 'package:falcon_gui/model/processor_definitions.dart';
import 'package:falcon_gui/utils/regex.dart';
import 'package:flutter/material.dart';
import 'package:yaml/yaml.dart';

extension FalconGraphSerializerX on FalconGraph {
  String toYaml() {
    final buffer = StringBuffer()..writeln('graph:');

    if (processors.isNotEmpty) {
      buffer.writeln('  processors:');
      for (final processor in processors.values) {
        if (processor.isTemplate) continue;

        final ui = processor.uiMetadata;

        buffer
          ..writeln('    ${processor.id}:')
          ..writeln('      class: ${processor.className}');

        if (processor.options.isNotEmpty) {
          buffer.writeln('      options:');
          for (final entry in processor.options.entries) {
            buffer.writeln(
              '        ${entry.key}: ${_yamlScalar(entry.value.value)}',
            );
          }
        }

        buffer
          ..writeln('      ui:')
          ..writeln('        position:')
          ..writeln('          x: ${_yamlScalar(ui.position.dx.toInt())}')
          ..writeln('          y: ${_yamlScalar(ui.position.dy.toInt())}')
          ..writeln(
            '        lastModified: "${_yamlScalar(ui.lastModified.toUtc())}"',
          )
          ..writeln(
            '        isExpanded: ${_yamlScalar(ui.isExpanded)}',
          );

        if (ui.color != null) {
          buffer.writeln('        color: ${_yamlScalar(ui.color)}');
        }

        buffer.writeln();
      }
    }

    if (connections.isNotEmpty) {
      buffer.writeln('  connections:');
      for (final conn in connections) {
        buffer.writeln(
          '    - ${conn.outProcessor}.${conn.outPort} = '
          '${conn.inProcessor}.${conn.inPort}',
        );
      }
    }

    return buffer.toString().trimRight();
  }

  String _yamlScalar(Object? value) {
    if (value is String) return '"${value.replaceAll('"', r'\"')}"';
    if (value is num || value is bool) return value.toString();
    if (value == null) return 'null';
    if (value is DateTime) return value.toIso8601String();
    if (value is Color) {
      return '#${value.toARGB32().toRadixString(16).padLeft(8, '0')}';
    }
    return '"$value"';
  }

  static FalconGraph fromYaml(String yamlString) {
    if (yamlString.trim().isEmpty) {
      return FalconGraph(processors: {}, connections: []);
    }

    var doc = loadYaml(yamlString) as YamlMap;

    // Extract graph content if it's wrapped in 'graph:' key
    if (doc['graph'] != null) {
      doc = doc['graph'] as YamlMap;
    }

    final processors = <String, Processor>{};
    final connections = <Connection>[];

    // Get processors map - support both with and without "processors:" key
    final processorsMap = doc['processors'] as YamlMap? ?? doc;

    // First pass: parse all processors
    for (final entry in processorsMap.entries) {
      final key = entry.key as String;

      if (key == 'connections' || key == 'processors') continue;

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
        try {
          options[name] = _optionFromScalar(templateOption, optMap[name]);
        } catch (e) {
          throw FalconGraphYamlParserException(
            '"${optMap[name]}" is not a valid value for option "$name" for '
            'processor "$className".',
          );
        }
      }

      var position = Offset.zero;
      var lastModified = DateTime(1970);
      Color? color;
      var isExpanded = false;

      final uiMap = map['ui'] as YamlMap?;
      if (uiMap != null) {
        try {
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

          if (uiMap['isExpanded'] != null) {
            isExpanded = uiMap['isExpanded'] as bool;
          }
        } catch (_) {
          // no-op
        }
      }

      if (!processorIdRegex.hasMatch(key)) {
        throw FalconGraphYamlParserException(
          '$key is not a valid processor id. '
          'It must contain only letters (a–z, A–Z), digits (0-9) and '
          'underscores (_)',
        );
      }
      processors[key] = Processor(
        id: key,
        className: className,
        options: options,
        ports: List.of(templateProcessor.ports),
        uiMetadata: UIMetadata(
          position: position,
          lastModified: lastModified,
          color: color,
          isExpanded: isExpanded,
        ),
      );
    }

    // Second pass: parse and validate connections
    final connectionsEntry = doc['connections'];

    if (connectionsEntry != null) {
      if (connectionsEntry is YamlList) {
        // Handle list format: connections: [line1, line2, ...]
        for (final line in connectionsEntry) {
          _parseAndValidateConnection(line as String, processors, connections);
        }
      } else if (connectionsEntry is YamlMap) {
        // Handle map format where keys and values form the connection
        for (final connEntry in connectionsEntry.entries) {
          final inPart = (connEntry.key ?? '').toString().trim();
          final outPart = (connEntry.value ?? '').toString().trim();

          if (inPart.isNotEmpty && outPart.isNotEmpty) {
            final line = '$inPart = $outPart';
            _parseAndValidateConnection(line, processors, connections);
          }
        }
      } else if (connectionsEntry is String) {
        // Handle string that may contain multiple connections
        final lines = connectionsEntry
            .split(RegExp(r'(?<!=)\s+(?=\w+\.\w+\s*=)'))
            .where((line) => line.trim().isNotEmpty)
            .toList();

        for (final line in lines) {
          _parseAndValidateConnection(line, processors, connections);
        }
      }
    }

    return FalconGraph(processors: processors, connections: connections);
  }

  static void _parseAndValidateConnection(
    String line,
    Map<String, Processor> processors,
    List<Connection> connections,
  ) {
    final trimmedLine = line.trim();

    // Try to find the '=' separator
    if (!trimmedLine.contains('=')) {
      throw FalconGraphYamlParserException(
        'Invalid connection format: "$trimmedLine". Expected format: '
        '"processorId.portName = processorId.portName"',
      );
    }

    final parts = trimmedLine.split('=');
    if (parts.length != 2) {
      throw FalconGraphYamlParserException(
        'Invalid connection format: "$trimmedLine". Expected exactly one '
        '"=" separator.',
      );
    }

    final leftSide = parts[0].trim();
    final rightSide = parts[1].trim();

    final left = leftSide.split('.');
    final right = rightSide.split('.');

    if (left.length < 2) {
      throw FalconGraphYamlParserException(
        'Invalid input port format: "$leftSide". '
        'Expected "processorId.portName"',
      );
    }

    if (right.length < 2) {
      throw FalconGraphYamlParserException(
        'Invalid output port format: "$rightSide". Expected '
        '"processorId.portName"',
      );
    }

    final inProcessorId = left[0].trim();
    final inPortName = left.sublist(1).join('.');
    final outProcessorId = right[0].trim();
    final outPortName = right.sublist(1).join('.');

    // Validate processors exist
    final inProcessor = processors[inProcessorId];
    if (inProcessor == null) {
      throw FalconGraphYamlParserException(
        'Input processor "$inProcessorId" not found in '
        'connection "$trimmedLine".',
      );
    }

    final outProcessor = processors[outProcessorId];
    if (outProcessor == null) {
      throw FalconGraphYamlParserException(
        'Output processor "$outProcessorId" not found in '
        'connection "$trimmedLine".',
      );
    }

    // Validate ports exist
    final inPort = inProcessor.ports.firstWhere(
      (p) => p.name == inPortName,
      orElse: () => throw FalconGraphYamlParserException(
        'Input port "$inPortName" not found in processor "$inProcessorId". '
        'Available ports: ${inProcessor.ports.map((p) => p.name).join(", ")}',
      ),
    );

    final outPort = outProcessor.ports.firstWhere(
      (p) => p.name == outPortName,
      orElse: () => throw FalconGraphYamlParserException(
        'Output port "$outPortName" not found in processor '
        '"$outProcessorId". '
        'Available ports: ${outProcessor.ports.map((p) => p.name).join(", ")}',
      ),
    );

    // Validate port types - input must be input, output must be output
    if (!inPort.isIn) {
      throw FalconGraphYamlParserException(
        'Connection "$trimmedLine" is invalid: input port "$inPortName" must '
        'be an input port.',
      );
    }

    if (outPort.isIn) {
      throw FalconGraphYamlParserException(
        'Connection "$trimmedLine" is invalid: output port "$outPortName" '
        'must be an output port.',
      );
    }

    // Validate port type compatibility
    if (inPort.type != 'AnyType' &&
        outPort.type != 'AnyType' &&
        inPort.type != outPort.type) {
      throw FalconGraphYamlParserException(
        'Connection "$trimmedLine" is invalid: port types do not match '
        '(${inPort.type} != ${outPort.type}).',
      );
    }

    connections.add(
      Connection(
        inProcessor: inProcessorId,
        inPort: inPortName,
        outProcessor: outProcessorId,
        outPort: outPortName,
      ),
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
    if (!templateOption.allowed
        .map((allowed) => allowed.toLowerCase())
        .contains(v.toLowerCase())) {
      throw FalconGraphYamlParserException(
        'Value "$v" is not allowed for option "${templateOption.displayName}". '
        'Allowed values: ${templateOption.allowed.join(", ")}',
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

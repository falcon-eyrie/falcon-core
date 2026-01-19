import 'package:falcon_gui/model/falcon_graph.dart';
import 'package:falcon_gui/model/processor_templates.dart';
import 'package:falcon_gui/utils/regex.dart';
import 'package:falcon_gui/utils/yaml_scalar.dart';
import 'package:flutter/material.dart';
import 'package:yaml/yaml.dart';
import 'package:yaml_writer/yaml_writer.dart';

// TODO(ben): when loading from file, fill in the missing ui metadata
// which will be complex because processors needs to be positioned
// and aligned with non-overlapping positions.
extension FalconGraphSerializerX on FalconGraph {
  String toYaml({bool excludeUIMetadata = false}) {
    if (processors.isEmpty && connections.isEmpty) {
      return '';
    }

    final graph = <String, Object?>{};

    if (processors.isNotEmpty) {
      final processorsMap = <String, Object?>{};

      for (final processor in processors.values) {
        final processorMap = <String, Object?>{
          'class': processor.className,
        };

        if (processor.options.isNotEmpty) {
          processorMap['options'] = {
            for (final entry in processor.options.entries)
              entry.key: entry.value.value,
          };
        }

        processorsMap[processor.id] = processorMap;
      }

      if (processorsMap.isNotEmpty) {
        graph['processors'] = processorsMap;
      }
    }

    if (connections.isNotEmpty) {
      graph['connections'] = [
        for (final conn in connections)
          '''${conn.outProcessor}.${conn.outPort} = ${conn.inProcessor}.${conn.inPort}''',
      ];
    }

    final root = <String, Object?>{
      'graph': graph,
    };

    if (!excludeUIMetadata) {
      final uiMetadata = <String, Object?>{};

      for (final processor in processors.values) {
        final ui = processor.uiMetadata;

        final uiMap = <String, Object?>{
          'position': {
            'x': ui.position.dx.toInt(),
            'y': ui.position.dy.toInt(),
          },
          'lastModified': ui.lastModified.toUtc().toIso8601String(),
          'isExpanded': ui.isExpanded,
        };

        if (ui.color != null) {
          uiMap['color'] = ui.color;
        }

        uiMetadata[processor.id] = uiMap;
      }

      root['uiMetadata'] = uiMetadata;
    }

    final yamlWriter = YamlWriter();

    return yamlWriter.write(root);
  }

  static FalconGraph fromYaml(String yamlString) {
    if (yamlString.trim().isEmpty) {
      return FalconGraph(processors: const {}, connections: const []);
    }

    var doc = loadYaml(yamlString) as YamlMap;

    final uiMetadataMap = doc['uiMetadata'] as YamlMap?;

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

      final templateProcessor = processorTemplates.values.firstWhere(
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
          options[name] = optionFromScalar(templateOption, optMap[name]);
        } catch (e) {
          throw FalconGraphYamlParserException(
            '"${optMap[name]}" is not a valid value for option "$name" for '
            'processor "$className".',
          );
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
        uiMetadata: UIMetadata(),
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

    // Third pass: parse UI metadata if present
    if (uiMetadataMap != null) {
      for (final entry in uiMetadataMap.entries) {
        final processorId = entry.key as String;
        final uiMap = entry.value as YamlMap?;

        final processor = processors[processorId];
        if (processor == null) continue;

        var position = Offset.zero;
        var lastModified = DateTime(1970);
        Color? color;
        var isExpanded = false;
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

        processors[processor.id] = processor.copyWith(
          uiMetadata: UIMetadata(
            position: position,
            lastModified: lastModified,
            color: color,
            isExpanded: isExpanded,
          ),
        );
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

    final outProcessorId = left[0].trim();
    final outPortName = left.sublist(1).join('.');
    final inProcessorId = right[0].trim();
    final inPortName = right.sublist(1).join('.');

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

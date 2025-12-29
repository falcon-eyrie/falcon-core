import 'dart:ui';

import 'package:collection/collection.dart';

class FalconGraph {
  FalconGraph({
    required this.processors,
    required this.connections,
  });

  final Map<String, Processor> processors;
  final List<Connection> connections;

  bool validateConnections() {
    for (final connection in connections) {
      final from = processors[connection.fromProcessor]?.getOutputPort(
        connection.fromPort,
      );
      final to = processors[connection.toProcessor]?.getInputPort(
        connection.toPort,
      );

      if (from == null || to == null) return false;

      final isPortsCompatible =
          from.type == 'AnyType' ||
          to.type == 'AnyType' ||
          from.type == to.type;

      if (!isPortsCompatible) {
        return false;
      }
    }
    return true;
  }
}

class Processor {
  const Processor({
    required this.id,
    required this.className,
    required this.options,
    required this.inputPorts,
    required this.outputPorts,
    required this.uiMetadata,
    this.isTemplate = false,
  });

  final String id;
  final String className;
  final Options options;
  final List<Port> inputPorts;
  final List<Port> outputPorts;
  final UIMetadata uiMetadata;
  final bool isTemplate;

  Port? getInputPort(String name) =>
      inputPorts.firstWhereOrNull((p) => p.name == name);

  Port? getOutputPort(String name) =>
      outputPorts.firstWhereOrNull((p) => p.name == name);

  Processor copyWith({
    String? id,
    Options? options,
    List<Port>? inputPorts,
    List<Port>? outputPorts,
    UIMetadata? uiMetadata,
    bool? isTemplate,
  }) {
    return Processor(
      id: id ?? this.id,
      className: className,
      options: options ?? this.options,
      inputPorts: inputPorts ?? this.inputPorts,
      outputPorts: outputPorts ?? this.outputPorts,
      uiMetadata: uiMetadata ?? this.uiMetadata,
    );
  }
}

typedef Options = Map<String, OptionValue<dynamic>>;

sealed class OptionValue<T> {
  OptionValue(this.value);
  T value;
}

final class IntOption extends OptionValue<int> {
  IntOption(super.value);
}

final class DoubleOption extends OptionValue<double> {
  DoubleOption(super.value);
}

final class StringOption extends OptionValue<String> {
  StringOption(super.value);
}

final class BoolOption extends OptionValue<bool> {
  // ignore: avoid_positional_boolean_parameters
  BoolOption(super.value);
}

final class OneOfOption extends OptionValue<String> {
  OneOfOption(super.value, this.allowed)
    : assert(
        allowed.contains(value),
        'Value $value is not in allowed options: $allowed',
      );
  final List<String> allowed;
}

class Port {
  Port({required this.name, required this.type});
  final String name;
  final String type; // e.g. "AnyType", "TimeSeriesType<double>", "int"
}

class UIMetadata {
  UIMetadata({
    required this.position,
    this.layoutSize = Size.zero,
    DateTime? lastModified,
  }) : lastModified = lastModified ?? DateTime(1970);

  final Offset position;
  final Size layoutSize;
  DateTime lastModified;

  UIMetadata copyWith({
    Offset? position,
    DateTime? lastModified,
    Size? layoutSize,
  }) {
    return UIMetadata(
      layoutSize: layoutSize ?? this.layoutSize,
      position: position ?? this.position,
      lastModified: lastModified ?? this.lastModified,
    );
  }
}

class Connection {
  Connection({
    required this.fromProcessor,
    required this.fromPort,
    required this.toProcessor,
    required this.toPort,
  });

  final String fromProcessor;
  final String fromPort;
  final String toProcessor;
  final String toPort;
}

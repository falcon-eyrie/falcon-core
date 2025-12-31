import 'dart:ui';

import 'package:collection/collection.dart';

class FalconGraph {
  FalconGraph({
    required Map<String, Processor> processors,
    required List<Connection> connections,
  }) : _processors = Map.of(processors),
       _connections = List.of(connections);

  final Map<String, Processor> _processors;
  final List<Connection> _connections;

  Map<String, Processor> get processors => Map.unmodifiable(_processors);
  List<Connection> get connections => List.unmodifiable(_connections);

  void setProcessor({required String id, required Processor newValue}) {
    _processors[id] = newValue;
  }

  FalconGraph copyWith({
    Map<String, Processor>? processors,
    List<Connection>? connections,
  }) {
    return FalconGraph(
      processors: processors ?? Map.of(_processors),
      connections: connections ?? List.of(_connections),
    );
  }
}

class Processor {
  Processor({
    required this.id,
    required this.className,
    required Map<String, OptionValue<dynamic>> options,
    required List<Port> inputPorts,
    required List<Port> outputPorts,
    required this.uiMetadata,
    this.isTemplate = false,
  }) : _inputPorts = List.of(inputPorts),
       _outputPorts = List.of(outputPorts),
       _options = Map.of(options);

  final String id;
  final String className;
  final Map<String, OptionValue<dynamic>> _options;
  final List<Port> _inputPorts;
  final List<Port> _outputPorts;
  final UIMetadata uiMetadata;
  final bool isTemplate;

  List<Port> get inputPorts => List.unmodifiable(_inputPorts);
  List<Port> get outputPorts => List.unmodifiable(_outputPorts);
  Map<String, OptionValue<dynamic>> get options => Map.unmodifiable(_options);

  Port? getInputPort(String name) =>
      inputPorts.firstWhereOrNull((p) => p.name == name);

  Port? getOutputPort(String name) =>
      outputPorts.firstWhereOrNull((p) => p.name == name);

  void updateOption({
    required String name,
    required OptionValue<dynamic> value,
  }) {
    _options[name] = value;
  }

  Processor copyWith({
    String? id,
    Map<String, OptionValue<dynamic>>? options,
    List<Port>? inputPorts,
    List<Port>? outputPorts,
    UIMetadata? uiMetadata,
    bool? isTemplate,
  }) {
    return Processor(
      id: id ?? this.id,
      className: className,
      isTemplate: isTemplate ?? this.isTemplate,
      options: options ?? Map.of(_options),
      inputPorts: inputPorts ?? List.of(_inputPorts),
      outputPorts: outputPorts ?? List.of(_outputPorts),
      uiMetadata: uiMetadata ?? this.uiMetadata,
    );
  }
}

sealed class OptionValue<T> {
  OptionValue(this.value);
  final T value;
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
  OneOfOption(super.value, List<String> allowed)
    : _allowed = allowed,
      assert(
        allowed.contains(value),
        'Value $value is not in allowed options: $allowed',
      );
  final List<String> _allowed;
  List<String> get allowed => List.unmodifiable(_allowed);
}

class Port {
  Port({required this.name, required this.type});
  final String name;
  final String type; // e.g. "AnyType", "TimeSeriesType<double>", "int"
}

class UIMetadata {
  UIMetadata({
    Offset position = Offset.zero,
    Size layoutSize = Size.zero,
    DateTime? lastModified,
    Color? color,
  }) : _position = position,
       _layoutSize = layoutSize,
       _lastModified = lastModified ?? DateTime(1970),
       _color = color;

  Offset _position;
  Size _layoutSize;
  DateTime _lastModified;
  Color? _color;

  Offset get position => _position;
  Size get layoutSize => _layoutSize;
  DateTime get lastModified => _lastModified;
  Color? get color => _color;

  // ignore: use_setters_to_change_properties
  void setPosition(Offset newPosition) {
    _position = newPosition;
  }

  // ignore: use_setters_to_change_properties
  void setLayoutSize(Size newSize) {
    _layoutSize = newSize;
  }

  // ignore: use_setters_to_change_properties
  void setColor(Color newColor) {
    _color = newColor;
  }

  void updateLastModified() {
    _lastModified = DateTime.now();
  }

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

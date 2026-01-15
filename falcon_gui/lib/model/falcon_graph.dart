import 'dart:async';
import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:falcon_gui/state/falcon_manager.dart';
import 'package:falcon_gui/utils/regex.dart';
import 'package:yaml/yaml.dart' as yaml;

class FalconGraph extends Equatable {
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
    unawaited(falconManager.onGraphChanged(this));
  }

  void removeProcessor({required String id}) {
    _connections.removeWhere(
      (conn) => conn.inProcessor == id || conn.outProcessor == id,
    );
    _processors.remove(id);
    unawaited(falconManager.onGraphChanged(this));
  }

  void updateOption({
    required String processorId,
    required String optionName,
    required OptionValue<dynamic> newValue,
  }) {
    final processor = _processors[processorId];
    if (processor == null) return;

    final newOptions = Map<String, OptionValue<dynamic>>.from(
      processor.options,
    );
    newOptions[optionName] = newValue;
    _processors[processorId] = processor.copyWith(options: newOptions);

    unawaited(falconManager.onGraphChanged(this));
  }

  void addConnection({required Connection newConnection}) {
    final isNotDuplicate = !connectionExists(connection: newConnection);
    if (isNotDuplicate) {
      _connections.add(newConnection);
    }
    unawaited(falconManager.onGraphChanged(this));
  }

  void removeConnection({required Connection connectionToRemove}) {
    _connections.removeWhere(
      (connection) =>
          connection.inProcessor == connectionToRemove.inProcessor &&
          connection.inPort == connectionToRemove.inPort &&
          connection.outProcessor == connectionToRemove.outProcessor &&
          connection.outPort == connectionToRemove.outPort,
    );
    unawaited(falconManager.onGraphChanged(this));
  }

  void renameConnections({
    required String oldProcessorId,
    required String newProcessorId,
  }) {
    for (var i = 0; i < _connections.length; i++) {
      final c = _connections[i];
      _connections[i] = Connection(
        inProcessor: c.inProcessor == oldProcessorId
            ? newProcessorId
            : c.inProcessor,
        inPort: c.inPort,
        outProcessor: c.outProcessor == oldProcessorId
            ? newProcessorId
            : c.outProcessor,
        outPort: c.outPort,
      );
    }
    unawaited(falconManager.onGraphChanged(this));
  }

  bool connectionExists({required Connection connection}) {
    return _connections.any(
      (conn) =>
          conn.inProcessor == connection.inProcessor &&
          conn.inPort == connection.inPort &&
          conn.outProcessor == connection.outProcessor &&
          conn.outPort == connection.outPort,
    );
  }

  bool isPortInAConnection({
    required String processorId,
    required String portName,
  }) {
    return _connections.any(
      (conn) =>
          (conn.inProcessor == processorId && conn.inPort == portName) ||
          (conn.outProcessor == processorId && conn.outPort == portName),
    );
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

  @override
  List<Object?> get props => [_processors, _connections];
}

class Processor extends Equatable {
  Processor({
    required this.id,
    required this.className,
    required Map<String, OptionValue<dynamic>> options,
    required List<Port> ports,
    required this.uiMetadata,
    this.isTemplate = false,
  }) : _ports = List.of(ports),
       _options = Map.of(options),
       assert(
         processorIdRegex.hasMatch(id),
         '$id is not a valid processor id. '
         'It must contain only letters (a–z, A–Z), digits (0-9) and '
         'underscores (_)',
       );

  final String id;
  final String className;
  final Map<String, OptionValue<dynamic>> _options;
  final List<Port> _ports;
  final UIMetadata uiMetadata;
  final bool isTemplate;

  List<Port> get ports => List.unmodifiable(_ports);
  Map<String, OptionValue<dynamic>> get options => Map.unmodifiable(_options);

  Port? getPort(String name) => ports.firstWhereOrNull((p) => p.name == name);

  bool get isSource => _ports.every((port) => port.isOut);

  bool get isSink => _ports.every((port) => port.isIn);

  bool get isIntermediate => !isSource && !isSink;

  Processor copyWith({
    String? id,
    Map<String, OptionValue<dynamic>>? options,
    List<Port>? ports,
    UIMetadata? uiMetadata,
    bool? isTemplate,
  }) {
    return Processor(
      id: id ?? this.id,
      className: className,
      isTemplate: isTemplate ?? this.isTemplate,
      options:
          options ??
          Map.of(
            _options.map((key, value) {
              return MapEntry(key, value);
            }),
          ),
      ports: ports ?? List.of(_ports),
      uiMetadata: uiMetadata ?? this.uiMetadata,
    );
  }

  @override
  List<Object?> get props => [
    id,
    className,
    _options,
    _ports,
    uiMetadata,
    isTemplate,
  ];
}

sealed class OptionValue<T> extends Equatable {
  const OptionValue({required this.value, required this.displayName});
  final T value;
  final String displayName;

  @override
  List<Object?> get props => [value, displayName];
}

final class IntOption extends OptionValue<int> {
  const IntOption({required super.value, required super.displayName});

  IntOption copyWith({required int newValue}) {
    return IntOption(value: newValue, displayName: displayName);
  }
}

final class DoubleOption extends OptionValue<double> {
  const DoubleOption({required super.value, required super.displayName});

  DoubleOption copyWith({required double newValue}) {
    return DoubleOption(value: newValue, displayName: displayName);
  }
}

final class StringOption extends OptionValue<String> {
  const StringOption({required super.value, required super.displayName});

  StringOption copyWith({required String newValue}) {
    return StringOption(value: newValue, displayName: displayName);
  }
}

final class BoolOption extends OptionValue<bool> {
  const BoolOption({required super.value, required super.displayName});

  BoolOption copyWith({required bool newValue}) {
    return BoolOption(value: newValue, displayName: displayName);
  }
}

final class YamlMapOption extends OptionValue<yaml.YamlMap> {
  const YamlMapOption({required super.value, required super.displayName});

  YamlMapOption copyWith({required yaml.YamlMap newValue}) {
    return YamlMapOption(value: newValue, displayName: displayName);
  }
}

final class OneOfOption extends OptionValue<String> {
  OneOfOption({
    required super.value,
    required List<String> allowed,
    required super.displayName,
  }) : _allowed = allowed.map((e) => e.toLowerCase()).toList(),
       assert(
         allowed.map((e) => e.toLowerCase()).contains(value.toLowerCase()),
         'Value $value is not in allowed options: $allowed',
       );
  final List<String> _allowed;
  List<String> get allowed => List.unmodifiable(_allowed);

  OneOfOption copyWith({required String newValue}) {
    return OneOfOption(
      value: newValue,
      allowed: List.of(_allowed),
      displayName: displayName,
    );
  }
}

class Port extends Equatable {
  const Port({required this.isIn, required this.name, required this.type});
  final String name;
  final String type; // e.g. "AnyType", "TimeSeriesType<double>", "int"
  final bool isIn;
  bool get isOut => !isIn;

  @override
  List<Object?> get props => [name, type, isIn];
}

class UIMetadata {
  UIMetadata({
    Offset position = Offset.zero,
    DateTime? lastModified,
    Color? color,
    bool isExpanded = false,
  }) : _position = position,
       _lastModified = lastModified ?? DateTime(1970),
       _color = color,
       _isExpanded = isExpanded;

  Offset _position;
  DateTime _lastModified;
  Color? _color;
  bool _isExpanded;

  Offset get position => _position;
  DateTime get lastModified => _lastModified;
  Color? get color => _color;
  bool get isExpanded => _isExpanded;

  // ignore: use_setters_to_change_properties
  void setPosition(Offset newPosition) {
    _position = newPosition;
  }

  // ignore: use_setters_to_change_properties
  void setColor(Color newColor) {
    _color = newColor;
  }

  void updateLastModified() {
    _lastModified = DateTime.now();
  }

  void toggleExpanded() {
    _isExpanded = !_isExpanded;
  }

  UIMetadata copyWith({
    Offset? position,
    DateTime? lastModified,
    bool? isExpanded,
  }) {
    return UIMetadata(
      position: position ?? this.position,
      lastModified: lastModified ?? this.lastModified,
      isExpanded: isExpanded ?? this.isExpanded,
    );
  }
}

class Connection extends Equatable {
  const Connection({
    required this.inProcessor,
    required this.inPort,
    required this.outProcessor,
    required this.outPort,
  });

  final String inProcessor;
  final String inPort;
  final String outProcessor;
  final String outPort;

  @override
  String toString() =>
      'Connection($inProcessor:$inPort -> $outProcessor:$outPort)';

  @override
  List<Object?> get props => [
    inProcessor,
    inPort,
    outProcessor,
    outPort,
  ];
}

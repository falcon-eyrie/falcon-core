import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:falcon_gui/utils/regex.dart';

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

  void removeProcessor({required String id}) {
    _connections.removeWhere(
      (conn) => conn.srcProcessor == id || conn.dstProcessor == id,
    );
    _processors.remove(id);
  }

  void addConnection({required Connection newConnection}) {
    final isNotDuplicate = _connections.none(
      (connection) =>
          connection.srcProcessor == newConnection.srcProcessor &&
          connection.srcPort == newConnection.srcPort &&
          connection.dstProcessor == newConnection.dstProcessor &&
          connection.dstPort == newConnection.dstPort,
    );
    if (isNotDuplicate) {
      _connections.add(newConnection);
    }
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

  void updateOption({
    required String name,
    required OptionValue<dynamic> value,
  }) {
    _options[name] = value;
  }

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
      options: options ?? Map.of(_options),
      ports: ports ?? List.of(_ports),
      uiMetadata: uiMetadata ?? this.uiMetadata,
    );
  }
}

sealed class OptionValue<T> {
  OptionValue({required this.value, required this.displayName});
  final T value;
  final String displayName;
}

final class IntOption extends OptionValue<int> {
  IntOption({required super.value, required super.displayName});

  IntOption copyWith({required int newValue}) {
    return IntOption(value: newValue, displayName: displayName);
  }
}

final class DoubleOption extends OptionValue<double> {
  DoubleOption({required super.value, required super.displayName});

  DoubleOption copyWith({required double newValue}) {
    return DoubleOption(value: newValue, displayName: displayName);
  }
}

final class StringOption extends OptionValue<String> {
  StringOption({required super.value, required super.displayName});

  StringOption copyWith({required String newValue}) {
    return StringOption(value: newValue, displayName: displayName);
  }
}

final class BoolOption extends OptionValue<bool> {
  BoolOption({required super.value, required super.displayName});

  BoolOption copyWith({required bool newValue}) {
    return BoolOption(value: newValue, displayName: displayName);
  }
}

final class OneOfOption extends OptionValue<String> {
  OneOfOption({
    required super.value,
    required List<String> allowed,
    required super.displayName,
  }) : _allowed = allowed,
       assert(
         allowed.contains(value),
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

class Port {
  Port({required this.isSrc, required this.name, required this.type});
  final String name;
  final String type; // e.g. "AnyType", "TimeSeriesType<double>", "int"
  final bool isSrc;
  bool get isDst => !isSrc;
}

class UIMetadata {
  UIMetadata({
    Offset position = Offset.zero,
    DateTime? lastModified,
    Color? color,
  }) : _position = position,
       _lastModified = lastModified ?? DateTime(1970),
       _color = color;

  Offset _position;
  DateTime _lastModified;
  Color? _color;

  Offset get position => _position;
  DateTime get lastModified => _lastModified;
  Color? get color => _color;

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

  UIMetadata copyWith({
    Offset? position,
    DateTime? lastModified,
  }) {
    return UIMetadata(
      position: position ?? this.position,
      lastModified: lastModified ?? this.lastModified,
    );
  }
}

class Connection {
  Connection({
    required this.srcProcessor,
    required this.srcPort,
    required this.dstProcessor,
    required this.dstPort,
  });

  final String srcProcessor;
  final String srcPort;
  final String dstProcessor;
  final String dstPort;

  @override
  String toString() =>
      'Connection($srcProcessor:$srcPort -> $dstProcessor:$dstPort)';
}

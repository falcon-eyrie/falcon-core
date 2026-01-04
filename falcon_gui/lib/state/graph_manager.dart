import 'dart:math' as math;

import 'package:falcon_gui/model/falcon_graph.dart';
import 'package:falcon_gui/model/graph_serializer.dart';
import 'package:falcon_gui/utils/regex.dart';
import 'package:flutter/material.dart';

// td: when loading from file, fill in the missing ui metadata, which will be
// complex because processors needs to be positioned and aligned

final GraphManager graphManager = GraphManager.instance;

class GraphManager extends ChangeNotifier {
  GraphManager._internal();

  static final GraphManager instance = GraphManager._internal();

  FalconGraph _graph = FalconGraph(
    processors: {},
    connections: [],
  );

  double _minX = 0;
  double _minY = 0;

  Offset? _grabOffset;

  final TransformationController transformationController =
      TransformationController();

  List<Processor> get processors => _graph.processors.values.toList()
    ..sort(
      (a, b) => a.uiMetadata.lastModified.compareTo(b.uiMetadata.lastModified),
    );

  List<Connection> get connections => _graph.connections;

  String get graphAsYaml => _graph.toYaml();

  void loadGraph(FalconGraph graph) {
    _graph = graph;

    notifyListeners();
  }

  void removeProcessor({required String id}) {
    _graph.removeProcessor(id: id);

    notifyListeners();
  }

  /// Duplicates a processor, returning the new processor's ID
  /// The new processor is offset by (20,20) from the original.
  /// If the original processor ID ends with '_number', the number is
  /// incremented to create a unique ID for the new processor. If not,
  /// '_1' is appended to the original ID. If the new ID already exists,
  /// the number is incremented until a unique ID is found.
  ///
  /// The original processor can already be in the canvas or a template from
  /// the panel. In either case, the new processor will be a real processor in
  /// the canvas. The new processor will have `isTemplate` set to false.
  String duplicateProcessor({
    required Processor processor,
  }) {
    var newId = processor.id;
    while (_graph.processors.containsKey(newId)) {
      // parse the last _* segment, increment id
      final match = processorIdSuffixRegex.firstMatch(newId);
      if (match != null) {
        final number = int.parse(match.group(1)!);
        newId = newId.replaceFirst(processorIdSuffixRegex, '_${number + 1}');
      } else {
        newId = '${newId}_1';
      }
    }

    final Offset newPosition;
    if (processor.isTemplate) {
      newPosition = _findNonOverlappingPosition();
    } else {
      newPosition = processor.uiMetadata.position + const Offset(20, 20);
    }

    _graph.setProcessor(
      id: newId,
      newValue: processor.copyWith(
        id: newId,
        isTemplate: false,
        uiMetadata: processor.uiMetadata.copyWith(
          position: newPosition,
          lastModified: DateTime.now(),
        ),
      ),
    );

    notifyListeners();
    return newId;
  }

  Offset _findNonOverlappingPosition() {
    const nodeSize = Size(300, 500);
    const padding = 20;
    final existingPositions = _graph.processors.values
        .map((p) => p.uiMetadata.position & nodeSize)
        .toList();

    var position = Offset.zero;

    bool overlaps(Offset pos) {
      final rect = pos & nodeSize;
      return existingPositions.any((r) => r.overlaps(rect));
    }

    while (overlaps(position)) {
      position += Offset(nodeSize.width + padding, 0);
      // move to next row if exceeding some arbitrary canvas width
      if (position.dx > 2000) {
        position = Offset(0, position.dy + nodeSize.height + padding);
      }
    }

    return position;
  }

  void onOnProcessorDragStart({
    required String id,
    required Offset scenePosition,
  }) {
    final processor = _graph.processors[id];
    if (processor == null) return;

    final scenePositionTransformed = MatrixUtils.transformPoint(
      transformationController.value.clone()..invert(),
      scenePosition,
    );
    _grabOffset = scenePositionTransformed - processor.uiMetadata.position;
  }

  void onProcessorDragUpdate({required String id, required Offset newPos}) {
    final processor = _graph.processors[id];
    if (processor == null) return;

    final newPosTransformed = MatrixUtils.transformPoint(
      transformationController.value.clone()..invert(),
      newPos,
    );

    var updatedPosition = newPosTransformed - (_grabOffset ?? Offset.zero);

    // Shift all processors if dragged into negative coordinates
    double shiftX = 0;
    double shiftY = 0;
    if (updatedPosition.dx < 0) shiftX = -updatedPosition.dx;
    if (updatedPosition.dy < 0) shiftY = -updatedPosition.dy;

    if (shiftX != 0 || shiftY != 0) {
      for (final processor in _graph.processors.values) {
        processor.uiMetadata.setPosition(
          processor.uiMetadata.position + Offset(shiftX, shiftY),
        );
      }
      // Move canvas so that negative space is removed
      transformationController.value = transformationController.value.clone()
        ..translateByDouble(-shiftX, -shiftY, 0, 1);

      updatedPosition += Offset(shiftX, shiftY);
    }

    _graph.processors[id]?.uiMetadata.setPosition(updatedPosition);
    _graph.processors[id]?.uiMetadata.updateLastModified();

    notifyListeners();
  }

  void onProcessorDragEnd({required String id}) {
    _grabOffset = null;
  }

  void onProcessorClicked({required String id}) {
    final processor = _graph.processors[id];
    if (processor == null) return;
    _graph.processors[id]?.uiMetadata.updateLastModified();
    notifyListeners();
  }

  void _adjustCanvas() {
    if (_graph.processors.isEmpty) return;

    final minX = _graph.processors.values
        .map((n) => n.uiMetadata.position.dx)
        .reduce(math.min);
    final minY = _graph.processors.values
        .map((n) => n.uiMetadata.position.dy)
        .reduce(math.min);

    if (minX > 0 || minY > 0) {
      // Shift all processors up-left
      for (final processor in _graph.processors.values) {
        processor.uiMetadata.setPosition(
          processor.uiMetadata.position - Offset(minX, minY),
        );
      }

      // Move canvas down-right to make it seamless
      transformationController.value = transformationController.value.clone()
        ..translateByDouble(minX, minY, 0, 1);
    }
  }

  Size get canvasSize {
    if (_graph.processors.isEmpty) return Size.zero;
    _adjustCanvas();

    final maxX = _graph.processors.values.fold<double>(
      0,
      (prev, processor) => math.max(
        prev,
        processor.uiMetadata.position.dx + 1000,
      ),
    );

    final maxY = _graph.processors.values.fold<double>(
      0,
      (prev, processor) => math.max(
        prev,
        processor.uiMetadata.position.dy + 1000,
      ),
    );

    _minX = _graph.processors.values.fold<double>(
      double.infinity,
      (prev, processor) => math.min(prev, processor.uiMetadata.position.dx),
    );
    _minY = _graph.processors.values.fold<double>(
      double.infinity,
      (prev, processor) => math.min(prev, processor.uiMetadata.position.dy),
    );

    return Size(maxX - _minX, maxY - _minY);
  }

  void updateOptionValue({
    required String processorId,
    required String optionName,
    required OptionValue<dynamic> newValue,
  }) {
    final processor = _graph.processors[processorId];
    if (processor == null) return;

    processor.updateOption(name: optionName, value: newValue);

    notifyListeners();
  }

  void zoomIn() =>
      transformationController.value = transformationController.value.clone()
        ..scaleByDouble(1.2, 1.2, 1.2, 1);

  void zoomOut() =>
      transformationController.value = transformationController.value.clone()
        ..scaleByDouble(1 / 1.2, 1 / 1.2, 1 / 1.2, 1);

  void resetZoom() {
    transformationController.value = Matrix4.identity()
      ..translateByDouble(40, 40, 0, 1);
  }

  // Offset of each port's center position relative to the processor item
  // widget that contains it.
  final _portPositions = <String, Offset>{};

  // Currently selected port unique ID (processorId-portName) for connection
  // creation.
  String? _selectedPortUniqueId;

  // Cursor position for drawing temporary connection line
  Offset? _cursorPosition;

  String? get selectedPortUniqueId => _selectedPortUniqueId;

  Offset? get cursorPosition => _cursorPosition;

  // Set of enabled port unique IDs (processorId-portName) for connection
  // creation. In other words, user will see these ports highlighted as
  // connectable to the currently selected port.
  final _enabledPortIds = <String>{};

  Offset getPortPosition({
    required String processorId,
    required String portName,
  }) {
    final uniquePortId = '$processorId-$portName';
    return _portPositions[uniquePortId] ?? Offset.zero;
  }

  void onPortClicked({required String processorId, required Port port}) {
    final uniquePortId = '$processorId-${port.name}';

    if (_selectedPortUniqueId == null) {
      _selectedPortUniqueId = uniquePortId;

      // Determine enabled ports
      _enabledPortIds.clear();
      for (final otherProcessor in _graph.processors.values) {
        for (final otherPort in [...otherProcessor.ports]) {
          final otherUniqueId = '${otherProcessor.id}-${otherPort.name}';
          if (otherUniqueId == uniquePortId) continue;

          final isDataTypeCompatible =
              port.type == 'AnyType' ||
              otherPort.type == 'AnyType' ||
              port.type == otherPort.type;
          final isSameProcessor = otherProcessor.id == processorId;
          final isSrcDstPair = port.isSrc != otherPort.isSrc;
          final isCompatible =
              isSrcDstPair && !isSameProcessor && isDataTypeCompatible;
          if (isCompatible) {
            _enabledPortIds.add(otherUniqueId);
          }
        }
      }
    } else {
      if (_selectedPortUniqueId != uniquePortId) {
        final selectedPortParts = _selectedPortUniqueId!.split('-');
        final sourceProcessorId = selectedPortParts[0];
        final sourcePortName = selectedPortParts[1];
        final destinationProcessorId = processorId;
        final destinationPortName = port.name;

        if (port.isSrc) {
          _graph.addConnection(
            newConnection: Connection(
              srcProcessor: destinationProcessorId,
              srcPort: destinationPortName,
              dstProcessor: sourceProcessorId,
              dstPort: sourcePortName,
            ),
          );
        } else {
          _graph.addConnection(
            newConnection: Connection(
              srcProcessor: sourceProcessorId,
              srcPort: sourcePortName,
              dstProcessor: destinationProcessorId,
              dstPort: destinationPortName,
            ),
          );
        }
      }

      _selectedPortUniqueId = null;
      _cursorPosition = null;
    }

    notifyListeners();
  }

  void updateCursorPosition(Offset position) {
    if (_selectedPortUniqueId != null) {
      // Apply same transformation as processor drag to get canvas coordinates
      final canvasPosition = MatrixUtils.transformPoint(
        graphManager.transformationController.value.clone()..invert(),
        position,
      );
      _cursorPosition = canvasPosition;
      notifyListeners();
    }
  }

  void onPortPositionUpdated({
    required String processorId,
    required String portName,
    required Offset newPosition,
  }) {
    final uniquePortId = '$processorId-$portName';
    _portPositions[uniquePortId] = newPosition;
  }

  /// Whether or not the specified port is compatible to connect to the
  /// currently selected port. This will be used to highlight compatible ports
  /// and grey out incompatible ones.
  ///
  /// This does not mean the port is enabled or not, just that it can be
  /// connected to the selected port.
  bool isPortEnabled({required String processorId, required String portName}) {
    final uniquePortId = '$processorId-$portName';

    // If we are not in the create connection mode, all ports are enabled
    if (_selectedPortUniqueId == null) return true;

    // The selected port itself is always enabled
    if (_selectedPortUniqueId == uniquePortId) return true;

    return _enabledPortIds.contains(uniquePortId);
  }

  void cancelPortSelection() {
    _selectedPortUniqueId = null;
    _cursorPosition = null;
    _enabledPortIds.clear();
    notifyListeners();
  }

  ({Offset startPos, Offset endPos})? get tempConnectionLinePosition {
    if (_selectedPortUniqueId == null || _cursorPosition == null) {
      return null;
    }

    final parts = _selectedPortUniqueId!.split('-');
    final processorId = parts[0];
    final portName = parts.sublist(1).join('-');

    final processor = _graph.processors[processorId];
    if (processor == null) return null;

    final portPos = getPortPosition(
      processorId: processorId,
      portName: portName,
    );
    final startPos = processor.uiMetadata.position + portPos;

    return (startPos: startPos, endPos: _cursorPosition!);
  }

  List<({Offset startPos, Offset endPos, Connection connection})>
  get connectionPositions {
    return connections.map((connection) {
      final srcProcessor = _graph.processors[connection.srcProcessor];
      final dstProcessor = _graph.processors[connection.dstProcessor];

      if (srcProcessor == null || dstProcessor == null) {
        return (
          startPos: Offset.zero,
          endPos: Offset.zero,
          connection: connection,
        );
      }

      final fromPortOffset = getPortPosition(
        processorId: connection.srcProcessor,
        portName: connection.srcPort,
      );
      final toPortOffset = getPortPosition(
        processorId: connection.dstProcessor,
        portName: connection.dstPort,
      );

      final fromPos = srcProcessor.uiMetadata.position + fromPortOffset;
      final toPos = dstProcessor.uiMetadata.position + toPortOffset;

      return (startPos: fromPos, endPos: toPos, connection: connection);
    }).toList();
  }

  void removeConnectionAtPosition(Offset position) {
    const threshold = 5.0; // Distance threshold in pixels

    // Transform position to canvas coordinates
    final canvasPosition = MatrixUtils.transformPoint(
      transformationController.value.clone()..invert(),
      position,
    );

    for (final connPos in connectionPositions) {
      // Check if position is near the connection curve
      if (_isPointNearCubicBezier(
        canvasPosition,
        connPos.startPos,
        connPos.endPos,
        threshold,
      )) {
        // Find and remove the corresponding connection
        _graph.removeConnection(connectionToRemove: connPos.connection);
        notifyListeners();
        return;
      }
    }
  }

  bool _isPointNearCubicBezier(
    Offset point,
    Offset start,
    Offset end,
    double threshold,
  ) {
    // Sample points along the cubic bezier curve
    // Use more samples for better accuracy
    final curveLength = (end - start).distance;
    final samples = (curveLength / 10).ceil().clamp(20, 100);

    final ctrl1 = Offset(start.dx + 100, start.dy);
    final ctrl2 = Offset(end.dx - 100, end.dy);

    for (var i = 0; i <= samples; i++) {
      final t = i / samples;
      final curvePoint = _cubicBezierPoint(t, start, ctrl1, ctrl2, end);

      if ((curvePoint - point).distance < threshold) {
        return true;
      }
    }
    return false;
  }

  Offset _cubicBezierPoint(
    double t,
    Offset p0,
    Offset p1,
    Offset p2,
    Offset p3,
  ) {
    final u = 1 - t;
    final tt = t * t;
    final uu = u * u;
    final uuu = uu * u;
    final ttt = tt * t;

    return Offset(
      uuu * p0.dx + 3 * uu * t * p1.dx + 3 * u * tt * p2.dx + ttt * p3.dx,
      uuu * p0.dy + 3 * uu * t * p1.dy + 3 * u * tt * p2.dy + ttt * p3.dy,
    );
  }
}

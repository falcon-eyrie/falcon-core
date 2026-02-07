import 'dart:async';
import 'dart:math' as math;

import 'package:collection/collection.dart';
import 'package:falcon_gui/model/falcon_graph.dart';
import 'package:falcon_gui/model/graph_serializer.dart';
import 'package:falcon_gui/state/falcon_manager.dart';
import 'package:falcon_gui/utils/debounce.dart';
import 'package:falcon_gui/utils/geometry_algorithms.dart';
import 'package:falcon_gui/utils/misc.dart';
import 'package:flutter/material.dart';

final GraphManager graphManager = GraphManager.instance;

class GraphManager extends ChangeNotifier {
  GraphManager._internal();

  static final GraphManager instance = GraphManager._internal();

  FalconGraph _graph = FalconGraph(processors: const {}, connections: const []);

  double _minX = 0;
  double _minY = 0;

  Size _viewportSize = Size.zero;
  Offset? _grabOffset;

  // Whether to wait for port positions to be reported from the UI
  // before rendering connections. Port positions are needed for
  // start and end points of connections.
  bool _shouldWaitForPortPositions = true;

  bool get shouldRenderConnections =>
      _graph.processors.isNotEmpty && !_shouldWaitForPortPositions;

  final TransformationController transformationController =
      TransformationController(topLeftMatrix);

  final _hoverDebounce = Debounce(
    delay: const Duration(milliseconds: 1),
  );

  List<Processor> get processors => _graph.processors.values.toList()
    ..sort(
      (a, b) => a.uiMetadata.lastModified.compareTo(b.uiMetadata.lastModified),
    );

  List<Connection> get connections => _graph.connections;

  String get graphAsYaml => _graph.toYaml();
  String get graphAsYamlWithoutUI => _graph.toYaml(excludeUIMetadata: true);

  void loadGraph(FalconGraph graph) {
    _graph = graph;
    unawaited(falconManager.onGraphChanged(graph));
    notifyListeners();
  }

  void removeProcessor({required String id}) {
    _selectedPortUniqueId = null;
    _graph.removeProcessor(id: id);

    notifyListeners();
  }

  // ignore: avoid_setters_without_getters
  set viewportSize(Size newSize) {
    _viewportSize = newSize;
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
    _selectedPortUniqueId = null;
    var newId = processor.isTemplate ? '${processor.id}1' : processor.id;

    while (_graph.processors.containsKey(newId)) {
      // parse the last _* segment, increment id
      final match = processorIdSuffixRegex.firstMatch(newId);
      if (match != null) {
        final number = int.parse(match.group(1)!);
        newId = newId.replaceFirst(processorIdSuffixRegex, '${number + 1}');
      } else {
        newId = '${newId}1';
      }
    }

    final Offset newPosition;
    if (processor.isTemplate) {
      newPosition = findNonOverlappingPosition(
        processors: _graph.processors.values.toList(),
      );
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
          isExpanded: true,
        ),
      ),
    );

    focusOnProcessor(id: newId);

    notifyListeners();
    return newId;
  }

  void focusOnProcessor({required String id}) {
    final processor = _graph.processors[id];
    if (processor == null) return;

    final processorPos = processor.uiMetadata.position;

    // Calculate the target transformation to center it on the screen
    final targetX = -(processorPos.dx - _viewportSize.width / 2) - 600;
    final targetY = -(processorPos.dy - _viewportSize.height / 2) - 300;

    // Create new transformation matrix with translation to center the processor
    final targetMatrix = Matrix4.identity()
      ..translateByDouble(targetX, targetY, 0, 1);

    transformationController.value = targetMatrix;

    notifyListeners();
  }

  void onProcessorDragStart({
    required String id,
    required Offset scenePosition,
  }) {
    _selectedPortUniqueId = null;
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
    unawaited(falconManager.onUIMetadataChanged(_graph));
  }

  void onProcessorClicked({required String id}) {
    final processor = _graph.processors[id];
    if (processor == null) return;
    _graph.processors[id]?.uiMetadata.updateLastModified();
    unawaited(falconManager.onUIMetadataChanged(_graph));
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
    _selectedPortUniqueId = null;
    _graph.updateOption(
      processorId: processorId,
      optionName: optionName,
      newValue: newValue,
    );

    notifyListeners();
  }

  void zoomIn() =>
      transformationController.value = transformationController.value.clone()
        ..scaleByDouble(1.2, 1.2, 1.2, 1);

  void zoomOut() =>
      transformationController.value = transformationController.value.clone()
        ..scaleByDouble(1 / 1.2, 1 / 1.2, 1 / 1.2, 1);

  void resetZoom() {
    transformationController.value = topLeftMatrix;
  }

  // Offset of each port's center position relative to the processor item
  // widget that contains it.
  final _portPositions = <String, Offset>{};

  // Currently selected port unique ID (processorId-portDirectionalName) for
  // connection creation.
  String? _selectedPortUniqueId;

  // Cursor position for drawing temporary connection line
  Offset? _cursorPosition;

  String? get selectedPortUniqueId => _selectedPortUniqueId;

  // Port selectability status for the currently selected input port.
  final _validOutPortIds = <String>{};
  final _typeIncompatiblePortIds = <String>{};
  final _bothInPortIds = <String>{};
  final _bothOutPortIds = <String>{};
  final _alreadyConnectedPortIds = <String>{};
  final _sameProcessorPortIds = <String>{};

  PortSelectabilityStatus? getPortSelectabilityStatus({
    required String processorId,
    required Port port,
  }) {
    // If we are not in the create connection mode, all ports are idle
    if (_selectedPortUniqueId == null) {
      if (_graph.isPortInAConnection(
        processorId: processorId,
        port: port,
      )) {
        return PortSelectabilityStatus.connectedIdle;
      } else {
        return PortSelectabilityStatus.idle;
      }
    }

    final uniquePortId = '$processorId-${port.directionalName}';

    // The port itself is selected as input port
    if (_selectedPortUniqueId == uniquePortId) {
      return PortSelectabilityStatus.selectedAsInput;
    }

    final statusMap = {
      _validOutPortIds: PortSelectabilityStatus.compatible,
      _typeIncompatiblePortIds: PortSelectabilityStatus.typeIncompatible,
      _bothInPortIds: PortSelectabilityStatus.bothInput,
      _bothOutPortIds: PortSelectabilityStatus.bothOutput,
      _alreadyConnectedPortIds: PortSelectabilityStatus.alreadyConnected,
      _sameProcessorPortIds: PortSelectabilityStatus.sameProcessor,
    };

    for (final entry in statusMap.entries) {
      if (entry.key.contains(uniquePortId)) {
        return entry.value;
      }
    }

    // This should not happen, but return idle as fallback
    return PortSelectabilityStatus.idle;
  }

  Offset getPortPosition({
    required String processorId,
    required String portDirectionalName,
  }) {
    final uniquePortId = '$processorId-$portDirectionalName';
    return _portPositions[uniquePortId] ?? Offset.zero;
  }

  void onPortClicked({required String processorId, required Port port}) {
    final uniquePortId = '$processorId-${port.directionalName}';
    if (_selectedPortUniqueId == null) {
      _selectedPortUniqueId = uniquePortId;

      // Determine enabled ports
      _validOutPortIds.clear();
      _typeIncompatiblePortIds.clear();
      _bothInPortIds.clear();
      _bothOutPortIds.clear();
      _alreadyConnectedPortIds.clear();
      _sameProcessorPortIds.clear();

      for (final otherProcessor in [
        ..._graph.processors.values,
      ]) {
        for (final otherPort in otherProcessor.ports) {
          final otherUniqueId =
              '${otherProcessor.id}-${otherPort.directionalName}';

          // Skip self
          if (otherUniqueId == uniquePortId) continue;

          final isSameProcessor = otherProcessor.id == processorId;
          final isInOutPair = port.isIn != otherPort.isIn;
          final isBothIn = port.isIn && otherPort.isIn;
          final isBothOut = !port.isIn && !otherPort.isIn;

          final isDataTypeCompatible =
              port.type == 'AnyType' ||
              otherPort.type == 'AnyType' ||
              port.type == otherPort.type;

          final possibleConnection = port.isIn
              ? Connection(
                  inProcessor: processorId,
                  inPort: port.name,
                  outProcessor: otherProcessor.id,
                  outPort: otherPort.name,
                )
              : Connection(
                  inProcessor: otherProcessor.id,
                  inPort: otherPort.name,
                  outProcessor: processorId,
                  outPort: port.name,
                );

          final isAlreadyConnected = _graph.connectionExists(
            connection: possibleConnection,
          );

          if (isAlreadyConnected) {
            _alreadyConnectedPortIds.add(otherUniqueId);
            continue;
          }

          if (isSameProcessor) {
            _sameProcessorPortIds.add(otherUniqueId);
            continue;
          }

          if (isBothIn) {
            _bothInPortIds.add(otherUniqueId);
            continue;
          }

          if (isBothOut) {
            _bothOutPortIds.add(otherUniqueId);
            continue;
          }

          if (!isDataTypeCompatible) {
            _typeIncompatiblePortIds.add(otherUniqueId);
            continue;
          }

          if (isInOutPair) {
            _validOutPortIds.add(otherUniqueId);
          }
        }
      }
    } else if (_validOutPortIds.contains(uniquePortId)) {
      final selectedPortParts = _selectedPortUniqueId!.split('-');
      final inProcessorId = selectedPortParts[0];
      final inPortName = selectedPortParts[1].split(':')[1];
      final outProcessorId = processorId;
      final outPortName = port.name;

      if (port.isIn) {
        _graph.addConnection(
          newConnection: Connection(
            inProcessor: outProcessorId,
            inPort: outPortName,
            outProcessor: inProcessorId,
            outPort: inPortName,
          ),
        );
      } else {
        _graph.addConnection(
          newConnection: Connection(
            inProcessor: inProcessorId,
            inPort: inPortName,
            outProcessor: outProcessorId,
            outPort: outPortName,
          ),
        );
      }

      _selectedPortUniqueId = null;
      _cursorPosition = null;
    }

    notifyListeners();
  }

  void onPortPositionUpdated({
    required String processorId,
    required Port port,
    required Offset newPosition,
  }) {
    final uniquePortId = '$processorId-${port.directionalName}';
    _portPositions[uniquePortId] = newPosition;
  }

  void cancelPortSelection() {
    _selectedPortUniqueId = null;
    _cursorPosition = null;
    _validOutPortIds.clear();
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

    final port = processor?.ports.firstWhereOrNull(
      (p) => p.directionalName == portName,
    );
    if (processor == null || port == null) return null;

    final portPos = getPortPosition(
      processorId: processorId,
      portDirectionalName: port.directionalName,
    );
    final startPos = processor.uiMetadata.position + portPos;

    final connectionLine = port.isOut
        ? (startPos: startPos, endPos: _cursorPosition!)
        : (startPos: _cursorPosition!, endPos: startPos);

    return connectionLine;
  }

  List<({Offset startPos, Offset endPos, Connection connection})>
  get connectionPositions {
    return connections.map((connection) {
      final inProcessor = _graph.processors[connection.inProcessor];
      final outProcessor = _graph.processors[connection.outProcessor];

      if (inProcessor == null || outProcessor == null) {
        return (
          startPos: Offset.zero,
          endPos: Offset.zero,
          connection: connection,
        );
      }

      final fromPortOffset = getPortPosition(
        processorId: connection.inProcessor,
        portDirectionalName: 'in:${connection.inPort}',
      );
      final toPortOffset = getPortPosition(
        processorId: connection.outProcessor,
        portDirectionalName: 'out:${connection.outPort}',
      );

      final fromPos = outProcessor.uiMetadata.position + toPortOffset;
      final toPos = inProcessor.uiMetadata.position + fromPortOffset;

      return (startPos: fromPos, endPos: toPos, connection: connection);
    }).toList();
  }

  Connection? _hoveredConnection;
  Connection? get hoveredConnection => _hoveredConnection;

  void updateCursorPosition(Offset position) {
    if (_selectedPortUniqueId != null) {
      // Apply same transformation as processor drag to get canvas coordinates
      final canvasPosition = MatrixUtils.transformPoint(
        graphManager.transformationController.value.clone()..invert(),
        position,
      );
      _cursorPosition = canvasPosition;
      notifyListeners();
    } else {
      final newHoveredConnection = _getHoveredConnection(position);

      if (newHoveredConnection != null) {
        _hoveredConnection = newHoveredConnection;
        notifyListeners();
      } else {
        _hoverDebounce(() {
          _hoveredConnection = null;
          notifyListeners();
        });
      }
    }
  }

  void maybeRemoveConnectionAtPosition() {
    if (_hoveredConnection != null) {
      _graph.removeConnection(connectionToRemove: _hoveredConnection!);
      _hoveredConnection = null;
      notifyListeners();
    }
  }

  Connection? _getHoveredConnection(Offset position) {
    const threshold = 12.0; // Distance threshold in pixels

    // Transform position to canvas coordinates
    final canvasPosition = MatrixUtils.transformPoint(
      transformationController.value.clone()..invert(),
      position,
    );

    for (final connPos in connectionPositions) {
      // Check if position is near the connection curve
      if (isPointNearCubicBezier(
        canvasPosition,
        connPos.startPos,
        connPos.endPos,
        threshold,
      )) {
        return connPos.connection;
      }
    }

    return null;
  }

  String? newProcessorNameValidator(String? newId) {
    if (newId == null || newId.trim().isEmpty) {
      return 'Name cannot be empty';
    }
    if (!processorIdRegex.hasMatch(newId)) {
      return 'Invalid name format';
    }
    if (_graph.processors.values.where((p) => p.id == newId).isNotEmpty) {
      return 'Name already exists';
    }
    return null;
  }

  void renameProcessor({required String oldId, required String newId}) {
    if (oldId == newId) return;
    if (newProcessorNameValidator(newId) != null) return;

    final processor = _graph.processors[oldId];
    if (processor == null) return;
    _graph.renameProcessor(oldId: oldId, newId: newId);

    _shouldWaitForPortPositions = true;
    notifyListeners();
  }

  void toggleProcessorExpanded({required String id}) {
    final processor = _graph.processors[id];
    if (processor == null) return;

    processor.uiMetadata.toggleExpanded();
    unawaited(falconManager.onUIMetadataChanged(_graph));

    notifyListeners();
  }

  bool get isAllExpanded => _graph.processors.values.every(
    (processor) => processor.uiMetadata.isExpanded,
  );

  bool get isAllCollapsed => _graph.processors.values.every(
    (processor) => !processor.uiMetadata.isExpanded,
  );

  void toggleCollapseAll() {
    final isAllExpanded = this.isAllExpanded;
    final isAllCollapsed = this.isAllCollapsed;

    for (final processor in _graph.processors.values) {
      if (isAllExpanded || isAllCollapsed) {
        processor.uiMetadata.toggleExpanded();
      } else if (processor.uiMetadata.isExpanded) {
        processor.uiMetadata.toggleExpanded();
      }
    }
    unawaited(falconManager.onUIMetadataChanged(_graph));

    notifyListeners();
  }

  bool isProcessorCompatibleForSelectedPort(String processorId) {
    if (_selectedPortUniqueId == null) {
      return true;
    }

    if (_selectedPortUniqueId!.startsWith('$processorId-')) {
      return true;
    }

    for (final uniquePortId in _validOutPortIds) {
      if (uniquePortId.startsWith('$processorId-')) {
        return true;
      }
    }
    return false;
  }

  @override
  void dispose() {
    _hoverDebounce.dispose();
    super.dispose();
  }

  // Hook called when the editor view has been rendered.
  void onEditorViewRendered() {
    // If there are port positions and we were waiting for them,
    // we can now stop waiting and render connections using these port
    // positions.
    if (_shouldWaitForPortPositions) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(
          Future.microtask(() {
            if (_portPositions.isNotEmpty && _shouldWaitForPortPositions) {
              _shouldWaitForPortPositions = false;
              notifyListeners();
            }
          }),
        );
      });
    }
  }
}

enum PortSelectabilityStatus {
  selectedAsInput,
  typeIncompatible,
  bothInput,
  bothOutput,
  alreadyConnected,
  sameProcessor,
  compatible,
  idle,
  connectedIdle,
}

import 'dart:math' as math;

import 'package:falcon_gui/model/falcon_graph.dart';
import 'package:falcon_gui/utils/regex.dart';
import 'package:flutter/material.dart';

// td: when loading from file, fill in the missing ui metadata, which will be
// complex because nodes needs to be positioned and aligned

final GraphManager graphManager = GraphManager.instance;

class GraphManager extends ChangeNotifier {
  GraphManager._internal();

  static final GraphManager instance = GraphManager._internal();

  FalconGraph _graph = FalconGraph(processors: {}, connections: []);

  double _minX = 0;
  double _minY = 0;

  Offset? _grabOffset;

  final TransformationController transformationController =
      TransformationController();

  List<Processor> get processors => _graph.processors.values.toList()
    ..sort(
      (a, b) => a.uiMetadata.lastModified.compareTo(b.uiMetadata.lastModified),
    );

  void loadGraph(FalconGraph graph) {
    _graph = graph;

    _maybeShrinkCanvas();
    notifyListeners();
  }

  void removeNode({required String id}) {
    _graph.connections.removeWhere(
      (conn) => conn.fromProcessor == id || conn.toProcessor == id,
    );
    _graph.processors.removeWhere((key, _) => key == id);

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
  /// the panel. In either case, the new processor will be a real node in
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
      // TODO(ben): put the new node in the center of the viewport
      newPosition = Offset.zero;
    } else {
      newPosition = processor.uiMetadata.position + const Offset(20, 20);
    }

    _graph.processors[newId] = processor.copyWith(
      id: newId,
      isTemplate: false, // In case it was a template, now it's a real node
      uiMetadata: processor.uiMetadata.copyWith(
        position: newPosition,
        lastModified: DateTime.now(),
      ),
    );

    _maybeShrinkCanvas();

    notifyListeners();
    return newId;
  }

  void onNodeDragStart({required String id, required Offset scenePosition}) {
    final processor = _graph.processors[id];
    if (processor == null) return;

    final scenePositionTransformed = MatrixUtils.transformPoint(
      transformationController.value.clone()..invert(),
      scenePosition,
    );
    _grabOffset = scenePositionTransformed - processor.uiMetadata.position;
  }

  void onNodeDragUpdate({required String id, required Offset newPos}) {
    final processor = _graph.processors[id];
    if (processor == null) return;

    final newPosTransformed = MatrixUtils.transformPoint(
      transformationController.value.clone()..invert(),
      newPos,
    );

    var updatedPosition = newPosTransformed - (_grabOffset ?? Offset.zero);

    // Shift all nodes if dragged into negative coordinates
    double shiftX = 0;
    double shiftY = 0;
    if (updatedPosition.dx < 0) shiftX = -updatedPosition.dx;
    if (updatedPosition.dy < 0) shiftY = -updatedPosition.dy;

    if (shiftX != 0 || shiftY != 0) {
      _graph.processors.updateAll(
        (key, processor) => processor.copyWith(
          uiMetadata: processor.uiMetadata.copyWith(
            position: processor.uiMetadata.position + Offset(shiftX, shiftY),
          ),
        ),
      );

      // Move canvas so that negative space is removed
      transformationController.value = transformationController.value.clone()
        ..translateByDouble(-shiftX, -shiftY, 0, 1);

      updatedPosition += Offset(shiftX, shiftY);
    }

    _graph.processors[id] = processor.copyWith(
      uiMetadata: processor.uiMetadata.copyWith(
        position: updatedPosition,
        lastModified: DateTime.now(),
      ),
    );
    _maybeShrinkCanvas();

    notifyListeners();
  }

  void _maybeShrinkCanvas() {
    final minX = _graph.processors.values
        .map((n) => n.uiMetadata.position.dx)
        .reduce(math.min);
    final minY = _graph.processors.values
        .map((n) => n.uiMetadata.position.dy)
        .reduce(math.min);

    if (minX > 0 || minY > 0) {
      // Shift all nodes up-left
      _graph.processors.updateAll(
        (key, n) => n.copyWith(
          uiMetadata: n.uiMetadata.copyWith(
            position: n.uiMetadata.position - Offset(minX, minY),
          ),
        ),
      );

      // Move canvas down-right to make it seamless
      transformationController.value = transformationController.value.clone()
        ..translateByDouble(minX, minY, 0, 1);
    }
  }

  void onNodeDragEnd({required String id}) {
    _grabOffset = null;
  }

  void onNodeClicked({required String id}) {
    final processor = _graph.processors[id];
    if (processor == null) return;
    _graph.processors[id] = processor.copyWith(
      uiMetadata: processor.uiMetadata.copyWith(
        lastModified: DateTime.now(),
      ),
    );
    notifyListeners();
  }

  void onNodeSizeUpdated({required String id, required Size newSize}) {
    final processor = _graph.processors[id];
    if (processor == null) return;
    _graph.processors[id] = processor.copyWith(
      uiMetadata: processor.uiMetadata.copyWith(
        layoutSize: newSize,
        lastModified: DateTime.now(),
      ),
    );

    notifyListeners();
  }

  Size get canvasSize {
    if (_graph.processors.isEmpty) return Size.zero;

    // Use actual layoutSize of nodes
    final maxX = _graph.processors.values.fold<double>(
      0,
      (prev, processor) => math.max(
        prev,
        processor.uiMetadata.position.dx +
            (processor.uiMetadata.layoutSize.width),
      ),
    );

    final maxY = _graph.processors.values.fold<double>(
      0,
      (prev, processor) => math.max(
        prev,
        processor.uiMetadata.position.dy +
            (processor.uiMetadata.layoutSize.height),
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

  void updateIntOption({
    required String processorId,
    required String optionName,
    required int newValue,
  }) {
    final processor = _graph.processors[processorId];
    if (processor == null) return;

    processor.options[optionName] = IntOption(newValue);

    notifyListeners();
  }
}

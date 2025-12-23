import 'dart:math' as math;

import 'package:falcon_gui/node_data.dart';
import 'package:flutter/material.dart';

final NodeManager nodeManager = NodeManager.instance
  ..loadNodes({
    1: const NodeData(id: 1, position: Offset(100, 100), title: 'Node 1'),
    2: const NodeData(id: 2, position: Offset(400, 390), title: 'Node 2'),
    3: const NodeData(id: 3, position: Offset(700, 200), title: 'Node 3'),
  });

class NodeManager extends ChangeNotifier {
  NodeManager._internal();

  static final NodeManager instance = NodeManager._internal();

  Map<int, NodeData> _nodes = {};

  double _minX = 0;
  double _minY = 0;

  Offset? _grabOffset;

  final TransformationController transformationController =
      TransformationController();

  Map<int, NodeData> get nodes => _nodes;

  int _nextId() =>
      (_nodes.keys.isEmpty ? 0 : _nodes.keys.reduce((a, b) => a > b ? a : b)) +
      1;

  void loadNodes(Map<int, NodeData> nodes) {
    _nodes = nodes;

    _maybeShrinkCanvas();
    notifyListeners();
  }

  void addNode({required NodeData node}) {
    _nodes[node.id] = node.copyWith(lastModified: DateTime.now());
    notifyListeners();
  }

  void removeNode({required int id}) {
    _nodes.remove(id);
    notifyListeners();
  }

  int duplicateNode({required int id}) {
    final original = _nodes[id];
    if (original == null) throw Exception('Node $id does not exist');

    final newId = _nextId();
    _nodes[newId] = original.copyWith(
      id: newId,
      position: original.position + const Offset(40, 40),
      title: '${original.title} Copy',
      lastModified: DateTime.now(),
    );
    notifyListeners();
    return newId;
  }

  void onNodeDragStart({required int id, required Offset scenePosition}) {
    final node = _nodes[id];
    if (node == null) return;

    final scenePositionTransformed = MatrixUtils.transformPoint(
      transformationController.value.clone()..invert(),
      scenePosition,
    );
    _grabOffset = scenePositionTransformed - node.position;
  }

  void onNodeDragUpdate({required int id, required Offset newPos}) {
    final node = _nodes[id];
    if (node == null) return;

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
      _nodes.updateAll(
        (key, n) => n.copyWith(position: n.position + Offset(shiftX, shiftY)),
      );

      // Move canvas so that negative space is removed
      transformationController.value = transformationController.value.clone()
        ..translateByDouble(-shiftX, -shiftY, 0, 1);

      updatedPosition += Offset(shiftX, shiftY);
    }

    _nodes[id] = node.copyWith(
      position: updatedPosition,
      lastModified: DateTime.now(),
    );
    _maybeShrinkCanvas();

    notifyListeners();
  }

  void _maybeShrinkCanvas() {
    final minX = _nodes.values.map((n) => n.position.dx).reduce(math.min);
    final minY = _nodes.values.map((n) => n.position.dy).reduce(math.min);

    if (minX > 0 || minY > 0) {
      // Shift all nodes up-left
      _nodes.updateAll(
        (key, n) => n.copyWith(
          position: n.position - Offset(minX, minY),
        ),
      );

      // Move canvas down-right to make it seamless
      transformationController.value = transformationController.value.clone()
        ..translateByDouble(minX, minY, 0, 1);
    }
  }

  void onNodeDragEnd({required int id}) {
    _grabOffset = null;
  }

  void onNodeClicked({required int id}) {
    final node = _nodes[id];
    if (node == null) return;
    _nodes[id] = node.copyWith(lastModified: DateTime.now());
    notifyListeners();
  }

  void onNodeSizeUpdated({required int id, required Size newSize}) {
    final node = _nodes[id];
    if (node == null) return;
    _nodes[id] = node.copyWith(
      layoutSize: newSize,
      lastModified: DateTime.now(),
    );

    notifyListeners();
  }

  Size get canvasSize {
    if (_nodes.isEmpty) return Size.zero;

    // Use actual layoutSize of nodes
    final maxX = _nodes.values.fold<double>(
      0,
      (prev, node) =>
          math.max(prev, node.position.dx + (node.layoutSize.width)),
    );

    final maxY = _nodes.values.fold<double>(
      0,
      (prev, node) =>
          math.max(prev, node.position.dy + (node.layoutSize.height)),
    );

    _minX = _nodes.values.fold<double>(
      double.infinity,
      (prev, node) => math.min(prev, node.position.dx),
    );
    _minY = _nodes.values.fold<double>(
      double.infinity,
      (prev, node) => math.min(prev, node.position.dy),
    );

    return Size(maxX - _minX, maxY - _minY);
  }
}

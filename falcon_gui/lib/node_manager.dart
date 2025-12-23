import 'dart:math' as math;

import 'package:falcon_gui/node_data.dart';
import 'package:flutter/material.dart';

final NodeManager nodeManager = NodeManager.instance;

class NodeManager extends ChangeNotifier {
  NodeManager._internal();

  static final NodeManager instance = NodeManager._internal();

  // Store the minimum x and y of all nodes to simulate negative canvas growth
  double _minX = 0;
  double _minY = 0;

  // Get canvas size, but also shift nodes virtually so it can "grow" -x and -y
  Size get canvasSize {
    double maxX = _nodes.values.fold<double>(
      0,
      (prev, node) => math.max(prev, node.position.dx + 300),
    );
    double maxY = _nodes.values.fold<double>(
      0,
      (prev, node) => math.max(prev, node.position.dy + 200),
    );

    // Update _minX and _minY based on current nodes
    _minX = _nodes.values.fold<double>(0, (prev, node) => math.min(prev, node.position.dx));
    _minY = _nodes.values.fold<double>(0, (prev, node) => math.min(prev, node.position.dy));

    // Total width and height including "negative space"
    return Size(maxX - _minX, maxY - _minY);
  }

  final Map<int, NodeData> _nodes = {
    1: NodeData(id: 1, position: const Offset(100, 100), title: 'Node 1'),
    2: NodeData(id: 2, position: const Offset(300, 200), title: 'Node 2'),
  };

  Map<int, NodeData> get nodes => _nodes;

  int _nextId() =>
      (_nodes.keys.isEmpty ? 0 : _nodes.keys.reduce((a, b) => a > b ? a : b)) +
      1;

  NodeData? getNode(int id) => _nodes[id];

  void addNode(NodeData node) {
    _nodes[node.id] = node.copyWith(lastModified: DateTime.now());
    notifyListeners();
  }

  int duplicateNode(int id) {
    final original = _nodes[id];
    if (original == null) throw Exception('Node $id does not exist');

    final newId = _nextId();
    _nodes[newId] = original.copyWith(
      id: newId,
      position: original.position + const Offset(20, 20),
      title: '${original.title} Copy',
      lastModified: DateTime.now(),
    );
    notifyListeners();
    return newId;
  }

  void updatePosition(int id, Offset newPos) {
    final node = _nodes[id];
    if (node == null) return;

    _nodes[id] = node.copyWith(position: newPos, lastModified: DateTime.now());
    notifyListeners();
  }

  void focus(int id) {
    final node = _nodes[id];
    if (node == null) return;
    _nodes[id] = node.copyWith(lastModified: DateTime.now());
    notifyListeners();
  }

  void removeNode(int id) {
    _nodes.remove(id);
    notifyListeners();
  }

  /// Get a shifted position for rendering nodes
  /// This simulates negative coordinates visually
  Offset getVisualPosition(NodeData node) {
    // Shift every node by -_minX and -_minY to make canvas appear to grow -x/-y
    return node.position - Offset(_minX, _minY);
  }
}

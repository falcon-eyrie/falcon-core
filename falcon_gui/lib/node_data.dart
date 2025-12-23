import 'package:flutter/material.dart';

class NodeData {
  const NodeData({
    required this.id,
    required this.position,
    required this.title,
    this.layoutSize = Size.zero,
    this.lastModified,
  });

  final int id;
  final Offset position;
  final Size layoutSize;
  final String title;
  final DateTime? lastModified;

  NodeData copyWith({
    int? id,
    Offset? position,
    String? title,
    DateTime? lastModified,
    Size? layoutSize,
  }) {
    return NodeData(
      id: id ?? this.id,
      layoutSize: layoutSize ?? this.layoutSize,
      position: position ?? this.position,
      title: title ?? this.title,
      lastModified: lastModified ?? this.lastModified,
    );
  }
}

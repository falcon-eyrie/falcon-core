import 'package:flutter/material.dart';

class NodeData {
  NodeData({
    required this.id,
    required this.position,
    required this.title,
    DateTime? lastModified,
  }) : lastModified = lastModified ?? DateTime.now();

  final int id;
  final Offset position;
  final String title;
  final DateTime lastModified;

  NodeData copyWith({
    int? id,
    Offset? position,
    String? title,
    DateTime? lastModified,
  }) {
    return NodeData(
      id: id ?? this.id,
      position: position ?? this.position,
      title: title ?? this.title,
      lastModified: lastModified ?? this.lastModified,
    );
  }
}

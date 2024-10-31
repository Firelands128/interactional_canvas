import 'package:flutter/material.dart';

/// A node in the [InteractionalCanvas].
class Node<T> {
  Node({
    required this.key,
    required this.size,
    required this.offset,
    required this.child,
    this.label,
    this.resizeMode = ResizeMode.disabled,
    this.allowMove = true,
    this.value,
  });

  String get id => key.toString();

  final LocalKey key;
  late Size size;
  late Offset offset;
  String? label;
  T? value;
  final Widget child;
  final ResizeMode resizeMode;
  bool resizing = false;
  final bool allowMove;

  Rect get rect => offset & size;

  void update({Size? size, Offset? offset, String? label}) {
    if (offset != null && (size != null || allowMove)) {
      this.offset = offset;
    }

    if (size != null && resizeMode.isEnabled) {
      this.size = size;
    }

    if (label != null) this.label = label;
  }
}

enum ResizeMode {
  disabled,
  corners,
  edges,
  cornersAndEdges;

  bool get isEnabled => this != ResizeMode.disabled;

  bool get containsCornerHandles =>
      this == ResizeMode.corners || this == ResizeMode.cornersAndEdges;

  bool get containsEdgeHandles => this == ResizeMode.edges || this == ResizeMode.cornersAndEdges;
}

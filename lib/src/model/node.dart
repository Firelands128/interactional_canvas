import 'package:flutter/material.dart';

/// A node in the [InteractionalCanvas].
class Node<T> {
  Node({
    required this.key,
    required this.size,
    required this.offset,
    required this.child,
    this.label,
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
  bool resizing = false;
  final bool allowMove;

  Rect get rect => offset & size;

  void update({Size? size, Offset? offset, String? label}) {
    if (offset != null && (size != null || allowMove)) {
      this.offset = offset;
    }

    if (size != null) {
      this.size = size;
    }

    if (label != null) this.label = label;
  }
}

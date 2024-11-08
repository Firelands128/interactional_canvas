import 'dart:math';

import 'package:flutter/material.dart';
import 'package:interactional_canvas/interactional_canvas.dart';

import '../utils/utils.dart';

class ResizeHandler extends StatefulWidget {
  ResizeHandler({
    super.key,
    required this.controller,
    required this.node,
    required this.alignment,
    required this.gridSize,
    required this.size,
    required this.minimumNodeSize,
  });

  final CanvasController controller;
  final Node node;
  final ResizeHandlerAlignment alignment;
  final Size gridSize;
  final double size;
  final Size minimumNodeSize;

  @override
  State<ResizeHandler> createState() => _ResizeHandlerState();
}

class _ResizeHandlerState extends State<ResizeHandler> {
  late final CanvasController controller;
  late final Node node;

  late Rect initialBounds;
  late Rect minimumSizeBounds;
  late Offset draggingOffset;

  @override
  void initState() {
    super.initState();
    controller = widget.controller;
    node = widget.node;
  }

  void onResize(Offset delta) {
    draggingOffset = draggingOffset + delta;
    Rect newBounds = initialBounds;

    if (widget.alignment.isLeft) {
      double left = min(minimumSizeBounds.left, newBounds.left + draggingOffset.dx);
      if (controller.snapResizeToGrid) {
        left = adjustEdgeToGrid(
          left,
          widget.gridSize.width,
          maximum: minimumSizeBounds.left,
        );
      }
      newBounds = Rect.fromLTRB(left, newBounds.top, newBounds.right, newBounds.bottom);
    }
    if (widget.alignment.isTop) {
      double top = min(minimumSizeBounds.top, newBounds.top + draggingOffset.dy);
      if (controller.snapResizeToGrid) {
        top = adjustEdgeToGrid(
          top,
          widget.gridSize.height,
          maximum: minimumSizeBounds.top,
        );
      }
      newBounds = Rect.fromLTRB(newBounds.left, top, newBounds.right, newBounds.bottom);
    }
    if (widget.alignment.isRight) {
      double right = max(minimumSizeBounds.right, newBounds.right + draggingOffset.dx);
      if (controller.snapResizeToGrid) {
        right = adjustEdgeToGrid(
          right,
          widget.gridSize.width,
          minimum: minimumSizeBounds.right,
        );
      }
      newBounds = Rect.fromLTRB(newBounds.left, newBounds.top, right, newBounds.bottom);
    }
    if (widget.alignment.isBottom) {
      double bottom = max(minimumSizeBounds.bottom, newBounds.bottom + draggingOffset.dy);
      if (controller.snapResizeToGrid) {
        bottom = adjustEdgeToGrid(
          bottom,
          widget.gridSize.height,
          minimum: minimumSizeBounds.bottom,
        );
      }
      newBounds = Rect.fromLTRB(newBounds.left, newBounds.top, newBounds.right, bottom);
    }

    if (controller.shiftPressed || controller.keepRatio) {
      final ratio =
          (initialBounds.width * newBounds.width + initialBounds.height * newBounds.height) /
              (pow(initialBounds.width, 2) + pow(initialBounds.height, 2));
      final proportionalWidth = ratio * initialBounds.width;
      final proportionalHeight = ratio * initialBounds.height;
      switch (widget.alignment.alignment) {
        case Alignment.topLeft:
          newBounds = Rect.fromLTWH(
            newBounds.right - proportionalWidth,
            newBounds.bottom - proportionalHeight,
            proportionalWidth,
            proportionalHeight,
          );
        case Alignment.topRight:
          newBounds = Rect.fromLTWH(
            newBounds.left,
            newBounds.bottom - proportionalHeight,
            proportionalWidth,
            proportionalHeight,
          );
        case Alignment.bottomLeft:
          newBounds = Rect.fromLTWH(
            newBounds.right - proportionalWidth,
            newBounds.top,
            proportionalWidth,
            proportionalHeight,
          );
        case Alignment.bottomRight:
          newBounds = Rect.fromLTWH(
            newBounds.left,
            newBounds.top,
            proportionalWidth,
            proportionalHeight,
          );
      }
    }

    node.update(size: newBounds.size, offset: newBounds.topLeft);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Positioned(
      left: widget.alignment.isLeft
          ? 0
          : widget.alignment.isHorizontalCenter
              ? node.size.width / 2 - widget.size / 2
              : null,
      right: widget.alignment.isRight ? 0 : null,
      top: widget.alignment.isTop
          ? 0
          : widget.alignment.isVerticalCenter
              ? node.size.height / 2 - widget.size / 2
              : null,
      bottom: widget.alignment.isBottom ? 0 : null,
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (details) {
          initialBounds = Rect.fromLTWH(
            node.offset.dx,
            node.offset.dy,
            node.size.width,
            node.size.height,
          );
          minimumSizeBounds = Rect.fromLTRB(
            initialBounds.right - widget.minimumNodeSize.width,
            initialBounds.bottom - widget.minimumNodeSize.height,
            initialBounds.left + widget.minimumNodeSize.width,
            initialBounds.top + widget.minimumNodeSize.height,
          );
          draggingOffset = Offset.zero;
          node.resizing = true;
        },
        onPointerUp: (details) {
          node.resizing = false;
        },
        onPointerCancel: (details) {
          node.resizing = false;
        },
        onPointerMove: (details) {
          if (widget.controller.mouseDown) {
            onResize(details.delta / controller.scale);
            controller.refreshCanvas();
          }
        },
        child: Container(
          height: widget.size,
          width: widget.size,
          decoration: BoxDecoration(
            color: colors.surfaceVariant,
            border: Border.all(
              color: colors.onSurfaceVariant,
              width: 1,
            ),
          ),
        ),
      ),
    );
  }
}

class ResizeHandlerAlignment {
  final Alignment alignment;

  const ResizeHandlerAlignment(this.alignment);

  bool get isLeft => alignment.x < 0;

  bool get isRight => alignment.x > 0;

  bool get isTop => alignment.y < 0;

  bool get isBottom => alignment.y > 0;

  bool get isHorizontalCenter => alignment.x == 0;

  bool get isVerticalCenter => alignment.y == 0;
}

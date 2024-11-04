import 'package:flutter/material.dart';
import 'package:interactional_canvas/interactional_canvas.dart';

import 'resize_handler.dart';

class NodeRenderer extends StatelessWidget {
  const NodeRenderer({
    super.key,
    required this.node,
    required this.controller,
    required this.gridSize,
    required this.resizeMode,
    required this.resizeHandlerSize,
  });

  final Node node;
  final CanvasController controller;
  final Size gridSize;
  final ResizeMode resizeMode;
  final double resizeHandlerSize;

  static const double borderInset = 0;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final fonts = Theme.of(context).textTheme;
    final showCornerHandles = resizeMode.containsCornerHandles && controller.isSelected(node.key);
    final showEdgeHandles = resizeMode.containsEdgeHandles && controller.isSelected(node.key);
    return SizedBox.fromSize(
      size: node.size,
      child: Stack(clipBehavior: Clip.none, children: [
        Positioned.fill(
          key: key,
          child: node.child,
        ),
        if (node.label != null)
          Center(
            child: Text(
              node.label!,
              style: fonts.bodyMedium?.copyWith(
                color: colors.onSurface,
                shadows: [
                  Shadow(
                    offset: const Offset(0.8, 0.8),
                    blurRadius: 3,
                    color: colors.surface,
                  ),
                ],
              ),
            ),
          ),
        if (controller.isSelected(node.key) || controller.isHovered(node.key))
          Positioned(
            top: borderInset,
            left: borderInset,
            right: borderInset,
            bottom: borderInset,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: controller.isSelected(node.key) ? colors.primary : colors.outline,
                    width: 1,
                  ),
                ),
              ),
            ),
          ),
        if (showCornerHandles) ...[
          _buildResizeHandler(Alignment.bottomRight),
          _buildResizeHandler(Alignment.bottomLeft),
          _buildResizeHandler(Alignment.topRight),
          _buildResizeHandler(Alignment.topLeft),
        ],
        if (showEdgeHandles) ...[
          _buildResizeHandler(Alignment.centerLeft),
          _buildResizeHandler(Alignment.centerRight),
          _buildResizeHandler(Alignment.topCenter),
          _buildResizeHandler(Alignment.bottomCenter),
        ],
      ]),
    );
  }

  ResizeHandler _buildResizeHandler(Alignment alignment) {
    final resizeHandlerAlignment = ResizeHandlerAlignment(alignment);
    return ResizeHandler(
      controller: controller,
      node: node,
      alignment: resizeHandlerAlignment,
      gridSize: gridSize,
      size: resizeHandlerSize,
    );
  }
}

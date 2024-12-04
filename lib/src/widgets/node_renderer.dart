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
    required this.isSelected,
    required this.isHovered,
    required this.onResized,
  });

  final Node node;
  final CanvasController controller;
  final Size gridSize;
  final ResizeMode resizeMode;
  final double resizeHandlerSize;
  final bool isSelected;
  final bool isHovered;
  final ValueChanged<Node>? onResized;

  static const double borderInset = 0;

  Size get minimumNodeSize {
    if (resizeMode.containsEdgeHandles) {
      return Size(resizeHandlerSize * 3, resizeHandlerSize * 3);
    } else {
      return Size(resizeHandlerSize * 2, resizeHandlerSize * 2);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final fonts = Theme.of(context).textTheme;
    final showCornerHandles = resizeMode.containsCornerHandles && isSelected;
    final showEdgeHandles = resizeMode.containsEdgeHandles && isSelected;
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
        if (isSelected || isHovered)
          Positioned(
            top: borderInset,
            left: borderInset,
            right: borderInset,
            bottom: borderInset,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isSelected ? colors.primary : colors.outline,
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
      minimumNodeSize: minimumNodeSize,
      onResized: onResized,
    );
  }
}

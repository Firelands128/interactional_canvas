import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:interactional_canvas/interactional_canvas.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;

import '../delegate/nodes_delegate.dart';
import 'grid_background.dart';
import 'marquee.dart';
import 'node_renderer.dart';

/// A Widget that renders a canvas that can be
/// panned and zoomed.
///
/// This can not be shrink wrapped, so it should be used
/// as a full screen / expanded widget.
class InteractionalCanvas extends StatefulWidget {
  const InteractionalCanvas({
    super.key,
    required this.controller,
    this.drawVisibleOnly = false,
    this.backgroundBuilder,
    this.gridSize = const Size.square(50),
    this.resizeMode = ResizeMode.cornersAndEdges,
    this.resizeHandlerSize = 10,
  });

  final CanvasController controller;
  final bool drawVisibleOnly;
  final Widget Function(BuildContext, Rect)? backgroundBuilder;
  final Size gridSize;
  final ResizeMode resizeMode;
  final double resizeHandlerSize;

  @override
  State<InteractionalCanvas> createState() => InteractionalCanvasState();
}

class InteractionalCanvasState extends State<InteractionalCanvas> {
  @override
  void initState() {
    super.initState();
    controller.addListener(onUpdate);
    controller.focusNode.requestFocus();
  }

  @override
  void dispose() {
    controller.removeListener(onUpdate);
    controller.focusNode.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant InteractionalCanvas oldWidget) {
    if (oldWidget.controller != controller) {
      oldWidget.controller.removeListener(onUpdate);
      controller.addListener(onUpdate);
    }
    if (oldWidget.drawVisibleOnly != widget.drawVisibleOnly) {
      if (mounted) setState(() {});
    }
    super.didUpdateWidget(oldWidget);
  }

  void onUpdate() {
    if (mounted) setState(() {});
  }

  CanvasController get controller => widget.controller;

  Rect axisAlignedBoundingBox(Quad quad) {
    double xMin = quad.point0.x;
    double xMax = quad.point0.x;
    double yMin = quad.point0.y;
    double yMax = quad.point0.y;

    for (final Vector3 point in <Vector3>[
      quad.point1,
      quad.point2,
      quad.point3,
    ]) {
      if (point.x < xMin) {
        xMin = point.x;
      } else if (point.x > xMax) {
        xMax = point.x;
      }

      if (point.y < yMin) {
        yMin = point.y;
      } else if (point.y > yMax) {
        yMax = point.y;
      }
    }

    return Rect.fromLTRB(xMin, yMin, xMax, yMax);
  }

  Widget buildBackground(BuildContext context, Quad quad) {
    final viewport = axisAlignedBoundingBox(quad);
    if (widget.backgroundBuilder != null) {
      return widget.backgroundBuilder!(context, viewport);
    }
    return GridBackground(
      cellWidth: widget.gridSize.width,
      cellHeight: widget.gridSize.height,
      viewport: viewport,
    );
  }

  List<Node> getNodes(BoxConstraints constraints) {
    if (widget.drawVisibleOnly) {
      final nodes = <Node>[];
      final viewport = controller.getRect(constraints);
      for (final node in controller.nodes) {
        if (node.rect.overlaps(viewport)) {
          nodes.add(node);
        }
      }
      return nodes;
    }
    return controller.nodes;
  }

  void handleCombinationKeyDownEvent(KeyDownEvent event) {
    if (event.logicalKey == LogicalKeyboardKey.shiftLeft ||
        event.logicalKey == LogicalKeyboardKey.shiftRight) {
      controller.shiftPressed = true;
    }
    if (event.logicalKey == LogicalKeyboardKey.controlLeft ||
        event.logicalKey == LogicalKeyboardKey.controlRight) {
      controller.controlPressed = true;
    }
    if (event.logicalKey == LogicalKeyboardKey.metaLeft ||
        event.logicalKey == LogicalKeyboardKey.metaRight) {
      controller.metaPressed = true;
    }
    if (event.logicalKey == LogicalKeyboardKey.space) {
      controller.spacePressed = true;
    }
  }

  void handleArrowKeyDownEvent(KeyDownEvent event) {
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      if (controller.hasSelection) {
        if (controller.shiftPressed) {
          controller.moveSelection(const Offset(-100, 0));
        } else {
          controller.moveSelection(const Offset(-10, 0));
        }
      }
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      if (controller.hasSelection) {
        if (controller.shiftPressed) {
          controller.moveSelection(const Offset(0, -100));
        } else {
          controller.moveSelection(const Offset(0, -10));
        }
      }
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      if (controller.hasSelection) {
        if (controller.shiftPressed) {
          controller.moveSelection(const Offset(100, 0));
        } else {
          controller.moveSelection(const Offset(10, 0));
        }
      }
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      if (controller.hasSelection) {
        if (controller.shiftPressed) {
          controller.moveSelection(const Offset(0, 100));
        } else {
          controller.moveSelection(const Offset(0, 10));
        }
      }
    }
  }

  void handleCombinationKeyUpEvent(KeyUpEvent event) {
    if (event.logicalKey == LogicalKeyboardKey.shiftLeft ||
        event.logicalKey == LogicalKeyboardKey.shiftRight) {
      controller.shiftPressed = false;
    }
    if (event.logicalKey == LogicalKeyboardKey.metaLeft ||
        event.logicalKey == LogicalKeyboardKey.metaRight) {
      controller.metaPressed = false;
    }
    if (event.logicalKey == LogicalKeyboardKey.controlLeft ||
        event.logicalKey == LogicalKeyboardKey.controlRight) {
      controller.controlPressed = false;
    }
    if (event.logicalKey == LogicalKeyboardKey.space) {
      controller.spacePressed = false;
    }
    if (event.logicalKey == LogicalKeyboardKey.delete ||
        event.logicalKey == LogicalKeyboardKey.backspace) {
      if (controller.focusNode.hasFocus) {
        controller.deleteSelection();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: controller.focusNode,
      onKeyEvent: (event) {
        if (event is KeyDownEvent) {
          handleCombinationKeyDownEvent(event);
          handleArrowKeyDownEvent(event);
        }
        if (event is KeyUpEvent) {
          handleCombinationKeyUpEvent(event);
        }
      },
      child: Listener(
        onPointerDown: (details) {
          final localPosition = controller.toLocal(details.localPosition);
          controller.mouseDown = true;
          controller.checkSelection(localPosition);
          if (controller.spacePressed) return;
          if (controller.shiftPressed && !controller.resizing || controller.selection.isEmpty) {
            controller.marqueeStart = localPosition;
            controller.marqueeEnd = localPosition;
          }
        },
        onPointerUp: (_) {
          controller.mouseDown = false;
          if (controller.marqueeStart != null && controller.marqueeEnd != null) {
            controller.checkMarqueeSelection();
          }
          controller.marqueeStart = null;
          controller.marqueeEnd = null;
        },
        onPointerCancel: (_) {
          controller.mouseDown = false;
        },
        onPointerHover: (details) {
          controller.mousePosition = controller.toLocal(details.localPosition);
          controller.checkSelection(controller.mousePosition, true);
        },
        onPointerMove: (details) {
          if (controller.marqueeStart != null && controller.marqueeEnd != null) {
            controller.marqueeEnd = controller.toLocal(details.localPosition);
            controller.checkMarqueeSelection(true);
          }
        },
        child: LayoutBuilder(
          builder: (context, constraints) {
            return InteractiveViewer.builder(
              transformationController: controller.transform,
              panEnabled: controller.canvasMoveEnabled,
              scaleEnabled: controller.canvasMoveEnabled,
              onInteractionStart: (details) {
                controller.mousePosition = controller.toLocal(details.focalPoint);
                controller.mouseDragStart = controller.mousePosition;
              },
              onInteractionUpdate: (details) {
                if (!controller.mouseDown) {
                  controller.scale = controller.scale * details.scale;
                } else if (controller.spacePressed) {
                  controller.pan(details.focalPointDelta / controller.scale);
                } else if (controller.selection.isNotEmpty &&
                    !controller.shiftPressed &&
                    !controller.resizing) {
                  controller.dragSelection(
                    controller.toLocal(details.focalPoint),
                    gridSize: widget.gridSize,
                  );
                }
                controller.mousePosition = controller.toLocal(details.focalPoint);
              },
              onInteractionEnd: (_) => controller.mouseDragStart = null,
              minScale: controller.minScale,
              maxScale: controller.maxScale,
              boundaryMargin: const EdgeInsets.all(double.infinity),
              builder: (context, quad) {
                final nodes = getNodes(constraints);
                return SizedBox.fromSize(
                  size: controller.getMaxSize().size,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      if (widget.controller.showGrid)
                        Positioned.fill(
                          child: buildBackground(context, quad),
                        ),
                      Positioned.fill(
                        child: CustomMultiChildLayout(
                          delegate: NodesDelegate(nodes),
                          children: nodes
                              .map((e) => LayoutId(
                                    key: e.key,
                                    id: e,
                                    child: NodeRenderer(
                                      node: e,
                                      controller: controller,
                                      gridSize: widget.gridSize,
                                      resizeMode: widget.resizeMode,
                                      resizeHandlerSize: widget.resizeHandlerSize,
                                    ),
                                  ))
                              .toList(),
                        ),
                      ),
                      if (controller.marqueeStart != null && controller.marqueeEnd != null) ...[
                        Positioned.fill(
                          child: Marquee(
                            start: controller.marqueeStart!,
                            end: controller.marqueeEnd!,
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:interactional_canvas/interactional_canvas.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;

import '../delegate/nodes_delegate.dart';
import '../utils/utils.dart';
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
    this.keepRatio = false,
    this.showGrid = true,
    this.snapMovementToGrid = true,
    this.snapResizeToGrid = true,
    this.backgroundBuilder,
    this.gridSize = const Size.square(50),
    this.resizeMode = ResizeMode.cornersAndEdges,
    this.resizeHandlerSize = 10,
    this.nodes = const [],
    this.onSelect,
    this.onDeselect,
    this.onHover,
    this.onLeave,
  });

  final CanvasController controller;
  final bool drawVisibleOnly;
  final bool keepRatio;
  final bool showGrid;
  final bool snapMovementToGrid;
  final bool snapResizeToGrid;
  final Widget Function(BuildContext, Rect)? backgroundBuilder;
  final Size gridSize;
  final ResizeMode resizeMode;
  final double resizeHandlerSize;
  final List<Node> nodes;
  final ValueChanged<List<Node>>? onSelect;
  final ValueChanged<List<Node>>? onDeselect;
  final ValueChanged<List<Node>>? onHover;
  final ValueChanged<List<Node>>? onLeave;

  @override
  State<InteractionalCanvas> createState() => InteractionalCanvasState();
}

class InteractionalCanvasState extends State<InteractionalCanvas> {
  static const double minScale = 0.4;
  static const double maxScale = 4;

  final transform = TransformationController();
  final focusNode = FocusNode();
  final Set<Key> _selected = {};
  final Set<Key> _hovered = {};
  final Map<Key, Offset> _selectedOrigins = {};

  late bool keepRatio;
  late bool showGrid;
  late bool snapMovementToGrid;
  late bool snapResizeToGrid;
  bool resizing = false;
  bool mouseDown = false;
  bool shiftPressed = false;
  bool spacePressed = false;
  bool controlPressed = false;
  bool metaPressed = false;
  double scale = 1;
  Offset mousePosition = Offset.zero;
  Offset? mouseDragStart;
  Offset? marqueeStart, marqueeEnd;

  @override
  void initState() {
    super.initState();
    controller.addListener(_onUpdate);
    focusNode.requestFocus();

    keepRatio = widget.keepRatio;
    showGrid = widget.showGrid;
    snapMovementToGrid = widget.snapMovementToGrid;
    snapResizeToGrid = widget.snapResizeToGrid;

    controller.focusNode = focusNode;
    controller.isKeepRatio = () => keepRatio;
    controller.isShowGrid = () => showGrid;
    controller.isSnapMovementToGrid = () => snapMovementToGrid;
    controller.isSnapResizeToGrid = () => snapResizeToGrid;
    controller.getScale = () => scale;
    controller.setResizing = (bool value) => resizing = value;
    controller.isMouseDown = () => mouseDown;
    controller.isShiftPressed = () => shiftPressed;
    controller.getNodes = () => nodes;
    controller.getSelection = () => selection;
    controller.refresh = refresh;
    controller.add = add;
    controller.update = update;
    controller.zoomIn = zoomIn;
    controller.zoomOut = zoomOut;
    controller.zoomReset = zoomReset;
    controller.panUp = panUp;
    controller.panDown = panDown;
    controller.panLeft = panLeft;
    controller.panRight = panRight;
    controller.selectAll = selectAll;
    controller.deselectAll = deselectAll;
    controller.bringForward = bringForward;
    controller.bringToFront = bringToFront;
    controller.sendBackward = sendBackward;
    controller.sendToBack = sendToBack;
    controller.deleteSelection = deleteSelection;
    controller.toggleKeepRatio = toggleKeepRatio;
    controller.toggleShowGrid = toggleShowGrid;
    controller.toggleSnapToGrid = toggleSnapToGrid;
  }

  @override
  void dispose() {
    controller.removeListener(_onUpdate);
    focusNode.dispose();
    super.dispose();
  }

  CanvasController get controller => widget.controller;

  Matrix4 get matrix => transform.value;

  List<Node> get nodes => widget.nodes;

  List<Node> get selection => nodes.where((e) => _selected.contains(e.key)).toList();

  List<Node> get hovered => nodes.where((e) => _hovered.contains(e.key)).toList();

  bool get hasSelection => _selected.isNotEmpty;

  bool get canvasMoveEnabled => !mouseDown;

  List<Node> _getNodeList(Set<Key> keys) => nodes.where((e) => keys.contains(e.key)).toList();

  Rect _getMaxSize() {
    Rect rect = Rect.zero;
    for (final child in nodes) {
      rect = Rect.fromLTRB(
        min(rect.left, child.rect.left),
        min(rect.top, child.rect.top),
        max(rect.right, child.rect.right),
        max(rect.bottom, child.rect.bottom),
      );
    }
    return rect;
  }

  bool _isSelected(LocalKey key) => _selected.contains(key);

  bool _isHovered(LocalKey key) => _hovered.contains(key);

  void _cacheSelectedOrigins() {
    _selectedOrigins.clear();
    for (final key in _selected) {
      final index = nodes.indexWhere((e) => e.key == key);
      if (index == -1) return;
      final current = nodes[index];
      _selectedOrigins[key] = current.offset;
    }
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  void refresh() {
    controller.notify();
  }

  void add(Node child) {
    nodes.add(child);
    refresh();
  }

  void update(Node child) {
    final idx = nodes.indexWhere((e) => e.key == child.key);
    if (idx == -1) return;
    nodes[idx] = child;
    refresh();
  }

  void remove(Key key) {
    nodes.removeWhere((e) => e.key == key);
    _selected.remove(key);
    _selectedOrigins.remove(key);
    refresh();
  }

  void zoom(double delta) {
    final matrix = transform.value.clone();
    final local = mousePosition;
    matrix.translate(local.dx, local.dy);
    matrix.scale(delta, delta);
    matrix.translate(-local.dx, -local.dy);
    transform.value = matrix;
    refresh();
  }

  void zoomIn({double delta = 1.1}) {
    scale = scale * delta;
    zoom(delta);
  }

  void zoomOut({double delta = 0.9}) {
    scale = scale * delta;
    zoom(delta);
  }

  void zoomReset() {
    scale = 1;
    transform.value = Matrix4.identity();
  }

  void pan(Offset delta) {
    final matrix = transform.value.clone();
    matrix.translate(delta.dx, delta.dy);
    transform.value = matrix;
    refresh();
  }

  void panUp() {
    if (!hasSelection) {
      pan(const Offset(0, -10));
    }
  }

  void panDown() {
    if (!hasSelection) {
      pan(const Offset(0, 10));
    }
  }

  void panLeft() {
    if (!hasSelection) {
      pan(const Offset(-10, 0));
    }
  }

  void panRight() {
    if (!hasSelection) {
      pan(const Offset(10, 0));
    }
  }

  void selectAll() {
    final toSelect = nodes.map((e) => e.key).toSet().difference(_selected);
    _selected.addAll(toSelect);
    if (widget.onSelect != null) widget.onSelect!(_getNodeList(toSelect));
    _cacheSelectedOrigins();
    refresh();
  }

  void deselectAll([bool hover = false]) {
    if (hover) {
      final remove = Set<Key>.from(_hovered);
      _hovered.removeAll(remove);
      if (widget.onLeave != null) widget.onLeave!(_getNodeList(remove));
    } else {
      final toDeselect = Set<Key>.from(_selected);
      _selected.removeAll(toDeselect);
      if (widget.onDeselect != null) widget.onDeselect!(_getNodeList(toDeselect));
      _selectedOrigins.clear();
    }
    refresh();
  }

  void bringForward() {
    final selection = _selected.toList();
    if (selection.length == 1) {
      final key = selection.first;
      final index = nodes.indexWhere((e) => e.key == key);
      if (index == -1) return;
      if (index == nodes.length - 1) return;
      final current = nodes[index];
      nodes.removeAt(index);
      nodes.insert(index + 1, current);
      refresh();
    }
  }

  void bringToFront() {
    final selection = _selected.toList();
    for (final key in selection) {
      final index = nodes.indexWhere((e) => e.key == key);
      if (index == -1) continue;
      final current = nodes[index];
      nodes.removeAt(index);
      nodes.add(current);
    }
    refresh();
  }

  void sendBackward() {
    final selection = _selected.toList();
    if (selection.length == 1) {
      final key = selection.first;
      final index = nodes.indexWhere((e) => e.key == key);
      if (index == -1) return;
      if (index == 0) return;
      final current = nodes[index];
      nodes.removeAt(index);
      nodes.insert(index - 1, current);
      refresh();
    }
  }

  void sendToBack() {
    final selection = _selected.toList();
    for (final key in selection) {
      final index = nodes.indexWhere((e) => e.key == key);
      if (index == -1) continue;
      final current = nodes[index];
      nodes.removeAt(index);
      nodes.insert(0, current);
    }
    refresh();
  }

  void deleteSelection() {
    final selection = _selected.toList();
    for (final key in selection) {
      final index = nodes.indexWhere((e) => e.key == key);
      if (index == -1) continue;
      nodes.removeAt(index);
      _selectedOrigins.remove(key);
    }
    refresh();
  }

  void toggleKeepRatio() {
    final newKeepRatio = !keepRatio;
    keepRatio = newKeepRatio;
    refresh();
  }

  void toggleShowGrid() {
    final newShowGridValue = !showGrid;
    showGrid = newShowGridValue;
    refresh();
  }

  void toggleSnapToGrid() {
    final newSnapValue = !snapMovementToGrid;
    snapMovementToGrid = newSnapValue;
    snapResizeToGrid = newSnapValue;
    refresh();
  }

  void _moveSelection(Offset delta) {
    for (final key in _selected) {
      final index = nodes.indexWhere((e) => e.key == key);
      if (index == -1) continue;
      final current = nodes[index];
      final origin = current.offset;
      Offset offset = origin + delta;
      current.update(offset: offset);
    }
    refresh();
  }

  void _handleCombinationKeyDownEvent(KeyDownEvent event) {
    if (event.logicalKey == LogicalKeyboardKey.shiftLeft ||
        event.logicalKey == LogicalKeyboardKey.shiftRight) {
      shiftPressed = true;
    }
    if (event.logicalKey == LogicalKeyboardKey.controlLeft ||
        event.logicalKey == LogicalKeyboardKey.controlRight) {
      controlPressed = true;
    }
    if (event.logicalKey == LogicalKeyboardKey.metaLeft ||
        event.logicalKey == LogicalKeyboardKey.metaRight) {
      metaPressed = true;
    }
    if (event.logicalKey == LogicalKeyboardKey.space) {
      spacePressed = true;
    }
  }

  void _handleArrowKeyDownEvent(KeyDownEvent event) {
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      if (hasSelection) {
        if (shiftPressed) {
          _moveSelection(const Offset(-100, 0));
        } else {
          _moveSelection(const Offset(-10, 0));
        }
      }
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      if (hasSelection) {
        if (shiftPressed) {
          _moveSelection(const Offset(0, -100));
        } else {
          _moveSelection(const Offset(0, -10));
        }
      }
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      if (hasSelection) {
        if (shiftPressed) {
          _moveSelection(const Offset(100, 0));
        } else {
          _moveSelection(const Offset(10, 0));
        }
      }
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      if (hasSelection) {
        if (shiftPressed) {
          _moveSelection(const Offset(0, 100));
        } else {
          _moveSelection(const Offset(0, 10));
        }
      }
    }
  }

  void _handleCombinationKeyUpEvent(KeyUpEvent event) {
    if (event.logicalKey == LogicalKeyboardKey.shiftLeft ||
        event.logicalKey == LogicalKeyboardKey.shiftRight) {
      shiftPressed = false;
    }
    if (event.logicalKey == LogicalKeyboardKey.metaLeft ||
        event.logicalKey == LogicalKeyboardKey.metaRight) {
      metaPressed = false;
    }
    if (event.logicalKey == LogicalKeyboardKey.controlLeft ||
        event.logicalKey == LogicalKeyboardKey.controlRight) {
      controlPressed = false;
    }
    if (event.logicalKey == LogicalKeyboardKey.space) {
      spacePressed = false;
    }
    if (event.logicalKey == LogicalKeyboardKey.delete ||
        event.logicalKey == LogicalKeyboardKey.backspace) {
      if (focusNode.hasFocus) {
        deleteSelection();
      }
    }
  }

  void _checkSelection(Offset localPosition, [bool hover = false]) {
    final offset = localPosition;
    final selection = <Key>[];
    for (final child in nodes) {
      final rect = child.rect;
      if (rect.contains(offset)) {
        selection.add(child.key);
      }
    }
    if (selection.isNotEmpty) {
      if (shiftPressed) {
        _setSelection({selection.last, ..._selected.toSet()}, hover);
      } else {
        _setSelection({selection.last}, hover);
      }
    } else {
      if (!shiftPressed) deselectAll(hover);
    }
  }

  void _checkMarqueeSelection([bool hover = false]) {
    if (marqueeStart == null || marqueeEnd == null) return;
    final selection = <Key>{};
    final rect = Rect.fromPoints(marqueeStart!, marqueeEnd!);
    for (final child in nodes) {
      if (rect.overlaps(child.rect)) {
        selection.add(child.key);
      }
    }
    if (selection.isNotEmpty) {
      if (shiftPressed) {
        _setSelection(selection.union(_selected.toSet()), hover);
      } else {
        _setSelection(selection, hover);
      }
    } else {
      deselectAll(hover);
    }
  }

  void _setSelection(Set<Key> keys, [bool hover = false]) {
    if (hover) {
      final remove = _hovered.difference(keys);
      final add = keys.difference(_hovered);
      _hovered.removeAll(remove);
      _hovered.addAll(add);
      if (widget.onHover != null) widget.onHover!(_getNodeList(add));
      if (widget.onLeave != null) widget.onLeave!(_getNodeList(remove));
    } else {
      final toDeselect = _selected.difference(keys);
      final toSelect = keys.difference(_selected);
      _selected.removeAll(toDeselect);
      _selected.addAll(toSelect);
      if (widget.onDeselect != null) widget.onDeselect!(_getNodeList(toDeselect));
      if (widget.onSelect != null) widget.onSelect!(_getNodeList(toSelect));
      _cacheSelectedOrigins();
    }
    refresh();
  }

  double _getClosestSnapPosition(double rawEdge, double nodeLength, double gridEdge) {
    final snapAtStartPos = adjustEdgeToGrid(rawEdge, gridEdge);
    final snapAtStartDelta = (snapAtStartPos - rawEdge).abs();
    final snapAtEndPos = adjustEdgeToGrid(rawEdge + nodeLength, gridEdge) - nodeLength;
    final snapAtEndDelta = (snapAtEndPos - rawEdge).abs();
    return snapAtEndDelta < snapAtStartDelta ? snapAtEndPos : snapAtStartPos;
  }

  void _dragSelection(Offset position, {Size? gridSize}) {
    final delta = mouseDragStart != null ? position - mouseDragStart! : position;
    for (final key in _selected) {
      final index = nodes.indexWhere((e) => e.key == key);
      if (index == -1) continue;
      final current = nodes[index];
      final origin = _selectedOrigins[key];
      Offset offset = origin! + delta;
      if (snapMovementToGrid == true && gridSize != null) {
        final size = current.size;
        final snappedX = _getClosestSnapPosition(offset.dx, size.width, gridSize.width);
        final snappedY = _getClosestSnapPosition(offset.dy, size.height, gridSize.height);
        offset = Offset(snappedX, snappedY);
      }

      current.update(offset: offset);
    }
    refresh();
  }

  Offset _getOffset() {
    final matrix = transform.value.clone();
    matrix.invert();
    final result = matrix.getTranslation();
    return Offset(result.x, result.y);
  }

  Rect _getRect(BoxConstraints constraints) {
    final offset = _getOffset();
    final scale = matrix.getMaxScaleOnAxis();
    final size = constraints.biggest;
    return offset & size / scale;
  }

  List<Node> _getNodes(BoxConstraints constraints) {
    if (widget.drawVisibleOnly) {
      final nodes = <Node>[];
      final viewport = _getRect(constraints);
      for (final node in widget.nodes) {
        if (node.rect.overlaps(viewport)) {
          nodes.add(node);
        }
      }
      return nodes;
    }
    return widget.nodes;
  }

  Rect _axisAlignedBoundingBox(Quad quad) {
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

  Widget _buildBackground(BuildContext context, Quad quad) {
    final viewport = _axisAlignedBoundingBox(quad);
    if (widget.backgroundBuilder != null) {
      return widget.backgroundBuilder!(context, viewport);
    }
    return GridBackground(
      cellWidth: widget.gridSize.width,
      cellHeight: widget.gridSize.height,
      viewport: viewport,
    );
  }

  Offset _toLocal(Offset global) {
    return transform.toScene(global);
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: focusNode,
      onKeyEvent: (event) {
        if (event is KeyDownEvent) {
          _handleCombinationKeyDownEvent(event);
          _handleArrowKeyDownEvent(event);
        }
        if (event is KeyUpEvent) {
          _handleCombinationKeyUpEvent(event);
        }
      },
      child: Listener(
        onPointerDown: (details) {
          final localPosition = _toLocal(details.localPosition);
          mouseDown = true;
          _checkSelection(localPosition);
          if (spacePressed) return;
          if (shiftPressed && !resizing || selection.isEmpty) {
            marqueeStart = localPosition;
            marqueeEnd = localPosition;
          }
        },
        onPointerUp: (_) {
          mouseDown = false;
          if (marqueeStart != null && marqueeEnd != null) {
            _checkMarqueeSelection();
          }
          marqueeStart = null;
          marqueeEnd = null;
        },
        onPointerCancel: (_) {
          mouseDown = false;
        },
        onPointerHover: (details) {
          mousePosition = _toLocal(details.localPosition);
          _checkSelection(mousePosition, true);
        },
        onPointerMove: (details) {
          if (marqueeStart != null && marqueeEnd != null) {
            marqueeEnd = _toLocal(details.localPosition);
            _checkMarqueeSelection(true);
          }
        },
        child: LayoutBuilder(
          builder: (context, constraints) {
            return InteractiveViewer.builder(
              transformationController: transform,
              panEnabled: canvasMoveEnabled,
              scaleEnabled: canvasMoveEnabled,
              onInteractionStart: (details) {
                mousePosition = _toLocal(details.focalPoint);
                mouseDragStart = mousePosition;
              },
              onInteractionUpdate: (details) {
                if (!mouseDown) {
                  scale = scale * details.scale;
                } else if (spacePressed) {
                  pan(details.focalPointDelta / scale);
                } else if (selection.isNotEmpty && !shiftPressed && !resizing) {
                  _dragSelection(_toLocal(details.focalPoint), gridSize: widget.gridSize);
                }
                mousePosition = _toLocal(details.focalPoint);
              },
              onInteractionEnd: (_) => mouseDragStart = null,
              minScale: minScale,
              maxScale: maxScale,
              boundaryMargin: const EdgeInsets.all(double.infinity),
              builder: (context, quad) {
                final nodes = _getNodes(constraints);
                return SizedBox.fromSize(
                  size: _getMaxSize().size,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      if (showGrid)
                        Positioned.fill(
                          child: _buildBackground(context, quad),
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
                                      isSelected: _isSelected(e.key),
                                      isHovered: _isHovered(e.key),
                                    ),
                                  ))
                              .toList(),
                        ),
                      ),
                      if (marqueeStart != null && marqueeEnd != null) ...[
                        Positioned.fill(
                          child: Marquee(
                            start: marqueeStart!,
                            end: marqueeEnd!,
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

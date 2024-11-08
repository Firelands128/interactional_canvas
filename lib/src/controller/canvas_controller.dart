import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

import '../model/graph.dart';
import '../model/node.dart';
import '../utils/utils.dart';

typedef NodeFormatter = void Function(Node);

/// A controller for the [InteractionalCanvas].
class CanvasController extends ChangeNotifier implements Graph {
  CanvasController({
    List<Node> nodes = const [],
    this.keepRatio = false,
    this.showGrid = true,
    this.snapMovementToGrid = true,
    this.snapResizeToGrid = true,
    this.onSelect,
    this.onDeselect,
  }) {
    if (nodes.isNotEmpty) {
      this.nodes.addAll(nodes);
    }
  }

  @override
  final List<Node> nodes = [];
  bool keepRatio;
  bool showGrid;
  bool snapMovementToGrid;
  bool snapResizeToGrid;
  final ValueChanged<List<Node>>? onSelect;
  final ValueChanged<List<Node>>? onDeselect;

  double minScale = 0.4;
  double maxScale = 4;
  final focusNode = FocusNode();

  final Set<Key> _selected = {};
  final Set<Key> _hovered = {};
  final Map<Key, Offset> _selectedOrigins = {};

  List<Node> get selection => nodes.where((e) => _selected.contains(e.key)).toList();

  List<Node> get hovered => nodes.where((e) => _hovered.contains(e.key)).toList();

  List<Node> getNodeList(Set<Key> keys) => nodes.where((e) => keys.contains(e.key)).toList();

  void _cacheSelectedOrigins() {
    _selectedOrigins.clear();
    for (final key in _selected) {
      final index = nodes.indexWhere((e) => e.key == key);
      if (index == -1) return;
      final current = nodes[index];
      _selectedOrigins[key] = current.offset;
    }
  }

  late final transform = TransformationController();

  Matrix4 get matrix => transform.value;
  Offset mousePosition = Offset.zero;
  Offset? mouseDragStart;
  Offset? marqueeStart, marqueeEnd;

  void _formatAll() {
    for (Node node in nodes) {
      _formatter!(node);
    }
  }

  bool _formatterHasChanged = false;
  NodeFormatter? _formatter;

  set formatter(NodeFormatter value) {
    _formatterHasChanged = _formatter != value;

    if (_formatterHasChanged == false) return;

    _formatter = value;
    _formatAll();
    refreshCanvas();
  }

  bool _mouseDown = false;

  bool get mouseDown => _mouseDown;

  set mouseDown(bool value) {
    if (value == _mouseDown) return;
    _mouseDown = value;
  }

  bool _shiftPressed = false;

  bool get shiftPressed => _shiftPressed;

  set shiftPressed(bool value) {
    if (value == _shiftPressed) return;
    _shiftPressed = value;
  }

  bool _spacePressed = false;

  bool get spacePressed => _spacePressed;

  set spacePressed(bool value) {
    if (value == _spacePressed) return;
    _spacePressed = value;
  }

  bool _controlPressed = false;

  bool get controlPressed => _controlPressed;

  set controlPressed(bool value) {
    if (value == _controlPressed) return;
    _controlPressed = value;
  }

  bool _metaPressed = false;

  bool get metaPressed => _metaPressed;

  set metaPressed(bool value) {
    if (value == _metaPressed) return;
    _metaPressed = value;
  }

  double _scale = 1;

  double get scale => _scale;

  set scale(double value) {
    if (value == _scale) return;
    _scale = value;
  }

  void refreshCanvas() {
    notifyListeners();
  }

  double getScale() {
    final matrix = transform.value;
    final scaleX = matrix.getMaxScaleOnAxis();
    return scaleX;
  }

  Rect getMaxSize() {
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

  bool isSelected(LocalKey key) => _selected.contains(key);

  bool isHovered(LocalKey key) => _hovered.contains(key);

  bool get hasSelection => _selected.isNotEmpty;

  bool get canvasMoveEnabled => !mouseDown;

  Offset toLocal(Offset global) {
    return transform.toScene(global);
  }

  void checkSelection(Offset localPosition, [bool hover = false]) {
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
        setSelection({selection.last, ..._selected.toSet()}, hover);
      } else {
        setSelection({selection.last}, hover);
      }
    } else {
      if (!shiftPressed) deselectAll(hover);
    }
  }

  void checkMarqueeSelection([bool hover = false]) {
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
        setSelection(selection.union(_selected.toSet()), hover);
      } else {
        setSelection(selection, hover);
      }
    } else {
      deselectAll(hover);
    }
  }

  Node? getNode(LocalKey? key) {
    if (key == null) return null;
    return nodes.firstWhereOrNull((e) => e.key == key);
  }

  void moveSelection(Offset delta) {
    for (final key in _selected) {
      final index = nodes.indexWhere((e) => e.key == key);
      if (index == -1) continue;
      final current = nodes[index];
      final origin = current.offset;
      Offset offset = origin + delta;
      current.update(offset: offset);
      if (_formatter != null) {
        _formatter!(current);
      }
    }
    refreshCanvas();
  }

  void dragSelection(Offset position, {Size? gridSize}) {
    final delta = mouseDragStart != null ? position - mouseDragStart! : position;
    for (final key in _selected) {
      final index = nodes.indexWhere((e) => e.key == key);
      if (index == -1) continue;
      final current = nodes[index];
      if (current.resizing) continue;
      final origin = _selectedOrigins[key];
      Offset offset = origin! + delta;
      if (snapMovementToGrid == true && gridSize != null) {
        final size = current.size;
        final snappedX = _getClosestSnapPosition(offset.dx, size.width, gridSize.width);
        final snappedY = _getClosestSnapPosition(offset.dy, size.height, gridSize.height);
        offset = Offset(snappedX, snappedY);
      }

      current.update(offset: offset);
      if (_formatter != null) {
        _formatter!(current);
      }
    }
    refreshCanvas();
  }

  void setSelection(Set<Key> keys, [bool hover = false]) {
    if (hover) {
      _hovered.clear();
      _hovered.addAll(keys);
    } else {
      final toDeselect = _selected.difference(keys);
      final toSelect = keys.difference(_selected);
      _selected.removeAll(toDeselect);
      _selected.addAll(toSelect);
      if (onDeselect != null) onDeselect!(getNodeList(toDeselect));
      if (onSelect != null) onSelect!(getNodeList(toSelect));
      _cacheSelectedOrigins();
    }
    refreshCanvas();
  }

  void selectAll() {
    final toSelect = nodes.map((e) => e.key).toSet().difference(_selected);
    _selected.addAll(toSelect);
    if (onSelect != null) onSelect!(getNodeList(toSelect));
    _cacheSelectedOrigins();
    refreshCanvas();
  }

  void deselectAll([bool hover = false]) {
    if (hover) {
      _hovered.clear();
    } else {
      final toDeselect = Set<Key>.from(_selected);
      _selected.removeAll(toDeselect);
      if (onDeselect != null) onDeselect!(getNodeList(toDeselect));
      _selectedOrigins.clear();
    }
    refreshCanvas();
  }

  void add(Node child) {
    if (_formatter != null) {
      _formatter!(child);
    }
    nodes.add(child);
    refreshCanvas();
  }

  void addAll(List<Node> children) {
    if (_formatter != null) {
      for (var child in children) {
        _formatter!(child);
      }
    }
    nodes.addAll(children);
    refreshCanvas();
  }

  void update(Node child) {
    final idx = nodes.indexWhere((e) => e.key == child.key);
    nodes[idx] = child;
    if (_formatter != null) {
      _formatter!(child);
    }
    refreshCanvas();
  }

  void remove(Key key) {
    nodes.removeWhere((e) => e.key == key);
    _selected.remove(key);
    _selectedOrigins.remove(key);
    refreshCanvas();
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
      refreshCanvas();
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
    refreshCanvas();
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
      refreshCanvas();
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
    refreshCanvas();
  }

  void deleteSelection() {
    final selection = _selected.toList();
    for (final key in selection) {
      final index = nodes.indexWhere((e) => e.key == key);
      if (index == -1) continue;
      nodes.removeAt(index);
      _selectedOrigins.remove(key);
    }
    refreshCanvas();
  }

  void zoom(double delta) {
    final matrix = transform.value.clone();
    final local = mousePosition;
    matrix.translate(local.dx, local.dy);
    matrix.scale(delta, delta);
    matrix.translate(-local.dx, -local.dy);
    transform.value = matrix;
    refreshCanvas();
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
    refreshCanvas();
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

  Offset getOffset() {
    final matrix = transform.value.clone();
    matrix.invert();
    final result = matrix.getTranslation();
    return Offset(result.x, result.y);
  }

  Rect getRect(BoxConstraints constraints) {
    final offset = getOffset();
    final scale = matrix.getMaxScaleOnAxis();
    final size = constraints.biggest;
    return offset & size / scale;
  }

  void toggleKeepRatio() {
    final newKeepRatio = !keepRatio;
    keepRatio = newKeepRatio;
    refreshCanvas();
  }

  void toggleShowGrid() {
    final newShowGridValue = !showGrid;
    showGrid = newShowGridValue;
    refreshCanvas();
  }

  void toggleSnapToGrid() {
    final newSnapValue = !snapMovementToGrid;
    snapMovementToGrid = newSnapValue;
    snapResizeToGrid = newSnapValue;
    refreshCanvas();
  }

  double _getClosestSnapPosition(double rawEdge, double nodeLength, double gridEdge) {
    final snapAtStartPos = adjustEdgeToGrid(rawEdge, gridEdge);
    final snapAtStartDelta = (snapAtStartPos - rawEdge).abs();
    final snapAtEndPos = adjustEdgeToGrid(rawEdge + nodeLength, gridEdge) - nodeLength;
    final snapAtEndDelta = (snapAtEndPos - rawEdge).abs();
    return snapAtEndDelta < snapAtStartDelta ? snapAtEndPos : snapAtStartPos;
  }
}

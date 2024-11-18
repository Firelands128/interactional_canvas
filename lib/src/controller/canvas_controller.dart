import 'package:flutter/cupertino.dart';

import '../model/node.dart';

class CanvasController extends ChangeNotifier {
  FocusNode? focusNode;
  ValueGetter<bool>? isKeepRatio;
  ValueGetter<bool>? isShowGrid;
  ValueGetter<bool>? isSnapMovementToGrid;
  ValueGetter<bool>? isSnapResizeToGrid;
  ValueGetter<double>? getScale;
  ValueSetter<bool>? setResizing;
  ValueGetter<bool>? isMouseDown;
  ValueGetter<bool>? isShiftPressed;
  ValueGetter<Offset>? getMousePosition;
  ValueGetter<List<Node>>? getNodes;
  ValueGetter<List<Node>>? getSelection;

  bool get keepRatio => isKeepRatio?.call() ?? false;

  bool get showGrid => isShowGrid?.call() ?? true;

  bool get snapMovementToGrid => isSnapMovementToGrid?.call() ?? true;

  bool get snapResizeToGrid => isSnapResizeToGrid?.call() ?? true;

  double get scale => getScale?.call() ?? 1;

  set resizing(bool value) => setResizing?.call(value);

  bool get mouseDown => isMouseDown?.call() ?? false;

  bool get shiftPressed => isShiftPressed?.call() ?? false;

  Offset get mousePosition => getMousePosition?.call() ?? const Offset(0, 0);

  List<Node> get nodes => getNodes?.call() ?? [];

  List<Node> get selection => getSelection?.call() ?? [];

  late bool Function(LocalKey key) isSelected;
  late bool Function(LocalKey key) isHovered;
  late VoidCallback refresh;
  late ValueChanged<Node> add;
  late ValueChanged<Node> update;
  late VoidCallback zoomIn;
  late VoidCallback zoomOut;
  late VoidCallback zoomReset;
  late VoidCallback panUp;
  late VoidCallback panDown;
  late VoidCallback panLeft;
  late VoidCallback panRight;
  late VoidCallback selectAll;
  late VoidCallback deselectAll;
  late VoidCallback bringForward;
  late VoidCallback bringToFront;
  late VoidCallback sendBackward;
  late VoidCallback sendToBack;
  late VoidCallback deleteSelection;
  late VoidCallback toggleKeepRatio;
  late VoidCallback toggleShowGrid;
  late VoidCallback toggleSnapToGrid;

  void notify() {
    notifyListeners();
  }
}

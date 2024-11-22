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

  bool Function(LocalKey key)? isSelected;
  bool Function(LocalKey key)? isHovered;
  VoidCallback? refresh;
  ValueChanged<Node>? add;
  ValueChanged<Node>? update;
  VoidCallback? zoomIn;
  VoidCallback? zoomOut;
  VoidCallback? zoomReset;
  VoidCallback? panUp;
  VoidCallback? panDown;
  VoidCallback? panLeft;
  VoidCallback? panRight;
  VoidCallback? selectAll;
  VoidCallback? deselectAll;
  VoidCallback? bringForward;
  VoidCallback? bringToFront;
  VoidCallback? sendBackward;
  VoidCallback? sendToBack;
  VoidCallback? deleteSelection;
  VoidCallback? toggleKeepRatio;
  VoidCallback? toggleShowGrid;
  VoidCallback? toggleSnapToGrid;

  void notify() {
    notifyListeners();
  }
}

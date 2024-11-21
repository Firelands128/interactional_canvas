## 0.2.1

Add some callback function of ```InteractionalCanvas```.

Expose ```isSelected``` and ```isHovered``` method through ```CanvasController```.

Avoid updating ```mousePosition``` in ```InteractiveViewer```.

Use ```localFocalPoint``` instead of ```focalPoint``` in ```InteractiveViewer```.

Update pointer ```Listener``` callback function to enable multiple selection dragging.

## 0.2.0

Reconstruct project.

Move all data and function from ```CanvasController``` to ```InteractionalCanvas```.

## 0.1.0

Add ```onSelect```, ```onDeselect```, ```onHover```, ```onLeave``` callback function in ```CanvasController```.

Add ```child``` parameter of ```update``` method of ```Node```.

Holding ```shift``` to union selection when marquee selection.

Optimize example app.

## 0.0.7

Use transparency material type, instead of background color in theme.

## 0.0.6

Fix bug in ```CanvasController```.

## 0.0.5

Add "keepRatio" state in ```CanvasController```, and simplify code.

Update resizing default mode.

Update example app.

## 0.0.4

Extract ```ResizeMode``` enum.

Expose "resizeMode" property to ```InteractionalCanvas``` instead of ```Node```.

Use different "minimumNodeSize" according to ```ResizeMode```.

## 0.0.3

Add "addAll" method of CanvasController.

## 0.0.2

Update repository url.

## 0.0.1

Initial release.

# Interactional Canvas

[![pub package](https://img.shields.io/pub/v/interactional_canvas.svg)](https://pub.dev/packages/interactional_canvas)

A Flutter package that provides interactional canvas, which can add nodes and manipulating nodes in a InteractiveViewer.

## Usage

To use this package, add `interactional_canvas` as a [dependency in your pubspec.yaml file](https://dart.dev/tools/pub/dependencies).

### Sample Usage

* You can now add a `InteractionalCanvas` widget to your widget tree.

```dart
class Demo extends StatefulWidget {
  const Demo({Key? key}) : super(key: key);

  static const title = 'amap_flutter_example';

  @override
  State<Demo> createState() => _DemoState();
}

class _DemoState extends State<Demo> {
  late CanvasController controller;
  
  @override
  void initState() {
    super.initState();
    controller = CanvasController();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(Demo.title),
      ),
      body: InteractionalCanvas(
        controller: controller,
      ),
    );
  }
}
```

See the `example` directory for a complete sample app.

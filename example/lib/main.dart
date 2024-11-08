import 'dart:math';

import 'package:flutter/material.dart';
import 'package:interactional_canvas/interactional_canvas.dart';
import 'package:random_color/random_color.dart';

import 'circle.dart';
import 'menus.dart';

void main() => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final CanvasController controller;
  final gridSize = const Size.square(50);

  @override
  void initState() {
    super.initState();
    // Generate random nodes
    final colors = RandomColor();
    final nodes = List.generate(100, (index) {
      return Node(
        key: UniqueKey(),
        label: 'Node $index',
        offset: Offset(
          Random().nextDouble() * 5000,
          Random().nextDouble() * 5000,
        ),
        size: Size.square(Random().nextDouble() * 200 + 100),
        child: Circle(color: colors.randomColor()),
      );
    });
    controller = CanvasController(
      nodes: nodes,
      onSelect: (selection) {
        for (final node in selection) {
          node.update(child: const Circle(color: Colors.blue));
        }
      },
      onDeselect: (selection) {
        for (final node in selection) {
          node.update(child: Circle(color: RandomColor().randomColor()));
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: ThemeData.light(useMaterial3: true),
      darkTheme: ThemeData.dark(useMaterial3: true),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Interactional Canvas Example'),
          centerTitle: false,
        ),
        body: Column(
          children: [
            Menus(controller: controller),
            Expanded(
              child: Stack(
                children: [
                  InteractionalCanvas(
                    drawVisibleOnly: true,
                    controller: controller,
                    gridSize: gridSize,
                  ),
                  const Positioned(
                    right: 10,
                    top: 10,
                    width: 300,
                    height: 300,
                    child: IgnorePointer(
                      child: Text(
                        "Tips:\n"
                        "1.Holding \"Space\" and dragging to move the viewport.\n"
                        "2.Holding \"Shift\" and resizing node to keep proportions.\n"
                        "3.Holding \"Shift\" to select multiple nodes.\n"
                        "4.Use arrow keys to move selected nodes.\n"
                        "5.Holding \"Shift\" and press arrow keys to quickly move selected nodes.",
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:interactional_canvas/interactional_canvas.dart';

class Circle extends StatefulWidget {
  const Circle({
    super.key,
    required this.color,
  });

  final Color color;

  @override
  State<Circle> createState() => _CircleState();
}

class _CircleState extends State<Circle> {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: NodePainter(
        brush: Paint()..color = widget.color,
        builder: (Paint brush, Canvas canvas, Rect rect) {
          final diameter = min(rect.width, rect.height);
          final radius = diameter / 2;
          canvas.drawCircle(rect.center, radius, brush);
        },
      ),
    );
  }
}

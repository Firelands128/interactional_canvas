import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:interactional_canvas/interactional_canvas.dart';

class Circle extends StatelessWidget {
  const Circle({
    super.key,
    required this.color,
  });

  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: NodePainter(
        brush: Paint()..color = color,
        builder: (Paint brush, Canvas canvas, Rect rect) {
          final diameter = min(rect.width, rect.height);
          final radius = diameter / 2;
          canvas.drawCircle(rect.center, radius, brush);
        },
      ),
    );
  }
}

import 'package:flutter/widgets.dart';
import 'package:interactional_canvas/interactional_canvas.dart';

import 'shape.dart';

class Rectangle extends StatelessWidget implements NodeShape {
  const Rectangle({
    super.key,
    required this.color,
  });

  final Color color;

  @override
  Rectangle update({Color? color}) {
    return Rectangle(color: color ?? this.color);
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: NodePainter(
        brush: Paint()..color = color,
        builder: (Paint brush, Canvas canvas, Rect rect) {
          canvas.drawRect(rect, brush);
        },
      ),
    );
  }
}

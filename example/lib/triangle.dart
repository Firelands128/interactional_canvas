import 'package:flutter/widgets.dart';
import 'package:interactional_canvas/interactional_canvas.dart';

import 'shape.dart';

class Triangle extends StatelessWidget implements NodeShape {
  const Triangle({
    super.key,
    required this.color,
  });

  final Color color;

  @override
  Triangle update({Color? color}) {
    return Triangle(color: color ?? this.color);
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: NodePainter(
        brush: Paint()..color = color,
        builder: (Paint brush, Canvas canvas, Rect rect) {
          final path = Path()
            ..moveTo(rect.left, rect.bottom)
            ..lineTo(rect.right, rect.bottom)
            ..lineTo(rect.center.dx, rect.top)
            ..close();
          canvas.drawPath(path, brush);
        },
      ),
    );
  }
}

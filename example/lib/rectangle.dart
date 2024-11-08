import 'package:flutter/widgets.dart';
import 'package:interactional_canvas/interactional_canvas.dart';

class Rectangle extends StatelessWidget {
  const Rectangle({
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
          canvas.drawRect(rect, brush);
        },
      ),
    );
  }
}

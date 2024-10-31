import 'package:flutter/widgets.dart';
import 'package:interactional_canvas/interactional_canvas.dart';

class Rectangle extends StatefulWidget {
  const Rectangle({
    super.key,
    required this.color,
  });

  final Color color;

  @override
  State<Rectangle> createState() => _RectangleState();
}

class _RectangleState extends State<Rectangle> {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: NodePainter(
        brush: Paint()..color = widget.color,
        builder: (Paint brush, Canvas canvas, Rect rect) {
          canvas.drawRect(rect, brush);
        },
      ),
    );
  }
}

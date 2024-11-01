import 'package:flutter/widgets.dart';
import 'package:interactional_canvas/interactional_canvas.dart';

class Triangle extends StatefulWidget {
  const Triangle({
    super.key,
    required this.color,
  });

  final Color color;

  @override
  State<Triangle> createState() => _TriangleState();
}

class _TriangleState extends State<Triangle> {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: NodePainter(
        brush: Paint()..color = widget.color,
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

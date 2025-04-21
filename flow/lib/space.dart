import 'package:flutter/material.dart';

class SpaceWidget extends LeafRenderObjectWidget {
  const SpaceWidget({super.key});

  @override
  RenderObject createRenderObject(BuildContext context) {
    return SpaceObject();
  }
}

class SpaceObject extends RenderBox {
  SpaceObject();

  @override
  bool get sizedByParent => true;

  @override
  Size computeDryLayout(covariant BoxConstraints constraints) {
    Size maxSize = const Size(4096, 4096);
    return constraints.constrain(maxSize);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    Paint greenPaint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.fill;
    context.canvas.drawRect(const Rect.fromLTWH(100, 100, 100, 100), greenPaint);
  }
}

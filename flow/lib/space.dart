import 'package:event/event.dart';
import 'package:flow/app_state.dart';
import 'package:flutter/material.dart';

class Space extends StatefulWidget {
  const Space({super.key});

  @override
  State<Space> createState() => _SpaceState();
}

class _SpaceState extends State<Space> {
  void invokeSetState(EventArgs? e) {
    setState(() {});
  }

  @override
  void initState() {
    super.initState();

    AppState.onNewImage.subscribe(invokeSetState);
  }

  @override
  void dispose() {
    AppState.onNewImage.unsubscribe(invokeSetState);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SpaceWidget();
  }
}

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
    if (AppState.image != null) {
      context.canvas.save();
      paintImage(
        canvas: context.canvas,
        rect: Rect.fromLTWH(100, 100, AppState.imageWidth, AppState.imageHeight),
        image: AppState.image!,
      );
    }

    context.canvas.restore();
  }
}

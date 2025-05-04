import 'package:event/event.dart';
import 'package:flow/app_state.dart';
import 'package:flow/bindings.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'dart:developer' as dev;

class Space extends StatefulWidget {
  const Space({super.key});

  @override
  State<Space> createState() => _SpaceState();
}

class _SpaceState extends State<Space> {
  double x = 0, dx = 0, y = 0, dy = 0;

  void invokeSetState(EventArgs? e) {
    setState(() {});
  }

  @override
  void initState() {
    super.initState();

    AppState.onNewImage.subscribe(invokeSetState);

    cLayerBindings.draw_background(0, 0, 0);
  }

  @override
  void dispose() {
    AppState.onNewImage.unsubscribe(invokeSetState);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (event) {
        if (event.buttons == kPrimaryMouseButton) {
          dx = event.position.dx;
          dy = event.position.dy;
        }
      },
      onPointerMove: (event) {
        if (event.buttons == kPrimaryMouseButton) {
          x += event.position.dx - dx;
          y += event.position.dy - dy;
          dx = event.position.dx;
          dy = event.position.dy;
          cLayerBindings.draw_background(0, x.floor(), y.floor()); // need thread
        }
      },
      behavior: HitTestBehavior.opaque,
      child: SpaceWidget(),
    );
  }
}

class SpaceWidget extends LeafRenderObjectWidget {
  const SpaceWidget({super.key});

  @override
  RenderObject createRenderObject(BuildContext context) {
    return SpaceObject();
  }

  @override
  void updateRenderObject(BuildContext context, SpaceObject renderObject) {
    renderObject.markNeedsPaint();
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
    context.canvas.save();
    if (AppState.painting.image != null) {
      paintImage(
        canvas: context.canvas,
        rect: Rect.fromLTWH(0, 0, AppState.painting.width!, AppState.painting.height!),
        image: AppState.painting.image!,
      );
    }

    context.canvas.restore();
  }
}

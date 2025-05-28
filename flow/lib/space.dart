import 'package:event/event.dart';
import 'package:flow/app_state.dart';
import 'package:flow/bindings.dart';
import 'package:flow/types.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'dart:developer' as dev;

class Space extends StatefulWidget {
  const Space({super.key});

  @override
  State<Space> createState() => _SpaceState();
}

class _SpaceState extends State<Space> {
  final int margin = 100;
  final double minZoom = 0.1;
  final double maxZoom = 10;

  double x = 0, dx = 0, y = 0, dy = 0;
  double zoom = 1;

  Size _spaceSize = Size(0, 0);
  Size get spaceSize => _spaceSize;
  set spaceSize(Size size) {
    if (AppState.imageUpdateStatus != LengthyProcess.ongoing && (size.width != _spaceSize.width || size.height != _spaceSize.height)) {
      _spaceSize = size;
      AppState.imageUpdateStatus = LengthyProcess.ongoing;
      cLayerBindings.update_background_size(size.width.ceil() + margin, size.height.ceil() + margin, zoom, x.floor(), x.floor());
    }
  }

  void invokeSetState(EventArgs? e) {
    setState(() {});
  }

  @override
  void initState() {
    super.initState();

    AppState.onNewImage.subscribe(invokeSetState);

    cLayerBindings.draw_background(zoom, 0, 0);
  }

  @override
  void dispose() {
    AppState.onNewImage.unsubscribe(invokeSetState);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    spaceSize = MediaQuery.of(context).size;

    return GestureDetector(
      onScaleStart: (details) {
        dx = details.localFocalPoint.dx;
        dy = details.localFocalPoint.dy;
      },
      onScaleUpdate: (details) {
        if (details.scale == 1) {
          y += details.localFocalPoint.dy - dy;
          x += details.localFocalPoint.dx - dx;
          dx = details.localFocalPoint.dx;
          dy = details.localFocalPoint.dy;
        } else if (details.pointerCount == 2) {
          double newZoom = zoom * AppState.conversions.dampenZoom(details.scale);
          if (newZoom >= minZoom && newZoom <= maxZoom) {
            zoom = newZoom;
          }
        }

        if (AppState.imageUpdateStatus != LengthyProcess.ongoing) {
          AppState.imageUpdateStatus = LengthyProcess.ongoing;
          cLayerBindings.draw_background(zoom, x.floor(), y.floor());
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

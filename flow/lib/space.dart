import 'dart:async';
import 'dart:io';

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
  late Timer timer;

  final int margin = 100;
  final double minZoom = 0.1;
  final double maxZoom = 10;

  bool leftClickDown = false;

  double x = 0, dx = 0, y = 0, dy = 0;
  double zoom = 1;
  Offset hoverPosition = Offset.zero;

  Size _spaceSize = Size.zero;
  Size get spaceSize => _spaceSize;
  set spaceSize(Size size) {
    if (AppState.imageUpdateStatus != LengthyProcess.ongoing && (size.width != _spaceSize.width || size.height != _spaceSize.height)) {
      _spaceSize = size;
      AppState.imageUpdateStatus = LengthyProcess.ongoing;
      cLayerBindings.update_background_size(size.width.ceil() + margin, size.height.ceil() + margin, zoom, x.floor(), x.floor());
    }
  }

  Widget platformListener(Widget child, Size screenSize) {
    if (Platform.isWindows) {
      return Listener(
        onPointerHover: (event) {
          hoverPosition = event.localPosition;
          if (AppState.player.alive) {
            AppState.player.setSpeedAndAngle(hoverPosition);
          }
        },
        onPointerSignal: (event) {
          if (event is PointerScrollEvent) {
            double dampenedZoom = AppState.conversions.dampenZoom(event.scrollDelta.dy > 0 ? 0.75 : 1.5);
            double newZoom = zoom * dampenedZoom;
            if (newZoom >= minZoom && newZoom <= maxZoom) {
              Offset offset = event.localPosition * (newZoom - zoom);
              zoom = newZoom;
              x -= offset.dx;
              y -= offset.dy;
            }
            if (AppState.imageUpdateStatus != LengthyProcess.ongoing) {
              AppState.imageUpdateStatus = LengthyProcess.ongoing;
              cLayerBindings.draw_background(zoom, x.floor(), y.floor());
            }
          }
        },
        onPointerDown: (event) {
          if (event.buttons == 1) {
            leftClickDown = true;
            dx = event.localPosition.dx;
            dy = event.localPosition.dy;
          } else if (event.buttons == 2) {
            if (!AppState.player.alive) {
              AppState.player.initializePosition(event.localPosition);
              AppState.player.alive = true;
            }
          }
        },
        onPointerMove: (event) {
          if (event.buttons == 1 && leftClickDown) {
            x += event.localPosition.dx - dx;
            y += event.localPosition.dy - dy;
            dx = event.localPosition.dx;
            dy = event.localPosition.dy;
            if (AppState.imageUpdateStatus != LengthyProcess.ongoing) {
              AppState.imageUpdateStatus = LengthyProcess.ongoing;
              cLayerBindings.draw_background(zoom, x.floor(), y.floor());
            }
          }
        },
        onPointerUp: (event) {
          if (event.buttons == 1) {
            leftClickDown = false;
          }
        },
        behavior: HitTestBehavior.opaque,
        child: child,
      );
    } else {
      return GestureDetector(
        onScaleStart: (details) {
          dx = details.localFocalPoint.dx;
          dy = details.localFocalPoint.dy;
        },
        onScaleUpdate: (details) {
          if (details.scale == 1) {
            x += details.localFocalPoint.dx - dx;
            y += details.localFocalPoint.dy - dy;
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
        child: child,
      );
    }
  }

  void invokeSetState(EventArgs? e) {
    setState(() {});
  }

  @override
  void initState() {
    super.initState();

    timer = Timer.periodic(const Duration(milliseconds: 100), (Timer t) {
      if (AppState.player.alive) {
        AppState.player.updatePositionAndSpeed(hoverPosition);
        setState(() {});
      }
    });

    AppState.onNewImage.subscribe(invokeSetState);
    AppState.player.onPlayerStatusChanged.subscribe(invokeSetState);

    cLayerBindings.draw_background(zoom, 0, 0);
  }

  @override
  void dispose() {
    AppState.onNewImage.unsubscribe(invokeSetState);
    AppState.player.onPlayerStatusChanged.unsubscribe(invokeSetState);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    spaceSize = MediaQuery.of(context).size;

    return platformListener(SpaceWidget(), spaceSize);
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

  final Paint playerPaint = Paint()
    ..color = Colors.red
    ..style = PaintingStyle.fill;

  @override
  void paint(PaintingContext context, Offset offset) {
    context.canvas.save();
    if (AppState.painting.image != null) {
      paintImage(
        canvas: context.canvas,
        rect: Rect.fromLTWH(0, 0, AppState.painting.width!, AppState.painting.height!),
        image: AppState.painting.image!,
      );

      if (AppState.player.alive) {
        context.canvas.drawCircle(AppState.player.position, 20, playerPaint);
      }
    }

    context.canvas.restore();
  }
}

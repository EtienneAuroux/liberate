import 'dart:async';
import 'dart:io';

import 'package:event/event.dart';
import 'package:flow/app_state.dart';
import 'package:flow/bindings.dart';
import 'package:flow/calculations.dart';
import 'package:flow/design.dart';
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
            AppState.player.setAngle(hoverPosition);
          }
        },
        onPointerSignal: (event) {
          if (event is PointerScrollEvent) {
            double dampenedZoom = Calculations.dampenZoom(event.scrollDelta.dy > 0 ? 0.75 : 1.5);
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
              AppState.initializeGameState(event.localPosition, Offset(screenSize.width, screenSize.height));
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
            double newZoom = zoom * Calculations.dampenZoom(details.scale);
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

    timer = Timer.periodic(const Duration(milliseconds: AppState.updateRate), (Timer t) {
      if (AppState.player.alive) {
        AppState.updateGameState();
        AppState.player.updatePositionAndSpeed(hoverPosition, AppState.bounds, AppState.blocks);
        setState(() {});
      }
    });

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
    AppState.bounds = Offset(spaceSize.width, spaceSize.height);

    // ignore: prefer_const_constructors
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

  final Paint targetPaint = Paint()
    ..color = Colors.green
    ..style = PaintingStyle.fill;

  final Paint enemyPaint = Paint()
    ..color = Colors.grey
    ..style = PaintingStyle.fill;

  final Paint blockPaint = Paint()
    ..color = Colors.blue
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
        context.canvas.drawCircle(AppState.player.position, AppState.player.hitBoxRadius, playerPaint);
        for (Target target in AppState.targets) {
          context.canvas.drawCircle(target.position, target.hitBoxRadius, targetPaint);
        }
        for (Enemy enemy in AppState.enemies) {
          context.canvas.drawCircle(enemy.position, enemy.hitBoxRadius, enemyPaint);
        }
        for (Block block in AppState.blocks) {
          context.canvas.drawRect(Rect.fromLTWH(block.position.dx, block.position.dy, block.width, block.height), blockPaint);
        }
      }

      TextSpan pointCounterSpan = TextSpan(
        text: AppState.player.points.toString().padLeft(4, '0'),
        style: Design.pointCounterStyle,
      );
      TextPainter pointCounterPainter = TextPainter(
        text: pointCounterSpan,
        textAlign: TextAlign.start,
        textDirection: TextDirection.ltr,
      );
      pointCounterPainter.layout();
      pointCounterPainter.paint(context.canvas, Offset(AppState.bounds.dx - 120, 20));
    }

    context.canvas.restore();
  }
}

import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:event/event.dart';
import 'package:flow/app_state.dart';
import 'package:flow/bindings.dart';
import 'package:flow/calculations.dart';
import 'package:flow/constants.dart';
import 'package:flow/design.dart';
import 'package:flow/types.dart';
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
        onPointerDown: (event) {
          if (event.buttons == 1) {
            if (AppState.shiftTime >= AppState.shiftCooldown) {
              AppState.boardShifting = true;
              AppState.shiftTime = 0;
            }
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
          if (event.buttons == 1 && AppState.boardShifting) {
            x += event.localPosition.dx - dx;
            y += event.localPosition.dy - dy;
            AppState.shift = Offset(event.localPosition.dx - dx, event.localPosition.dy - dy);
            AppState.shiftPointer = event.localPosition;
            dx = event.localPosition.dx;
            dy = event.localPosition.dy;
            if (AppState.imageUpdateStatus != LengthyProcess.ongoing) {
              AppState.imageUpdateStatus = LengthyProcess.ongoing;
              cLayerBindings.draw_background(zoom, x.floor(), y.floor());
            }
          }
        },
        onPointerUp: (event) {
          if (event.buttons == 0) {
            AppState.boardShifting = false;
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
        context.canvas.drawCircle(AppState.player.position, AppState.player.hitBoxRadius, Design.playerPaint);
        for (Target target in AppState.targets) {
          context.canvas.drawCircle(target.centerPosition, target.hitBoxRadius, Design.targetPaint);
        }
        for (Enemy enemy in AppState.enemies) {
          context.canvas.drawCircle(enemy.centerPosition, enemy.hitBoxRadius, Design.enemyPaint);
          context.canvas.drawVertices(
            Vertices(
              VertexMode.triangles,
              [
                enemy.centerPosition +
                    Offset(
                      enemy.hitBoxRadius * cos(enemy.angle),
                      enemy.hitBoxRadius * sin(enemy.angle),
                    ),
                enemy.centerPosition +
                    Offset(
                      (enemy.hitBoxRadius * 0.9) * cos(enemy.angle + 15),
                      (enemy.hitBoxRadius * 0.9) * sin(enemy.angle + 15),
                    ),
                enemy.centerPosition +
                    Offset(
                      (enemy.hitBoxRadius * 0.9) * cos(enemy.angle - 15),
                      (enemy.hitBoxRadius * 0.9) * sin(enemy.angle - 15),
                    ),
              ],
            ),
            BlendMode.color,
            Paint()..color = Colors.blueGrey,
          );
        }
        for (Block block in AppState.blocks) {
          if (block is BouncingBlock) {
            context.canvas.drawRect(Rect.fromLTWH(block.position.dx, block.position.dy, block.width, block.height), Design.bouncingBLockPaint);
          } else {
            context.canvas.drawRect(Rect.fromLTWH(block.position.dx, block.position.dy, block.width, block.height), Design.blockPaint);
          }
        }

        for (Laser laser in AppState.lasers) {
          context.canvas.drawLine(
            laser.startPosition,
            laser.endPosition,
            Paint()
              ..color = Colors.purple
              ..style = PaintingStyle.fill
              ..strokeWidth = laser.thickness,
          );
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
      pointCounterPainter.paint(
        context.canvas,
        Offset(
          AppState.bounds.dx - pointCounterPainter.width - UIConstants.textHorizontalMargin,
          UIConstants.textVerticalMargin,
        ),
      );

      if (AppState.player.alive) {
        TextSpan shiftSpan = TextSpan(
          text: AppState.boardShifting
              ? 'POWER ON'
              : AppState.shiftTime >= AppState.shiftCooldown
                  ? 'READY'
                  : 'POWER IN ${10 - (AppState.shiftTime / 1000).floor()}',
          style: Design.shiftStyle,
        );
        TextPainter shiftPainter = TextPainter(
          text: shiftSpan,
          textAlign: TextAlign.start,
          textDirection: TextDirection.ltr,
        );
        shiftPainter.layout();
        shiftPainter.paint(
          context.canvas,
          Offset(
            AppState.bounds.dx - UIConstants.textHorizontalMargin - shiftPainter.width,
            AppState.bounds.dy - UIConstants.textVerticalMargin - shiftPainter.height,
          ),
        );
      }

      if (!AppState.player.alive) {
        TextSpan announcementSpan;
        if (AppState.gameTime == 0) {
          announcementSpan = const TextSpan(text: UIConstants.gameStart, style: Design.announcementStyle);
        } else if (AppState.player.points < AppState.winningCondition) {
          announcementSpan = const TextSpan(text: UIConstants.gameOver, style: Design.announcementStyle);
        } else {
          announcementSpan = TextSpan(children: [
            const TextSpan(text: UIConstants.gameWon),
            TextSpan(text: Calculations.millisecondsToTime(AppState.gameTime)),
          ], style: Design.announcementStyle);
        }
        TextPainter announcementPainter = TextPainter(
          text: announcementSpan,
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr,
        );
        announcementPainter.layout();
        announcementPainter.paint(
          context.canvas,
          Offset(size.width - announcementPainter.width, size.height - announcementPainter.height) * 0.5,
        );
      }
    }

    context.canvas.restore();
  }
}

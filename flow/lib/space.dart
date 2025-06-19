import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:event/event.dart';
import 'package:flow/app_state.dart';
import 'package:flow/calculations.dart';
import 'package:flow/ui_constants.dart';
import 'package:flow/types.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'dart:developer' as dev;

import 'package:flutter/services.dart';

class Space extends StatefulWidget {
  const Space({super.key});

  @override
  State<Space> createState() => _SpaceState();
}

class _SpaceState extends State<Space> {
  late Timer timer;

  // focus node to capture keyboard events
  final FocusNode _focusNode = FocusNode();

  final int margin = 100;
  final double minZoom = 0.1;
  final double maxZoom = 10;

  double x = 0, dx = 0, y = 0, dy = 0;
  Offset hoverPosition = Offset.zero;

  Size _spaceSize = Size.zero;
  Size get spaceSize => _spaceSize;
  set spaceSize(Size size) {
    if (AppState.imageUpdateStatus != LengthyProcess.ongoing && (size.width != _spaceSize.width || size.height != _spaceSize.height)) {
      _spaceSize = size;
      AppState.imageUpdateStatus = LengthyProcess.ongoing;
      AppState.updateBackgroundSize(size.width.ceil() + margin, size.height.ceil() + margin, timer.tick, x.floor(), x.floor());
    }
  }

  Widget platformListener(Widget child, Size screenSize) {
    if (Platform.isWindows) {
      return KeyboardListener(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: (KeyEvent event) {
          if (event is KeyDownEvent) {
            if (event.logicalKey == LogicalKeyboardKey.digit1) {
              AppState.changeBackgroundConfiguration(BackgroundConfiguration.grid);
            } else if (event.logicalKey == LogicalKeyboardKey.digit2) {
              AppState.changeBackgroundConfiguration(BackgroundConfiguration.wave);
            }
          }
        },
        child: Listener(
          onPointerHover: (event) {
            hoverPosition = event.localPosition;
            if (AppState.player.alive) {
              AppState.player.setAngle(hoverPosition);
            }
          },
          onPointerSignal: (event) {
            if (event is PointerScrollEvent) {
              if (event.scrollDelta.dy > 0) {
                AppState.updateBackgroundColor(5);
              } else if (event.scrollDelta.dy < 0) {
                AppState.updateBackgroundColor(-5);
              }
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
                AppState.initializeGameState(event.localPosition);
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
            }
          },
          onPointerUp: (event) {
            if (event.buttons == 0) {
              AppState.boardShifting = false;
            }
          },
          behavior: HitTestBehavior.opaque,
          child: child,
        ),
      );
    } else {
      return const Placeholder();
      // GestureDetector(
      // onScaleStart: (details) {
      //   dx = details.localFocalPoint.dx;
      //   dy = details.localFocalPoint.dy;
      // },
      // onScaleUpdate: (details) {
      //   if (details.scale == 1) {
      //     x += details.localFocalPoint.dx - dx;
      //     y += details.localFocalPoint.dy - dy;
      //     dx = details.localFocalPoint.dx;
      //     dy = details.localFocalPoint.dy;
      //   }

      //   if (AppState.imageUpdateStatus != LengthyProcess.ongoing) {
      //     AppState.imageUpdateStatus = LengthyProcess.ongoing;
      //     cLayerBindings.draw_background(timer.tick, x.floor(), y.floor());
      //   }
      // },
      // behavior: HitTestBehavior.opaque,
      // child: child,
      // );
    }
  }

  void invokeSetState(EventArgs? e) {
    setState(() {});
  }

  @override
  void initState() {
    super.initState();

    timer = Timer.periodic(const Duration(milliseconds: AppState.updateRate), (Timer t) {
      AppState.updateBackground(timer.tick, 0, 0);
      if (AppState.player.alive) {
        AppState.updateGameState();
        AppState.player.updatePositionAndSpeed(hoverPosition, AppState.bounds, AppState.blocks);
        setState(() {});
      }
    });

    AppState.onNewImage.subscribe(invokeSetState);
  }

  @override
  void dispose() {
    AppState.onNewImage.unsubscribe(invokeSetState);

    _focusNode.dispose();

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
        // Draw player
        context.canvas.drawCircle(AppState.player.centerPosition, AppState.player.hitBoxRadius, UIConstants.playerPaint);
        context.canvas.drawVertices(
          Vertices(
            VertexMode.triangles,
            [
              AppState.player.centerPosition +
                  Offset(
                    AppState.player.hitBoxRadius * cos(AppState.player.angle),
                    AppState.player.hitBoxRadius * sin(AppState.player.angle),
                  ),
              AppState.player.centerPosition +
                  Offset(
                    (AppState.player.hitBoxRadius * 0.9) * cos(AppState.player.angle + 15),
                    (AppState.player.hitBoxRadius * 0.9) * sin(AppState.player.angle + 15),
                  ),
              AppState.player.centerPosition +
                  Offset(
                    (AppState.player.hitBoxRadius * 0.9) * cos(AppState.player.angle - 15),
                    (AppState.player.hitBoxRadius * 0.9) * sin(AppState.player.angle - 15),
                  ),
            ],
          ),
          BlendMode.color,
          UIConstants.playerArrowPaint,
        );

        // Draw targets
        for (Target target in AppState.targets) {
          context.canvas.drawCircle(target.centerPosition, target.hitBoxRadius, UIConstants.targetPaint);
          context.canvas.drawRect(
            Rect.fromCenter(
              center: target.centerPosition,
              width: target.hitBoxRadius * 0.75,
              height: target.hitBoxRadius * 0.75,
            ),
            UIConstants.targetCorePaint,
          );
        }

        // Draw enemies
        for (Enemy enemy in AppState.enemies) {
          context.canvas.drawCircle(enemy.centerPosition, enemy.hitBoxRadius, UIConstants.enemyPaint);
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
            UIConstants.enemyArrowPaint,
          );
        }

        // Draw blocks
        for (Block block in AppState.blocks) {
          context.canvas.drawRect(Rect.fromLTWH(block.position.dx, block.position.dy, block.width, block.height), UIConstants.blockPaint);
          if (block is BouncingBlock) {
            context.canvas.drawRect(
              Rect.fromLTWH(
                block.position.dx + UIConstants.bouncingBlockBorderPaint.strokeWidth / 2,
                block.position.dy + UIConstants.bouncingBlockBorderPaint.strokeWidth / 2,
                block.width - UIConstants.bouncingBlockBorderPaint.strokeWidth,
                block.height - UIConstants.bouncingBlockBorderPaint.strokeWidth,
              ),
              UIConstants.bouncingBlockBorderPaint,
            );
          } else {
            context.canvas.drawRect(
              Rect.fromLTWH(
                block.position.dx + UIConstants.blockBorderPaint.strokeWidth / 2,
                block.position.dy + UIConstants.blockBorderPaint.strokeWidth / 2,
                block.width - UIConstants.blockBorderPaint.strokeWidth,
                block.height - UIConstants.blockBorderPaint.strokeWidth,
              ),
              UIConstants.blockBorderPaint,
            );
          }
        }

        // Draw lasers
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
        style: UIConstants.pointCounterStyle,
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
              ? UIConstants.powerOn
              : AppState.shiftTime >= AppState.shiftCooldown
                  ? UIConstants.powerReady
                  : '${UIConstants.powerIn} ${10 - (AppState.shiftTime / 1000).floor()}',
          style: UIConstants.shiftStyle,
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
          announcementSpan = const TextSpan(children: [
            TextSpan(text: UIConstants.gameStart, style: UIConstants.announcementStyle),
            TextSpan(text: UIConstants.gameStartHint, style: UIConstants.subAnnouncementStyle)
          ]);
        } else if (AppState.player.points < AppState.winningCondition) {
          announcementSpan = const TextSpan(children: [
            TextSpan(text: UIConstants.gameOver, style: UIConstants.announcementStyle),
            TextSpan(text: UIConstants.gameOverRightClick, style: UIConstants.subAnnouncementStyle),
            TextSpan(text: UIConstants.gameOverLeftClick, style: UIConstants.subAnnouncementStyle),
            TextSpan(text: UIConstants.gameOverWheel, style: UIConstants.subAnnouncementStyle),
          ]);
        } else {
          announcementSpan = TextSpan(children: [
            const TextSpan(text: UIConstants.gameWon, style: UIConstants.announcementStyle),
            TextSpan(text: Calculations.millisecondsToTime(AppState.gameTime), style: UIConstants.subAnnouncementStyle),
          ]);
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

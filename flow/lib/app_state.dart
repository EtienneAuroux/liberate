import 'dart:async';
import 'dart:ffi';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:ui';

import 'package:event/event.dart';
import 'package:flow/bindings.dart';
import 'package:flow/calculations.dart';

import 'dart:developer' as dev;

import 'package:flow/types.dart';

class AppState {
  // SPACE RELATED OBJECTS //
  static Painting painting = Painting();

  static Event onNewImage = Event();

  static LengthyProcess imageUpdateStatus = LengthyProcess.unknown;

  static void initialize() {
    ui.Size size = ui.PlatformDispatcher.instance.views.first.physicalSize;
    double pixelRatio = ui.PlatformDispatcher.instance.views.first.devicePixelRatio;

    int maxWidth = max((size.width / pixelRatio).ceil(), 3500);
    int maxHeight = max((size.height / pixelRatio).ceil(), 2000);

    cLayerBindings.initialize(Pointer.fromFunction<FuncPtrNewFrame>(_onNewFrame), maxWidth, maxHeight);
  }

  static void _onNewFrame(int width, int height, int dataSize, Pointer<Void> data) {
    FrameEvent frameEvent = FrameEvent(width, height, data, dataSize);
    _handleNewFrame(frameEvent);
  }

  static Future<void> _handleNewFrame(FrameEvent? frame) async {
    if (frame == null) {
      imageUpdateStatus = LengthyProcess.failed;
      return;
    }

    Uint8List dataAsList = frame.data.cast<Uint8>().asTypedList(frame.dataSize);

    Completer completer = Completer();
    ui.decodeImageFromPixels(dataAsList, frame.width, frame.height, ui.PixelFormat.rgba8888, (ui.Image result) {
      completer.complete(result);
    });

    painting.image = await completer.future;
    painting.height = frame.height.toDouble();
    painting.width = frame.width.toDouble();
    onNewImage.broadcast();

    imageUpdateStatus = LengthyProcess.done;
  }

  // GAME RELATED OBJECTS //
  /// The player defined by its position, direction, speed, radius and alive status.
  static Player player = Player();

  /// The rate at which the game state is updated in [ms].
  static const int updateRate = 50;

  /// The time elapsed from the start to the end of the game in [ms]
  static int gameTime = 0;

  /// The minimum number of points required to win the game.
  static const int winningCondition = 200;

  /// A flag that is true when the user shifts the board and false otherwise.
  static bool boardShifting = false;
  static Offset shift = Offset.zero;
  static Offset shiftPointer = Offset.zero;
  static const int shiftCooldown = 10000;
  static const int shiftOnTime = 2000;
  static int shiftTime = 0;

  static List<Target> targets = List.filled(_maxTargets, Target(Offset.zero, 0, 0), growable: false);
  static List<Enemy> enemies = <Enemy>[];
  static List<Block> blocks = <Block>[];
  static List<Laser> lasers = <Laser>[];
  static Offset bounds = Offset.zero;
  static const int _enemiesThreshold = 5;
  static const int _blocksThreshold = 25;
  static const int _bouncingBlocksInterval = 3;
  static const int _laserThreshold = 70;
  static const int _maxTargets = 3;
  static const int _maxEnemies = 30;
  static const int _maxBlocks = 20;
  static const int _maxLaser = 5;
  static const int _blockStep = 8;
  static const int _laserStep = 20;

  static void initializeGameState(Offset pointerPosition, Offset bounds) {
    gameTime = DateTime.now().millisecondsSinceEpoch;

    player.initializePosition(pointerPosition);

    for (int targetIndex = 0; targetIndex < targets.length; targetIndex++) {
      targets[targetIndex] = _createTarget(player.centerPosition);
    }
  }

  static void updateBackground(int time, int xOffset, int yOffset) {
    if (AppState.imageUpdateStatus != LengthyProcess.ongoing) {
      AppState.imageUpdateStatus = LengthyProcess.ongoing;
      cLayerBindings.draw_background(time, xOffset, yOffset);
    }
  }

  static void updateGameState() {
    if (player.points >= winningCondition) {
      _endGame();
    }

    for (int targetIndex = 0; targetIndex < targets.length; targetIndex++) {
      targets[targetIndex].timeAlive += updateRate;
      bool targetCollision = _checkForCollision(player, targets[targetIndex]);
      if (targetCollision) {
        player.points += targets[targetIndex].point;
        targets[targetIndex] = _createTarget(player.centerPosition);
      }
      if (targets[targetIndex].timeAlive > targets[targetIndex].longevity) {
        targets[targetIndex] = _createTarget(player.centerPosition);
      }
    }

    if (player.points > _blocksThreshold + blocks.length * _blockStep && blocks.length < _maxBlocks) {
      if ((blocks.length + 1) % _bouncingBlocksInterval == 0) {
        blocks.add(_createBlock(player.centerPosition, true));
      } else {
        blocks.add(_createBlock(player.centerPosition, false));
      }
    }

    shiftTime += updateRate;
    if (boardShifting) {
      _shiftTheBoard();
      if (shiftTime >= shiftOnTime) {
        boardShifting = false;
        shiftTime = 0;
      }
    }

    for (int laserIndex = lasers.length; laserIndex > 0; laserIndex--) {
      bool laserCollision = Calculations.laserAndCircleOverlap(lasers[laserIndex - 1], CircularObject(player.centerPosition, player.hitBoxRadius));
      if (laserCollision) {
        _endGame();
        return;
      }
      lasers[laserIndex - 1].timeAlive += updateRate;
      if (lasers[laserIndex - 1].timeAlive >= lasers[laserIndex - 1].longevity) {
        lasers.removeAt(laserIndex - 1);
      }
    }
    if (player.points > _laserThreshold + lasers.length * _laserStep && lasers.length < _maxLaser) {
      lasers.add(_createLaser(player.centerPosition));
    }

    if (player.points > _enemiesThreshold) {
      for (int enemyIndex = 0; enemyIndex < (player.points / _enemiesThreshold).ceil() - 1; enemyIndex++) {
        if (enemyIndex == enemies.length && enemies.length < _maxEnemies) {
          enemies.add(_createEnemy(player.centerPosition));
        } else {
          bool enemyCollision = _checkForCollision(player, enemies[enemyIndex]);
          if (enemyCollision) {
            _endGame();
            return;
          }
          if (enemies[enemyIndex].hasBounced) {
            enemies[enemyIndex].timeSinceBounce += updateRate;
          } else {
            for (int blockIndex = 0; blockIndex < blocks.length; blockIndex++) {
              if (blocks[blockIndex] is BouncingBlock) {
                bool bouncingBlockCollision = Calculations.blockAndCircleOverlap(blocks[blockIndex], enemies[enemyIndex]);
                if (bouncingBlockCollision) {
                  enemies[enemyIndex].bounce((blocks[blockIndex] as BouncingBlock).chock);
                  enemies[enemyIndex].hasBounced = true;
                }
              }
            }
          }
          if (enemies[enemyIndex].hasBounced && enemies[enemyIndex].timeSinceBounce >= enemies[enemyIndex].minTimeBetweenBounces) {
            enemies[enemyIndex].hasBounced = false;
            enemies[enemyIndex].timeSinceBounce = 0;
          }
          enemies[enemyIndex].updatePosition();
        }
      }

      for (int enemyIndex = enemies.length; enemyIndex > 0; enemyIndex--) {
        if (_checkOutOfBounds(enemies[enemyIndex - 1])) {
          enemies.removeAt(enemyIndex - 1);
        }
      }
    }
  }

  /// Applies the background's [shift] resulting from the user dragging the screen to all [enemies] and [lasers].
  static void _shiftTheBoard() {
    for (int enemyIndex = 0; enemyIndex < enemies.length; enemyIndex++) {
      enemies[enemyIndex].shiftPosition(shift, shiftPointer);
    }

    for (int laserIndex = 0; laserIndex < lasers.length; laserIndex++) {
      lasers[laserIndex].shiftPosition(shift.dx, shift.dy);
    }
  }

  /// Ends the game by killing the [player] (alive = false),
  ///
  /// emptying [targets], [enemies], [blocks] and [lasers] and,
  ///
  /// calculating the [gameTime].
  static void _endGame() {
    player.death();
    for (int targetIndex = 0; targetIndex < targets.length; targetIndex++) {
      targets[targetIndex] = Target(Offset.zero, 0, 0);
    }
    enemies.clear();
    blocks.clear();
    lasers.clear();

    gameTime = DateTime.now().millisecondsSinceEpoch - gameTime;
  }

  /// Returns true if the [player] has collided with the [object] and false otherwise.
  static bool _checkForCollision(Player player, CircularObject object) {
    return (player.centerPosition - object.centerPosition).distanceSquared <= pow(player.hitBoxRadius + object.hitBoxRadius, 2);
  }

  /// Returns true if the [object] has left the screen and false otherwise.
  static bool _checkOutOfBounds(CircularObject object) {
    const double margin = 100;
    return object.centerPosition.dx + margin <= 0 ||
        object.centerPosition.dx - margin >= bounds.dx ||
        object.centerPosition.dy + margin <= 0 ||
        object.centerPosition.dy - margin >= bounds.dy;
  }

  /// Create a random [Target] some distance away from the [exclusionCenter] point.
  ///
  /// The [Target]'s size is inversely proportional to the number of points ([1;5]) it contains.
  static Target _createTarget(Offset exclusionCenter) {
    int point = Random().nextInt(5) + 1;
    double hitBoxRadius = 35 - point * 5;

    Offset position = exclusionCenter;
    while ((position - exclusionCenter).distanceSquared < 1000) {
      position =
          Offset(hitBoxRadius + Random().nextDouble() * (bounds.dx - hitBoxRadius * 2), hitBoxRadius + Random().nextDouble() * (bounds.dy - hitBoxRadius * 2));
    }

    return Target(position, hitBoxRadius, point);
  }

  /// Returns a random [Enemy] that starts its course outside a ramdom edge of the screen.
  ///
  /// The direction of the [Enemy] is set toward the [aimedPosition].
  static Enemy _createEnemy(Offset aimedPosition) {
    const double hitBoxRadius = 15;
    Edge entryEdge = Edge.values[Random().nextInt(4)];
    Offset startPosition;
    switch (entryEdge) {
      case Edge.left:
        startPosition = Offset(-hitBoxRadius, Random().nextDouble() * bounds.dy);
        break;
      case Edge.top:
        startPosition = Offset(Random().nextDouble() * bounds.dx, -hitBoxRadius);
        break;
      case Edge.right:
        startPosition = Offset(bounds.dx + hitBoxRadius, Random().nextDouble() * bounds.dy);
        break;
      case Edge.bottom:
        startPosition = Offset(Random().nextDouble() * bounds.dx, bounds.dy + hitBoxRadius);
        break;
    }
    double angle = atan2((aimedPosition.dy - startPosition.dy), (aimedPosition.dx - startPosition.dx));
    double speed = Random().nextDouble() * (10 + max(bounds.dx, bounds.dy) / 100);

    return Enemy(startPosition, hitBoxRadius, angle, speed);
  }

  /// Returns a random [Block] some distance away from the [exclusionCenter] point.
  ///
  /// If [bouncing] is true, returns a random [BouncingBlock] instead.
  static Block _createBlock(Offset exclusionCenter, bool bouncing) {
    double width = 10 + Random().nextDouble() * 10;
    double height = 50 + Random().nextDouble() * 150;

    Offset position = exclusionCenter;
    while ((position - exclusionCenter).distanceSquared < pow(height, 2)) {
      position = Offset(Random().nextDouble() * (bounds.dx - width), Random().nextDouble() * (bounds.dy - height));
    }

    if (Random().nextBool()) {
      return bouncing ? BouncingBlock(height, width, position, Random().nextDouble() * 2) : Block(height, width, position);
    } else {
      return bouncing ? BouncingBlock(width, height, position, Random().nextDouble() * 2) : Block(width, height, position);
    }
  }

  /// Returns a random [Laser] some distance away from the [exclusionCenter] point.
  static Laser _createLaser(Offset exclusionCenter) {
    Edge entryEdge = [Edge.left, Edge.top][Random().nextInt(2)];
    Offset startPosition, endPosition;
    if (entryEdge == Edge.left) {
      double start = exclusionCenter.dy;
      while ((start - exclusionCenter.dy).abs() < 150) {
        start = Random().nextDouble() * bounds.dy;
      }
      startPosition = Offset(0, start);
      endPosition = startPosition + Offset(bounds.dx, 0);
    } else {
      double start = exclusionCenter.dx;
      while ((start - exclusionCenter.dx).abs() < 150) {
        start = Random().nextDouble() * bounds.dx;
      }
      startPosition = Offset(start, 0);
      endPosition = startPosition + Offset(0, bounds.dy);
    }

    return Laser(startPosition, endPosition);
  }
}

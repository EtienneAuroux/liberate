import 'dart:async';
import 'dart:collection';
import 'dart:ffi';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:ui';

import 'package:event/event.dart';
import 'package:flow/bindings.dart';

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

  // GAME RELATED OBJECT //

  static Player player = Player();

  /// The rate at which the game state is updated in [ms].
  static const int updateRate = 50;
  static List<Target> targets = List.filled(_maxTargets, Target(Offset.zero, 0, 0), growable: false);
  static List<Enemy> enemies = <Enemy>[];
  static List<Block> blocks = <Block>[];
  static List<Laser> lasers = <Laser>[];
  static Offset bounds = Offset.zero;
  static const int _enemiesThreshold = 5;
  static const int _blocksThreshold = 30;
  static const int _laserThreshold = 5;
  static const int _maxTargets = 3;
  static const int _maxEnemies = 30;
  static const int _maxBlocks = 20;
  static const int _maxLaser = 5;
  static const int _blockStep = 10;
  static const int _laserStep = 5;

  static void initializeGameState(Offset pointerPosition, Offset bounds) {
    player.initializePosition(pointerPosition);

    for (int targetIndex = 0; targetIndex < targets.length; targetIndex++) {
      targets[targetIndex] = _createTarget(player.position);
    }
  }

  static void updateGameState() {
    for (int targetIndex = 0; targetIndex < targets.length; targetIndex++) {
      targets[targetIndex].timeAlive += updateRate;
      bool targetCollision = _checkForCollision(player, targets[targetIndex]);
      if (targetCollision) {
        player.points += targets[targetIndex].point;
        targets[targetIndex] = _createTarget(player.position);
      }
      if (targets[targetIndex].timeAlive > 10000) {
        targets[targetIndex] = _createTarget(player.position);
      }
    }

    if (player.points > _blocksThreshold + blocks.length * _blockStep && blocks.length < _maxBlocks) {
      blocks.add(_createBlock(player.position));
    }

    for (int laserIndex = 0; laserIndex < lasers.length; laserIndex++) {
      lasers[laserIndex].timeAlive += updateRate;
    }
    if (player.points > _laserThreshold + lasers.length * _laserStep && lasers.length < _maxLaser) {
      lasers.add(_createLaser(player.position));
    }
    if (lasers.length == _maxLaser && lasers.first.timeAlive >= lasers.first.longevity) {
      lasers.removeAt(0);
    }

    if (player.points > _enemiesThreshold) {
      for (int enemyIndex = 0; enemyIndex < (player.points / _enemiesThreshold).ceil(); enemyIndex++) {
        if (enemyIndex == enemies.length && enemies.length < _maxEnemies) {
          enemies.add(_createEnemy(player.position));
        } else {
          bool enemyCollision = _checkForCollision(player, enemies[enemyIndex]);
          if (enemyCollision) {
            _endGame();
            return;
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

  static void _endGame() {
    player.death();
    for (int targetIndex = 0; targetIndex < targets.length; targetIndex++) {
      targets[targetIndex] = Target(Offset.zero, 0, 0);
    }
    enemies.clear();
    blocks.clear();
  }

  static bool _checkForCollision(Player player, CircularObject object) {
    return (player.position - object.position).distanceSquared <= pow(player.hitBoxRadius + object.hitBoxRadius, 2);
  }

  static bool _checkOutOfBounds(CircularObject object) {
    const double margin = 100;
    return object.position.dx + margin <= 0 ||
        object.position.dx - margin >= bounds.dx ||
        object.position.dy + margin <= 0 ||
        object.position.dy - margin >= bounds.dy;
  }

  static Target _createTarget(Offset exclusionCenter) {
    int point = Random().nextInt(5) + 1;
    Offset position = exclusionCenter;
    while ((position - exclusionCenter).distanceSquared < 1000) {
      position = Offset(Random().nextDouble() * bounds.dx, Random().nextDouble() * bounds.dy);
    }
    double hitBoxRadius = 35 - point * 5;
    return Target(position, hitBoxRadius, point);
  }

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

  static Block _createBlock(Offset exclusionCenter) {
    double width = 10 + Random().nextDouble() * 10;
    double height = 50 + Random().nextDouble() * 150;

    Offset position = exclusionCenter;
    while ((position - exclusionCenter).distanceSquared < pow(width, 2)) {
      position = Offset(Random().nextDouble() * (bounds.dx - width / 2), Random().nextDouble() * (bounds.dy - height / 2));
    }

    if (Random().nextBool()) {
      return Block(height, width, position);
    } else {
      return Block(width, height, position);
    }
  }

  static Laser _createLaser(Offset exclusionCenter) {
    // TODO HANDLE EXCLUSION ZONE
    Edge entryEdge = [Edge.left, Edge.top][Random().nextInt(2)];
    Offset startPosition, endPosition;
    if (entryEdge == Edge.left) {
      startPosition = Offset(0, Random().nextDouble() * bounds.dy);
      endPosition = startPosition + Offset(bounds.dx, 0);
    } else {
      startPosition = Offset(Random().nextDouble() * bounds.dx, 0);
      endPosition = startPosition + Offset(0, bounds.dy);
    }

    return Laser(startPosition, endPosition);
  }
}

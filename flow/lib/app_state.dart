import 'dart:async';
import 'dart:ffi';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:event/event.dart';
import 'package:flow/bindings.dart';
import 'package:flow/calculations.dart';

// import 'dart:developer' as dev;

import 'package:flow/types.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The [AppState] handles the game objects ([Player], [Target], [Enemy], [Block], [BouncingBlock], [Laser])
/// and manages the game mechanics such as points, collisions and user interactions at each tick.
///
/// The [AppState] also handles communication with the underlying c_layer and serves as liaison between the c_layer and the rest of the software.
class AppState {
  // --------------------------------------- BACKGROUND RELATED OBJECTS --------------------------------------- //
  /// The [Painting] holding the latest valid background received from the c_layer.
  static Painting painting = Painting();

  /// Notifies listening widgets each time a new [Painting] has been successfully received from the c_layer and processed via [_handleNewFrame].
  static Event onNewImage = Event();

  /// Keeps track of calls to the c_layer to process a new background.
  ///
  /// Calls switch the [LengthyProcess] to [LengthyProcess.ongoing] and [_handleNewFrame] will switch it to [LengthyProcess.failed] and [LengthyProcess.done] based on the validity of the [FrameEvent].
  static LengthyProcess imageUpdateStatus = LengthyProcess.unknown;

  /// Initializes the c_layer with the screen size.
  ///
  /// If the screen is too big will default to 3500x2000.
  static void initialize() {
    ui.Size size = ui.PlatformDispatcher.instance.views.first.physicalSize;
    double pixelRatio = ui.PlatformDispatcher.instance.views.first.devicePixelRatio;

    int maxWidth = max((size.width / pixelRatio).ceil(), 3500);
    int maxHeight = max((size.height / pixelRatio).ceil(), 2000);

    cLayerBindings.initialize(Pointer.fromFunction<FuncPtrNewFrame>(_onNewFrame), maxWidth, maxHeight);
  }

  /// When the user resizes the screen, conveys the change to the c_layer.
  static void updateBackgroundSize(int width, int height, int gameTime, int xOffset, int yOffset) {
    cLayerBindings.update_background_size(width, height, gameTime, xOffset, yOffset);
  }

  /// Notifies the c_layer that the user wants to change the [BackgroundConfiguration].
  static void changeBackgroundConfiguration(BackgroundConfiguration configuration) {
    cLayerBindings.update_background_config(configuration.index);
  }

  /// When the user adjusts the colors of the game, conveys the change to the c_layer.
  static void updateBackgroundColor(int increment) {
    cLayerBindings.update_background_color(increment);
  }

  /// Receives frame_callback from the c_layer and converts it to a [FrameEvent] on the dart side.
  static void _onNewFrame(int width, int height, int dataSize, Pointer<Void> data) {
    FrameEvent frameEvent = FrameEvent(width, height, data, dataSize);
    _handleNewFrame(frameEvent);
  }

  /// Handles a [FrameEvent] and if valid will convert the buffer into a [Painting] that can be shown on a flutter canvas.
  ///
  /// If successful broadcast an [Event] to listening widgets.
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

  // --------------------------------------- SAVED OBJECTS --------------------------------------- //
  /// Used to store the user's [List] of [HighScore].
  static SharedPreferences? _preferences;

  /// The maximum number of [HighScore] that will be remembered.
  static const _maxHighScores = 5;

  /// The current [List] of [HighScore].
  static List<HighScore> highScores = <HighScore>[];

  /// Gets the [List] of [HighScore] from the [SharedPreferences].
  ///
  /// Also initializes the [SharedPreferences] instance if not done already.
  static Future<void> getHighScores() async {
    _preferences ??= await SharedPreferences.getInstance();

    String? temporary = _preferences!.getString('highScores');
    if (temporary != null) {
      highScores.clear();
      highScores.addAll(HighScore.decode(temporary));
    }
  }

  /// Checks if the user's [points] or [time] are sufficient to be registered among the [HighScore].
  ///
  /// If the user has fulfilled the winning condition, [time] is used, otherwise [points] are used.
  ///
  /// If the user's score is registered as a [HighScore], update the [List] of [HighScore] and saved it into the [SharedPreferences].
  static Future<void> _addHighScore(int points, int time) async {
    if (_preferences == null) {
      return;
    }

    if (highScores.isEmpty) {
      highScores.add(
        HighScore(
          position: 1,
          time: time,
          dateMsSinceEpoch: DateTime.now().millisecondsSinceEpoch,
          points: points,
        ),
      );
    } else {
      for (int scoreIndex = 0; scoreIndex < highScores.length; scoreIndex++) {
        if (points >= winningCondition) {
          if (time < highScores[scoreIndex].time) {
            highScores.insert(
              scoreIndex,
              HighScore(
                position: scoreIndex + 1,
                time: time,
                dateMsSinceEpoch: DateTime.now().millisecondsSinceEpoch,
                points: points,
              ),
            );
            break;
          }
        } else {
          if (highScores[scoreIndex].points < winningCondition && points > highScores[scoreIndex].points) {
            highScores.insert(
              scoreIndex,
              HighScore(
                position: scoreIndex + 1,
                time: time,
                dateMsSinceEpoch: DateTime.now().millisecondsSinceEpoch,
                points: points,
              ),
            );
            break;
          }
        }
      }
      if (highScores.length > _maxHighScores) {
        highScores.removeLast();
      }
    }

    await _preferences!.setString('highScores', HighScore.encode(highScores));
  }

  /// Clear the list of [HighScore] include data saved in the [SharedPreferences].
  static Future<void> resetHighScores() async {
    if (_preferences == null) {
      return;
    }
    highScores.clear();
    await _preferences!.clear();
  }

  // --------------------------------------- GAME RELATED OBJECTS --------------------------------------- //
  /// The player defined by its position, direction, speed, radius and alive status.
  static Player player = Player();

  /// The rate at which the game state is updated in [ms].
  static const int updateRate = 50;

  /// The time elapsed from the start to the end of the game in [ms]
  static int gameTime = 0;

  /// The minimum number of points required to win the game.
  static const int winningCondition = 200;

  /// A flag that is true when the user utilizes their power and false otherwise.
  static bool boardShifting = false;

  /// The bounds of the screen as defined by its bottom-right corner coordinates.
  static ui.Offset bounds = ui.Offset.zero;

  /// The magnitude of the shift imposed by the user while utilizing their power.
  static ui.Offset shift = ui.Offset.zero;

  /// The position of the pointer when [boardShifting] is true.
  static ui.Offset shiftPointer = ui.Offset.zero;

  /// The time that must be waiting between two activation of their power by the user in milliseconds.
  static const int shiftCooldown = 10000;

  /// The maximum time during which the user's power can be used in milliseconds.
  static const int shiftOnTime = 2000;

  /// The time that the user's power has been used in milliseconds.
  static int shiftTime = 0;

  /// A non-growable list of all existing [Target].
  ///
  /// There are 3 [Target] existing at all times.
  static List<Target> targets = List.filled(_maxTargets, Target(ui.Offset.zero, 0, 0), growable: false);

  /// The list of existing [Enemy].
  ///
  /// Note that the list only expands toward the maximum possible number of [Enemy] and is only cleared upon the death of the [Player].
  static List<Enemy> enemies = <Enemy>[];

  /// The list of existing [Block]. Also contains [BouncingBlock].
  ///
  /// Note that the list only expands toward the maximum possible number of [Block] and is only cleared upon the death of the [Player].
  static List<Block> blocks = <Block>[];

  /// The list of existing [Laser].
  ///
  /// Note that the list only expands toward the maximum possible number of [Laser] and is only cleared upon the death of the [Player].
  static List<Laser> lasers = <Laser>[];

  /// The minimum number of points required for a [Enemy] to be created.
  ///
  /// Also serves as the number of point the player must accumulate since the last [Enemy] has appeared for another [Enemy] to be created.
  static const int _enemiesThreshold = 5;

  /// The minimum number of points required for a [Block] to be created.
  static const int _blocksThreshold = 25;

  /// The minimum number of points required for a [Laser] to be created.
  static const int _laserThreshold = 70;

  /// The maximum number of [Target] that can be present on the screen at any given time.
  static const int _maxTargets = 3;

  /// The maximum number of [Enemy] that can be present on the screen at any given time.
  static const int _maxEnemies = 30;

  /// The maximum number of [Block] that can be present on the screen at any given time.
  static const int _maxBlocks = 20;

  /// The maximum number of [Laser] that can be present on the screen at any given time.
  static const int _maxLaser = 5;

  /// The number of point the player must accumulate since the last [Block] has appeared for another [Block] to be created.
  static const int _blockStep = 8;

  /// When a [Block] is created if the number of [Block] would become a multiple of [_bouncingBlocksInterval] then a [BouncingBlock] is created instead.
  ///
  /// Note that since a [BouncingBlock] is a [Block], the number of existing [BouncingBlock] is also taken into account.
  static const int _bouncingBlocksInterval = 3;

  /// The number of point the player must accumulate since the last [Laser] has appeared for another [Laser] to be created.
  static const int _laserStep = 20;

  /// Initialize the game upon the user right click whilst [Player] is not alive.
  ///
  /// The [Player] will be created at [pointerPosition].
  static void initializeGameState(ui.Offset pointerPosition) {
    gameTime = DateTime.now().millisecondsSinceEpoch;

    player.initializePosition(pointerPosition);

    for (int targetIndex = 0; targetIndex < targets.length; targetIndex++) {
      targets[targetIndex] = _createTarget(player.centerPosition);
    }
  }

  /// Asks the c_layer to update the background of the game based on the game [time].
  static void updateBackground(int time, int xOffset, int yOffset) {
    if (AppState.imageUpdateStatus != LengthyProcess.ongoing) {
      AppState.imageUpdateStatus = LengthyProcess.ongoing;
      cLayerBindings.draw_background(time, xOffset, yOffset);
    }
  }

  /// Update the state of the [Player], all [Target], all [Enemy] and all [Laser] existing.
  ///
  /// Based on the number of points earned by the [Player], creates new [Enemy], [Block] and [Laser].
  ///
  /// Handles end game conditions.
  ///
  /// Handles board shifting events corresponding to the user using their power.
  static void updateGameState() {
    if (player.points >= winningCondition) {
      _endGame();
      return;
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
    gameTime = DateTime.now().millisecondsSinceEpoch - gameTime;
    _addHighScore(player.points, gameTime);

    player.death();
    for (int targetIndex = 0; targetIndex < targets.length; targetIndex++) {
      targets[targetIndex] = Target(ui.Offset.zero, 0, 0);
    }
    enemies.clear();
    blocks.clear();
    lasers.clear();
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

  /// Creates a random [Target] some distance away from the [exclusionCenter] point.
  ///
  /// The [Target]'s size is inversely proportional to the number of points ([1;5]) it contains.
  static Target _createTarget(ui.Offset exclusionCenter) {
    int point = Random().nextInt(5) + 1;
    double hitBoxRadius = 35 - point * 5;

    ui.Offset position = exclusionCenter;
    while ((position - exclusionCenter).distanceSquared < 1000) {
      position = ui.Offset(
          hitBoxRadius + Random().nextDouble() * (bounds.dx - hitBoxRadius * 2), hitBoxRadius + Random().nextDouble() * (bounds.dy - hitBoxRadius * 2));
    }

    return Target(position, hitBoxRadius, point);
  }

  /// Returns a random [Enemy] that starts its course outside a ramdom edge of the screen.
  ///
  /// The direction of the [Enemy] is set toward the [aimedPosition].
  static Enemy _createEnemy(ui.Offset aimedPosition) {
    const double hitBoxRadius = 15;
    Edge entryEdge = Edge.values[Random().nextInt(4)];
    ui.Offset startPosition;
    switch (entryEdge) {
      case Edge.left:
        startPosition = ui.Offset(-hitBoxRadius, Random().nextDouble() * bounds.dy);
        break;
      case Edge.top:
        startPosition = ui.Offset(Random().nextDouble() * bounds.dx, -hitBoxRadius);
        break;
      case Edge.right:
        startPosition = ui.Offset(bounds.dx + hitBoxRadius, Random().nextDouble() * bounds.dy);
        break;
      case Edge.bottom:
        startPosition = ui.Offset(Random().nextDouble() * bounds.dx, bounds.dy + hitBoxRadius);
        break;
    }
    double angle = atan2((aimedPosition.dy - startPosition.dy), (aimedPosition.dx - startPosition.dx));
    double speed = Random().nextDouble() * (10 + max(bounds.dx, bounds.dy) / 100);

    return Enemy(startPosition, hitBoxRadius, angle, speed);
  }

  /// Returns a random [Block] some distance away from the [exclusionCenter] point.
  ///
  /// If [bouncing] is true, returns a random [BouncingBlock] instead.
  static Block _createBlock(ui.Offset exclusionCenter, bool bouncing) {
    double width = 10 + Random().nextDouble() * 10;
    double height = 50 + Random().nextDouble() * 150;

    ui.Offset position = exclusionCenter;
    while ((position - exclusionCenter).distanceSquared < pow(height, 2)) {
      position = ui.Offset(Random().nextDouble() * (bounds.dx - width), Random().nextDouble() * (bounds.dy - height));
    }

    if (Random().nextBool()) {
      return bouncing ? BouncingBlock(height, width, position, Random().nextDouble() * 2) : Block(height, width, position);
    } else {
      return bouncing ? BouncingBlock(width, height, position, Random().nextDouble() * 2) : Block(width, height, position);
    }
  }

  /// Returns a random [Laser] some distance away from the [exclusionCenter] point.
  static Laser _createLaser(ui.Offset exclusionCenter) {
    Edge entryEdge = [Edge.left, Edge.top][Random().nextInt(2)];
    ui.Offset startPosition, endPosition;
    if (entryEdge == Edge.left) {
      double start = exclusionCenter.dy;
      while ((start - exclusionCenter.dy).abs() < 150) {
        start = Random().nextDouble() * bounds.dy;
      }
      startPosition = ui.Offset(0, start);
      endPosition = startPosition + ui.Offset(bounds.dx, 0);
    } else {
      double start = exclusionCenter.dx;
      while ((start - exclusionCenter.dx).abs() < 150) {
        start = Random().nextDouble() * bounds.dx;
      }
      startPosition = ui.Offset(start, 0);
      endPosition = startPosition + ui.Offset(0, bounds.dy);
    }

    return Laser(startPosition, endPosition);
  }
}

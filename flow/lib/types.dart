import 'dart:convert';
import 'dart:ffi';
import 'dart:math';
import 'dart:ui';

import 'package:event/event.dart';
import 'package:flow/calculations.dart';

/// A class representing a [Painting] to be displayed on the screen.
///
/// [Painting] is made to hold a [FrameEvent] and transforms its data into an [Image] usable by the dart side.
class Painting {
  /// The width of the [Painting] in pixel.
  double? width;

  /// The height of the [Painting] in pixel.
  double? height;

  /// The image of the [Painting].
  Image? image;
}

/// A class representing a [FrameEvent] sent from the c_layer to the dart side.
///
/// Each frame is an array of unsigned bytes called [data] of length [dataSize].
///
/// Each frame represents an image to be drawn on the screen and is therefore a screen of dimensions [width] and [height].
class FrameEvent extends EventArgs {
  /// The [width] of the image.
  final int width;

  /// The [height] of the image.
  final int height;

  /// The [length] of the [data] array.
  final int dataSize;

  /// The actual pixel [data] arranged in the RGBA8888 order.
  final Pointer<Void> data;

  /// Public constructor of [FrameEvent].
  ///
  /// Requires three [int] for the [width], [height] and [dataSize] as well as a [Pointer] to the [data] array.
  FrameEvent(this.width, this.height, this.data, this.dataSize);
}

class HighScore {
  final int position;
  final int time;
  final int dateMsSinceEpoch;
  final int points;

  HighScore({required this.position, required this.time, required this.dateMsSinceEpoch, required this.points});

  factory HighScore.fromJson(Map<String, dynamic> jsonData) {
    return HighScore(
      position: jsonData['position'],
      time: jsonData['time'],
      dateMsSinceEpoch: jsonData['date'],
      points: jsonData['points'],
    );
  }

  static Map<String, dynamic> toMap(HighScore score) => {
        'position': score.position,
        'time': score.time,
        'date': score.dateMsSinceEpoch,
        'points': score.points,
      };

  static String encode(List<HighScore> scores) => json.encode(scores.map<Map<String, dynamic>>((HighScore score) => HighScore.toMap(score)).toList());

  static List<HighScore> decode(String scores) => (json.decode(scores) as List<dynamic>).map<HighScore>((jsonItem) => HighScore.fromJson(jsonItem)).toList();
}

/// A class representing the [Player], i.e. the user.
///
/// A [Player], if [alive], will aim to increase its number of [points] by moving its [centerPosition] on the screen to capture [Target].
class Player {
  /// A flag that is true if the [Player] is alive and false otherwise.
  bool alive = false;

  /// The number of points that the [Player] has accumulated.
  int points = 0;

  /// The radius of the [Player].
  final double hitBoxRadius = 20;

  /// The position of the center of the [Player] on the screen.
  Offset _centerPosition = Offset.zero;

  /// The position of the center of the [Player] on the screen.
  Offset get centerPosition => _centerPosition;

  /// The angle of the [Player] in radians.
  ///
  /// The angle determines the direction of the [Player] with respect to the bottom-left corner of the 2D cartesian reference system represented by the screen.
  double _angle = 0;

  /// The angle of the [Player] in radians.
  ///
  /// The angle determines the direction of the [Player] with respect to the bottom-left corner of the 2D cartesian reference system represented by the screen.
  double get angle => _angle;

  /// The speed of the [Player] in pixel per time unit.
  double _speed = 0;

  /// Sets the [centerPosition] of the [Player] to be equal to [pointerPosition].
  ///
  /// This should only be called if the [Player] is not [alive].
  ///
  /// Side-effects: sets [points] to 0 and [alive] to true.
  void initializePosition(Offset pointerPosition) {
    if (centerPosition.dx == 0 && centerPosition.dy == 0) {
      _centerPosition = pointerPosition;
      points = 0;
      alive = true;
    }
  }

  /// Sets the [_angle] of the [Player] so that it moves toward the [pointerPosition].
  void setAngle(Offset pointerPosition) {
    _angle = atan2((pointerPosition.dy - centerPosition.dy), (pointerPosition.dx - centerPosition.dx));
  }

  /// Updates the [_centerPosition] and [_speed] of the [Player] based on the user's [pointerPosition].
  ///
  /// The [Player] moves towards the [pointerPosition] at a speed that scales with the distance between the two.
  ///
  /// The [Player] movements are stopped if it meets the screen's bounds or a [Block].
  void updatePositionAndSpeed(Offset pointerPosition, Offset bounds, List<Block> blocks) {
    _speed = 1 +
        sqrt(pow((centerPosition.dx - pointerPosition.dx).abs(), 2) + pow((centerPosition.dy - pointerPosition.dy).abs(), 2)) /
            (max(bounds.dx, bounds.dy) / 100);
    Offset newPosition = Offset(centerPosition.dx + cos(_angle) * _speed, centerPosition.dy + sin(_angle) * _speed);
    if ((newPosition - pointerPosition).distanceSquared < hitBoxRadius) {
      return;
    }

    Offset remainingDistance = Offset.zero;
    for (Block block in blocks) {
      if (Calculations.blockAndCircleOverlap(block, CircularObject(newPosition, hitBoxRadius))) {
        remainingDistance = Calculations.circleToBlockVector(block, CircularObject(centerPosition, hitBoxRadius));
        _centerPosition += remainingDistance;
        return;
      }
    }
    if (newPosition.dx >= hitBoxRadius &&
        newPosition.dx <= bounds.dx - hitBoxRadius &&
        newPosition.dy >= hitBoxRadius &&
        newPosition.dy <= bounds.dy - hitBoxRadius) {
      _centerPosition = newPosition;
    }
  }

  /// Kills the [Player] by setting [alive] to false, its [_centerPosition] to the top-left corner, its [_angle] to 0 and its [_speed] to 0.
  void death() {
    alive = false;
    _centerPosition = Offset.zero;
    _angle = 0;
    _speed = 0;
  }
}

/// A class representing a [CircularObject].
///
/// A [CircularObject] is a circle characterized by its [centerPosition] and [hitBoxRadius].
class CircularObject {
  /// The position of the center of the [CircularObject].
  Offset centerPosition;

  /// The radius of the [CircularObject].
  double hitBoxRadius;

  /// Public constructor of [CircularObject].
  ///
  /// Requires an [Offset] and a [double] for the center position and radius of the [CircularObject], respectively.
  CircularObject(this.centerPosition, this.hitBoxRadius);
}

/// A class representing a [Target] on the screen.
///
/// A [Target] is a [CircularObject] characterized by the number of [point] it has.
class Target extends CircularObject {
  /// The number of point the [Target] is worth.
  int point;

  /// The time the [Target] has been present on the screen since appearing in milliseconds.
  int timeAlive = 0;

  /// The maximum time the [Target] will remain on the screen in milliseconds.
  final int longevity = 10000;

  /// Public constructor of [Target].
  ///
  /// Requires an [Offset] and a [double] as the center position and radius of the [CircularObject], respectively.
  ///
  /// Requires an [int] for the [point] of the [Target].
  Target(super.centerPosition, super.hitBoxRadius, this.point);
}

/// A class representing an [Enemy] on the screen.
///
/// An [Enemy] is a [CircularObject] characterized by its [speed] and [angle].
///
/// The [angle] determines the direction of the [Enemy] with respect to the bottom-left corner of the 2D cartesian reference system represented by the screen.
///
/// An [Enemy] will go through normal [Block] but bounce off [BouncingBlock].
///
/// Once an [Enemy] has bounced off a [BouncingBlock] it will not be able to immediately bounce off another [BouncingBlock].
class Enemy extends CircularObject {
  /// The angle of the [Enemy] in radian.
  double angle;

  /// The speed of the [Enemy] in pixel per time unit.
  double speed;

  /// A flag that is true if the [Enemy] has just bounced off a [BouncingBlock] and is false otherwise.
  bool hasBounced = false;

  /// The time elapsed since the [Enemy] has bounced off a [BouncingBlock] in milliseconds.
  int timeSinceBounce = 0;

  /// The time in milliseconds that must be awaited by the [Enemy] after bouncing off a [BouncingBlock] before it'd be allowed to bounce off an other one.
  final int minTimeBetweenBounces = 250;

  /// Public constructor of [Enemy].
  ///
  /// Requires an [Offset] and a [double] as the center position and radius of the [CircularObject], respectively.
  ///
  /// Requires two more [double] for the [angle] and [speed] of the [Enemy].
  Enemy(super.centerPosition, super.hitBoxRadius, this.angle, this.speed);

  /// Updates the [centerPosition] of the [Enemy] by [speed]*sqrt(2) in the direction determined by [angle].
  void updatePosition() {
    centerPosition = Offset(centerPosition.dx + cos(angle) * speed, centerPosition.dy + sin(angle) * speed);
  }

  /// Adds [pi] to the [angle] of the [Enemy] to represent a bounce off a [BouncingBlock].
  ///
  /// Multiplies the speed of the [Enemy] by the encountered [BouncingBlock]'s [chock] value.
  void bounce(double chock) {
    angle += pi;
    if (speed * chock >= hitBoxRadius / 2) {
      speed *= chock;
    }
  }

  /// Reorients the [Enemy] toward the [pointerPosition] and adds a [shift] to it.
  void shiftPosition(Offset shift, Offset pointerPosition) {
    angle = atan2((pointerPosition.dy - centerPosition.dy), (pointerPosition.dx - centerPosition.dx));
    Offset newPosition = centerPosition + shift;
    centerPosition = newPosition;
  }
}

/// A class representing a [Block] on the screen.
///
/// A [Block] is a rectangle characterized by its [width], [height] and the [position] of its top-left corner.
class Block {
  /// The width of the [Block].
  final double width;

  /// The heigth of the [Block].
  final double height;

  /// The position of the top-left corner of the [Block].
  final Offset position;

  /// Public constructor of [Block].
  ///
  /// Requires two [double] for [width] and [height] and an [Offset] for the position of the top-left corner.
  Block(this.width, this.height, this.position);
}

/// A class representing a [BouncingBlock], i.e. a [Block] through which an [Enemy] cannot go but rather bounces onto.
class BouncingBlock extends Block {
  /// The multiplier applied to the bouncing object's speed, ]0;2].
  final double chock;

  /// Public constructor of [BouncingBlock].
  ///
  /// Requires two [double] for [width] and [height] and an [Offset] for the position of the top-left corner.
  ///
  /// Requires [chock] to be more than 0 and at most 2.
  BouncingBlock(super.width, super.height, super.position, this.chock)
      : assert(chock > 0),
        assert(chock <= 2);
}

/// A class representing a [Laser] going from one side of the screen to the opposite.
///
/// A [Laser] is a line that is either horizontal or vertical (no diagonal line) with a given thickness.
///
/// Each [Laser] has a lifetime during which its thickness grows to a maximum at the half-life point before reducing to 0 at which point the [Laser] disappears.
class Laser {
  /// The starting position of the [Laser] on one edge of the screen.
  Offset startPosition;

  /// The ending position of the [Laser] opposite to [startPosition];
  Offset endPosition;

  /// The thickness of the [Laser] upon appearing.
  final double minThickness = 2;

  /// The maximum thickness of the [Laser] reached when [timeAlive] is half of [longevity].
  final double maxThickness = 10;

  /// The time the [Laser] has lived on the screen in milliseconds.
  int timeAlive = 0;

  /// The maximum time the [Laser] is allowed on the screen in milliseconds.
  final int longevity = 5000;

  /// Public constructor of [Laser]. Requires two [Offset] to know where the [Laser] starts and ends.
  Laser(this.startPosition, this.endPosition);

  /// The [thickness] of the [Laser]. It depends on how long the [Laser] has been alive on the screen.
  double get thickness => timeAlive <= longevity / 2
      ? minThickness + (maxThickness - minThickness) * 2 * timeAlive / longevity
      : maxThickness - maxThickness * 2 * (timeAlive - longevity / 2) / longevity;

  /// Moves the [Laser] up or down for an horizontal [Laser] and left or right for a vertical [Laser].
  ///
  /// Directly affects the [startPosition] and [endPosition] used to draw the [Laser] on the canvas.
  void shiftPosition(double xShift, double yShift) {
    if (startPosition.dx == endPosition.dx) {
      startPosition = Offset(xShift + startPosition.dx, startPosition.dy);
      endPosition = Offset(xShift + endPosition.dx, endPosition.dy);
    } else {
      startPosition = Offset(startPosition.dx, yShift + startPosition.dy);
      endPosition = Offset(endPosition.dx, yShift + endPosition.dy);
    }
  }
}

/// An enum with the possible states of a time-consuming process.
enum LengthyProcess {
  /// The state of the process is unknown.
  unknown,

  /// The process is ongoing.
  ongoing,

  /// The process has completed.
  done,

  /// The process has failed.
  failed,
}

/// An enum listing the edges of a [Block] when facing the screen.
enum Edge {
  left,
  top,
  right,
  bottom,
}

/// An enum listing the possible configuration for the background.
///
/// Can then be used to notify the c_layer of the chosen configuration.
enum BackgroundConfiguration {
  grid,
  wave,
}

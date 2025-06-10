import 'dart:ffi';
import 'dart:math';
import 'dart:ui';

import 'package:event/event.dart';
import 'package:flow/calculations.dart';

class Painting {
  double? width;
  double? height;
  Image? image;
}

class FrameEvent extends EventArgs {
  final int width;
  final int height;
  final int dataSize;
  final Pointer<Void> data;

  FrameEvent(this.width, this.height, this.data, this.dataSize);
}

class Player {
  bool alive = false;
  int points = 0;

  double hitBoxRadius = 20;

  Offset _position = Offset.zero;
  Offset get position => _position;
  double _angle = 0;
  double _speed = 0;

  void initializePosition(Offset pointerPosition) {
    if (position.dx == 0 && position.dy == 0) {
      _position = pointerPosition;
      points = 0;
      alive = true;
    }
  }

  void setAngle(Offset pointerPosition) {
    _angle = atan2((pointerPosition.dy - position.dy), (pointerPosition.dx - position.dx));
  }

  void updatePositionAndSpeed(Offset pointerPosition, Offset bounds, List<Block> blocks) {
    _speed = 1 + sqrt(pow((position.dx - pointerPosition.dx).abs(), 2) + pow((position.dy - pointerPosition.dy).abs(), 2)) / (max(bounds.dx, bounds.dy) / 100);
    Offset newPosition = Offset(position.dx + cos(_angle) * _speed, position.dy + sin(_angle) * _speed);
    if ((newPosition - pointerPosition).distanceSquared < hitBoxRadius) {
      return;
    }

    Offset remainingDistance = Offset.zero;
    for (Block block in blocks) {
      if (Calculations.blockAndCircleOverlap(block, CircularObject(newPosition, hitBoxRadius))) {
        remainingDistance = Calculations.circleToBlockVector(block, CircularObject(position, hitBoxRadius));
        _position += remainingDistance;
        return;
      }
    }
    if (newPosition.dx >= hitBoxRadius &&
        newPosition.dx <= bounds.dx - hitBoxRadius &&
        newPosition.dy >= hitBoxRadius &&
        newPosition.dy <= bounds.dy - hitBoxRadius) {
      _position = newPosition;
    }
  }

  void death() {
    alive = false;
    _position = Offset.zero;
    _angle = 0;
    _speed = 0;
  }
}

class CircularObject {
  Offset position;
  double hitBoxRadius;

  CircularObject(this.position, this.hitBoxRadius);
}

class Target extends CircularObject {
  int point;
  int timeAlive = 0;

  Target(super.position, super.hitBoxRadius, this.point);
}

class Enemy extends CircularObject {
  double angle;
  double speed;
  bool hasBounced = false;
  double timeSinceBounce = 0;
  final double minTimeBetweenBounces = 250;

  Enemy(super.position, super.hitBoxRadius, this.angle, this.speed);

  void updatePosition() {
    position = Offset(position.dx + cos(angle) * speed, position.dy + sin(angle) * speed);
  }

  void bounce(double chock) {
    angle += pi;
  }

  void shiftPosition(Offset shift, Offset pointerPosition) {
    angle = atan2((pointerPosition.dy - position.dy), (pointerPosition.dx - position.dx));
    Offset newPosition = position + shift;
    position = newPosition;
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
  double timeAlive = 0;

  /// The maximum time the [Laser] is allowed on the screen in milliseconds.
  final double longevity = 5000;

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

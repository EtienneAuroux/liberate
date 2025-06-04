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
      if (Calculations.blockAndCircleIntersection(block, CircularObject(newPosition, hitBoxRadius))) {
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

  Enemy(super.position, super.hitBoxRadius, this.angle, this.speed);

  void updatePosition() {
    position = Offset(position.dx + cos(angle) * speed, position.dy + sin(angle) * speed);
  }
}

class Block {
  final double width;
  final double height;
  final Offset position;

  Block(this.width, this.height, this.position);
}

class Laser {
  final Offset startPosition;
  final Offset endPosition;
  final double minThickness = 2;
  final double maxThickness = 10;
  double timeAlive = 0;
  final double longevity = 5000;

  Laser(this.startPosition, this.endPosition);

  double get thickness => timeAlive <= longevity / 2
      ? minThickness + (maxThickness - minThickness) * 2 * timeAlive / longevity
      : maxThickness - maxThickness * 2 * (timeAlive - longevity / 2) / longevity;
}

enum LengthyProcess {
  unknown,
  ongoing,
  done,
  failed,
}

enum Edge {
  left,
  top,
  right,
  bottom,
}

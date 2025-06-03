import 'dart:ffi';
import 'dart:math';
import 'dart:ui';

import 'package:event/event.dart';

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
    // TODO NEED TO ADD THE REMAINING DISTANCE TO BLOCK INSTEAD OF STOPPING.
    for (Block block in blocks) {
      Offset centerToCenterDistance =
          Offset((block.position.dx + block.width / 2 - newPosition.dx).abs(), (block.position.dy + block.height / 2 - newPosition.dy).abs());
      if (centerToCenterDistance.dx > block.width / 2 + hitBoxRadius || centerToCenterDistance.dy > block.height / 2 + hitBoxRadius) {
        continue;
      }
      if (centerToCenterDistance.dx <= block.width / 2 || centerToCenterDistance.dy <= block.height / 2) {
        return;
      }
      double distanceToCornerSquared = pow(centerToCenterDistance.dx - block.width / 2, 2) + pow(centerToCenterDistance.dy - block.height / 2, 2) + 0.0;
      if (distanceToCornerSquared <= pow(hitBoxRadius, 2)) {
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
  double width;
  double height;
  Offset position;

  Block(this.width, this.height, this.position);
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

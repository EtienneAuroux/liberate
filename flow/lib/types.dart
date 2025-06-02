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
      alive = true;
    }
  }

  void setAngle(Offset pointerPosition) {
    _angle = atan2((pointerPosition.dy - position.dy), (pointerPosition.dx - position.dx));
  }

  void updatePositionAndSpeed(Offset pointerPosition, Offset bounds) {
    _speed = 1 + sqrt(pow((position.dx - pointerPosition.dx).abs(), 2) + pow((position.dy - pointerPosition.dy).abs(), 2)) / (max(bounds.dx, bounds.dy) / 100);
    Offset newPosition = Offset(position.dx + cos(_angle) * _speed, position.dy + sin(_angle) * _speed);
    if ((newPosition - pointerPosition).distanceSquared < hitBoxRadius) {
      return;
    }
    if (newPosition.dx >= hitBoxRadius &&
        newPosition.dx <= bounds.dx - hitBoxRadius &&
        newPosition.dy >= hitBoxRadius &&
        newPosition.dy <= bounds.dy - hitBoxRadius) {
      _position = newPosition;
    }
  }
}

class GameObject {
  Offset position;
  double hitBoxRadius;

  GameObject(this.position, this.hitBoxRadius);
}

class Target extends GameObject {
  int point;

  Target(super.position, super.hitBoxRadius, this.point);
}

class Enemy extends GameObject {
  double angle;
  double speed;

  Enemy(super.position, super.hitBoxRadius, this.angle, this.speed);

  void updatePosition() {
    position = Offset(position.dx + cos(angle) * speed, position.dy + sin(angle) * speed);
  }
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

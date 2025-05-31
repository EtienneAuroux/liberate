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
  Event onPlayerStatusChanged = Event();
  bool _alive = false;
  bool get alive => _alive;
  set alive(bool status) {
    _alive = status;
    onPlayerStatusChanged.broadcast();
  }

  Offset _position = Offset.zero;
  Offset get position => _position;
  double _angle = 0;
  double get angle => _angle;
  double _speed = 0;
  double get speed => _speed;

  void initializePosition(Offset pointerPosition) {
    if (position.dx == 0 && position.dy == 0) {
      _position = pointerPosition;
    }
  }

  void setSpeedAndAngle(Offset pointerPosition) {
    _speed = sqrt(pow((position.dx - pointerPosition.dx).abs(), 2) + pow((position.dy - pointerPosition.dy).abs(), 2));
    _angle = atan((pointerPosition.dy - position.dy) / (pointerPosition.dx - position.dx));
  }

  void updatePositionAndSpeed(Offset pointerPosition) {
    _position = Offset(position.dx + cos(_angle), position.dy + sin(_angle));
    setSpeedAndAngle(pointerPosition);
  }
}

enum LengthyProcess {
  unknown,
  ongoing,
  done,
  failed,
}

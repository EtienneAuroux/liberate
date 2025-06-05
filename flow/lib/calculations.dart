import 'dart:math';
import 'dart:ui';

import 'package:flow/types.dart';

class Calculations {
  static double dampenZoom(double scale, {int dampingFactor = 10}) {
    if (scale >= 1) {
      double increase = scale - 1;
      return 1 + increase / dampingFactor;
    } else if (scale > 0) {
      double decrease = 1 - scale;
      return 1 - decrease / dampingFactor;
    } else {
      return 1;
    }
  }

  static bool blockAndCircleIntersection(Block block, CircularObject circle) {
    double distanceX = (block.position.dx + block.width / 2 - circle.position.dx).abs();
    double distanceY = (block.position.dy + block.height / 2 - circle.position.dy).abs();

    if (distanceX > block.width / 2 + circle.hitBoxRadius || distanceY > block.height / 2 + circle.hitBoxRadius) {
      return false;
    }
    if (distanceX <= block.width / 2 || distanceY <= block.height / 2) {
      return true;
    }
    double distanceToCornerSquared = pow(distanceX - block.width / 2, 2) + pow(distanceY - block.height / 2, 2) + 0.0;
    if (distanceToCornerSquared <= pow(circle.hitBoxRadius, 2)) {
      return true;
    }
    return false;
  }

  static Offset circleToBlockVector(Block block, CircularObject circle) {
    double dx = 0, dy = 0;
    if (block.position.dx > circle.position.dx + circle.hitBoxRadius) {
      dx = block.position.dx - (circle.position.dx + circle.hitBoxRadius);
    } else if (block.position.dx + block.width < circle.position.dx - circle.hitBoxRadius) {
      dx = block.position.dx + block.width - (circle.position.dx - circle.hitBoxRadius);
    }
    if (block.position.dy > circle.position.dy + circle.hitBoxRadius) {
      dy = block.position.dy - (circle.position.dy + circle.hitBoxRadius);
    } else if (block.position.dy + block.height < circle.position.dy - circle.hitBoxRadius) {
      dy = block.position.dy + block.height - (circle.position.dy - circle.hitBoxRadius);
    }
    return Offset(dx, dy);
  }

  static bool laserAndCircleIntersection(Laser laser, CircularObject circle) {
    if (laser.startPosition.dx == laser.endPosition.dx) {
      if ((laser.startPosition.dx - circle.position.dx).abs() <= laser.thickness / 2 + circle.hitBoxRadius) {
        return true;
      }
    } else {
      if ((laser.startPosition.dy - circle.position.dy).abs() <= laser.thickness / 2 + circle.hitBoxRadius) {
        return true;
      }
    }
    return false;
  }

  static String millisecondsToTime(int milliseconds) {
    int ms = milliseconds % 1000;
    int seconds = milliseconds ~/ 1000;
    int minutes = milliseconds ~/ (60 * 1000);
    int hours = milliseconds ~/ (60 * 60 * 1000);

    return '${'$hours'.padLeft(2, '0')}:${'$minutes'.padLeft(2, '0')}:${'$seconds'.padLeft(2, '0')}.$ms';
  }
}

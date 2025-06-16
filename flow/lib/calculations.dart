import 'dart:math';
import 'dart:ui';

import 'package:flow/types.dart';

/// A class with static methods with no side effects.
///
/// Contains the following methods:
/// - [blockAndCircleOverlap]
/// - [circleToBlockVector]
/// - [laserAndCircleOverlap]
/// - [millisecondsToTime]
class Calculations {
  /// Compares the position of a [Block] with that of a [CircularObject] and
  /// determines if any part of the [Block] overlaps with any part of the [CircularObject].
  ///
  /// Returns true if there is an overlap, false otherwise.
  static bool blockAndCircleOverlap(Block block, CircularObject circle) {
    double distanceX = (block.position.dx + block.width / 2 - circle.centerPosition.dx).abs();
    double distanceY = (block.position.dy + block.height / 2 - circle.centerPosition.dy).abs();

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

  /// Calculate the smallest distance between a [Block] and a [CircularObject].
  ///
  /// The distance is returned as an [Offset].
  static Offset circleToBlockVector(Block block, CircularObject circle) {
    double dx = 0, dy = 0;
    if (block.position.dx > circle.centerPosition.dx + circle.hitBoxRadius) {
      dx = block.position.dx - (circle.centerPosition.dx + circle.hitBoxRadius);
    } else if (block.position.dx + block.width < circle.centerPosition.dx - circle.hitBoxRadius) {
      dx = block.position.dx + block.width - (circle.centerPosition.dx - circle.hitBoxRadius);
    }
    if (block.position.dy > circle.centerPosition.dy + circle.hitBoxRadius) {
      dy = block.position.dy - (circle.centerPosition.dy + circle.hitBoxRadius);
    } else if (block.position.dy + block.height < circle.centerPosition.dy - circle.hitBoxRadius) {
      dy = block.position.dy + block.height - (circle.centerPosition.dy - circle.hitBoxRadius);
    }
    return Offset(dx, dy);
  }

  /// Compares the position of a [Laser] with that of a [CircularObject] and
  /// determines if any part of the [Laser] overlaps with any part of the [CircularObject].
  ///
  /// Returns true if there is an overlap, false otherwise.
  static bool laserAndCircleOverlap(Laser laser, CircularObject circle) {
    if (laser.startPosition.dx == laser.endPosition.dx) {
      if ((laser.startPosition.dx - circle.centerPosition.dx).abs() <= laser.thickness / 2 + circle.hitBoxRadius) {
        return true;
      }
    } else {
      if ((laser.startPosition.dy - circle.centerPosition.dy).abs() <= laser.thickness / 2 + circle.hitBoxRadius) {
        return true;
      }
    }
    return false;
  }

  /// Converts [milliseconds] to a [String] with the hh:mm:ss.sss format.
  ///
  /// We are not interested in times larger than a day.
  static String millisecondsToTime(int milliseconds) {
    int ms = milliseconds % 1000;
    int seconds = (milliseconds ~/ 1000) % 60;
    int minutes = (milliseconds ~/ (60 * 1000)) % 60;
    int hours = milliseconds ~/ (60 * 60 * 1000);

    return '${'$hours'.padLeft(2, '0')}:${'$minutes'.padLeft(2, '0')}:${'$seconds'.padLeft(2, '0')}.$ms';
  }
}

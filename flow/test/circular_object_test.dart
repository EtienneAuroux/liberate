import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:flow/types.dart';

void main() {
  group('CircularObject class', () {
    test('CircularObject initialization', () {
      final CircularObject circularObject = CircularObject(const Offset(150, 200), 30);

      expect(circularObject.centerPosition, const Offset(150, 200));
      expect(circularObject.hitBoxRadius, 30);
    });
  });

  group('Enemy class', () {
    test('Enemy position update', () {
      final Enemy enemy = Enemy(const Offset(100, 100), 20, pi / 4, 15);
      final Offset initialPosition = enemy.centerPosition;

      enemy.updatePosition();

      expect(enemy.centerPosition.dx, isNot(equals(initialPosition.dx)));
      expect(enemy.centerPosition.dy, isNot(equals(initialPosition.dy)));
    });

    test('Enemy bounce', () {
      final Enemy enemy = Enemy(const Offset(100, 100), 20, pi / 4, 15);
      final double initialSpeed = enemy.speed;
      final double initialAngle = enemy.angle;

      enemy.bounce(1.5);

      expect(enemy.speed, initialSpeed * 1.5);
      expect(enemy.angle, equals(initialAngle + pi));
    });

    test('Enemy bounce with no speed update', () {
      final Enemy enemy = Enemy(const Offset(100, 100), 20, pi / 4, 15);
      final double initialSpeed = enemy.speed;
      final double initialAngle = enemy.angle;

      enemy.bounce(0.5);

      expect(enemy.angle, initialAngle + pi);
      expect(enemy.speed, initialSpeed);
    });

    test('Shift position', () {
      final Enemy enemy = Enemy(const Offset(100, 100), 20, pi / 4, 15);
      final Offset initialPosition = enemy.centerPosition;
      const Offset shift = Offset(50, 50);
      const Offset pointerPosition = Offset(300, 400);

      final double expectedAngle = atan2((pointerPosition.dy - initialPosition.dy), (pointerPosition.dx - initialPosition.dx));
      enemy.shiftPosition(shift, pointerPosition);

      expect(enemy.centerPosition, equals(initialPosition + shift));
      expect(enemy.angle, closeTo(expectedAngle, 1e-9));
    });
  });
}

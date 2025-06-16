import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:flow/calculations.dart';
import 'package:flow/types.dart';

void main() {
  group('Calculations.blockAndCircleOverlap', () {
    final Block block = Block(20, 20, const Offset(10, 10));

    test('Overlap when circle center is inside block', () {
      final CircularObject circle = CircularObject(const Offset(15, 15), 5);

      bool overlap = Calculations.blockAndCircleOverlap(block, circle);

      expect(overlap, isTrue);
    });

    test('No overlap when circle is far outside block', () {
      final CircularObject circle = CircularObject(const Offset(100, 100), 5);

      bool overlap = Calculations.blockAndCircleOverlap(block, circle);

      expect(overlap, isFalse);
    });

    test('Edge overlap when circle just touches block corner', () {
      final CircularObject circle = CircularObject(const Offset(35, 35), sqrt(50));

      bool overlap = Calculations.blockAndCircleOverlap(block, circle);

      expect(overlap, isTrue);
    });

    test('Overlap when circle is partially outside block', () {
      final CircularObject circle = CircularObject(const Offset(25, 15), 5);

      bool overlap = Calculations.blockAndCircleOverlap(block, circle);

      expect(overlap, isTrue);
    });
  });

  group('Calculations.circleToBlockVector', () {
    final Block block = Block(20, 20, const Offset(10, 10));

    test('Vector is zero when circle overlaps block', () {
      final CircularObject circle = CircularObject(const Offset(15, 15), 5);

      final Offset vector = Calculations.circleToBlockVector(block, circle);

      expect(vector, equals(const Offset(0, 0)));
    });

    test('Returns positive offset when circle is to left/top of block', () {
      final CircularObject circle = CircularObject(const Offset(0, 0), 2);

      final Offset vector = Calculations.circleToBlockVector(block, circle);

      expect(vector.dx > 0, isTrue);
      expect(vector.dy > 0, isTrue);
    });

    test('Returns offset when circle is on the right/bottom of block', () {
      final CircularObject circle = CircularObject(const Offset(40, 40), 5);

      final Offset vector = Calculations.circleToBlockVector(block, circle);
      expect(vector.dx < 0, isTrue);
      expect(vector.dy < 0, isTrue);
    });
  });

  group('Calculations.laserAndCircleOverlap', () {
    test('Vertical laser overlaps circle', () {
      final Laser laser = Laser(const Offset(10, 0), const Offset(10, 100));
      final CircularObject circle = CircularObject(const Offset(12, 50), 3);

      bool overlap = Calculations.laserAndCircleOverlap(laser, circle);

      expect(overlap, isTrue);
    });

    test('Horizontal laser does not overlap circle', () {
      final Laser laser = Laser(const Offset(0, 10), const Offset(100, 10));
      final CircularObject circle = CircularObject(const Offset(50, 20), 3);

      bool overlap = Calculations.laserAndCircleOverlap(laser, circle);

      expect(overlap, isFalse);
    });

    test('Vertical laser and circle are aligned but no overlap', () {
      final Laser laser = Laser(const Offset(10, 0), const Offset(10, 100));
      final CircularObject circle = CircularObject(const Offset(25, 50), 3);

      bool overlap = Calculations.laserAndCircleOverlap(laser, circle);

      expect(overlap, isFalse);
    });
  });

  group('Calculations.millisecondsToTime', () {
    test('Converts zero milliseconds correctly', () {
      String zeroMilliseconds = Calculations.millisecondsToTime(0);

      expect(zeroMilliseconds, '00:00:00.0');
    });

    test('Formats full time correctly', () {
      String convertedMilliseconds = Calculations.millisecondsToTime(5025678);

      expect(convertedMilliseconds, '01:23:45.678');
    });

    test('Converts at the one hour boundary correctly', () {
      String oneHourMinusOneMilliseconds = Calculations.millisecondsToTime(3599999);

      expect(oneHourMinusOneMilliseconds, '00:59:59.999');
    });

    test('Handles large time values correctly', () {
      String largeMilliseconds = Calculations.millisecondsToTime(99999999);

      expect(largeMilliseconds, '27:46:39.999');
    });
  });
}

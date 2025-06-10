import 'package:flutter/material.dart';

/// A class with design elements such as [TextStyle] and [Paint] stored as static objects.
class Design {
  static const TextStyle pointCounterStyle = TextStyle(
    fontFamily: 'Roboto',
    fontSize: 40,
    fontWeight: FontWeight.normal,
    color: Colors.red,
    decoration: TextDecoration.none,
  );

  static const TextStyle shiftStyle = TextStyle(
    fontFamily: 'Roboto',
    fontSize: 40,
    fontWeight: FontWeight.normal,
    color: Colors.red,
    decoration: TextDecoration.none,
  );

  static const TextStyle announcementStyle = TextStyle(
    fontFamily: 'Roboto',
    fontSize: 80,
    fontWeight: FontWeight.normal,
    color: Colors.red,
    decoration: TextDecoration.none,
  );

  static final Paint playerPaint = Paint()
    ..color = Colors.red
    ..style = PaintingStyle.fill;

  static final Paint targetPaint = Paint()
    ..color = Colors.green
    ..style = PaintingStyle.fill;

  static final Paint enemyPaint = Paint()
    ..color = Colors.grey
    ..style = PaintingStyle.fill;

  static final Paint blockPaint = Paint()
    ..color = Colors.blue
    ..style = PaintingStyle.fill;

  static final Paint bouncingBLockPaint = Paint()
    ..color = Colors.orange
    ..style = PaintingStyle.fill;
}

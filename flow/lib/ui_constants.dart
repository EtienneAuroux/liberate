import 'package:flutter/material.dart';

class UIConstants {
  static const String gameStart = 'THIS GAME HAS AN END\n';
  static const String gameStartHint = '(Right click to start)';
  static const String gameOver = 'GAME OVER\n';
  static const String gameWon = 'CONGRATULATIONS!\n';

  static const String powerOn = 'POWER ON';
  static const String powerReady = 'READY (left click)';
  static const String powerIn = 'POWER IN';

  static const double textHorizontalMargin = 40;
  static const double textVerticalMargin = 20;

  static const Color lightBlue = Color.fromARGB(255, 173, 216, 230);
  static const Color neonBlue = Color.fromARGB(255, 0, 255, 255);
  static const Color darkBlue = Color.fromARGB(255, 0, 0, 139);
  static const Color neonGreen = Color.fromARGB(255, 57, 255, 20);
  static const Color darkGreen = Color.fromARGB(255, 0, 100, 0);
  static const Color purple = Color.fromARGB(255, 128, 0, 128);
  static const Color neonPurple = Color.fromARGB(255, 163, 73, 164);
  static const Color gray = Color.fromARGB(255, 169, 169, 169);
  static const Color lightGray = Color.fromARGB(255, 211, 211, 211);
  static const Color darkRed = Color.fromARGB(255, 139, 0, 0);
  static const Color brown = Color.fromARGB(255, 139, 69, 19);
  static const Color orange = Color.fromARGB(255, 255, 165, 0);
  static const Color brightOrange = Color.fromARGB(255, 255, 140, 0);
  static const Color neonOrange = Color.fromARGB(255, 255, 165, 0);
  static const Color neonYellow = Color.fromARGB(255, 255, 255, 0);
  static const Color brightYellow = Color.fromARGB(255, 255, 255, 102);
  static const Color gold = Color.fromARGB(255, 255, 215, 0);
  static const Color cyan = Color.fromARGB(255, 0, 255, 255);
  static const Color pink = Color.fromARGB(255, 255, 105, 180);
  static const Color electricPink = Color.fromARGB(255, 255, 20, 147);
  static const Color magenta = Color.fromARGB(255, 255, 0, 255);

  static const TextStyle pointCounterStyle = TextStyle(
    fontFamily: 'ProtestGuerrilla',
    fontSize: 40,
    color: Colors.red,
    decoration: TextDecoration.none,
  );

  static const TextStyle shiftStyle = TextStyle(
    fontFamily: 'ProtestGuerrilla',
    fontSize: 40,
    color: Colors.red,
    decoration: TextDecoration.none,
  );

  static const TextStyle announcementStyle = TextStyle(
    fontFamily: 'ProtestGuerrilla',
    fontSize: 80,
    color: Colors.red,
    decoration: TextDecoration.none,
  );

  static const TextStyle subAnnouncementStyle = TextStyle(
    fontFamily: 'ProtestGuerrilla',
    fontSize: 40,
    color: Colors.red,
    decoration: TextDecoration.none,
  );

  static final Paint playerPaint = Paint()
    ..color = Colors.white
    ..style = PaintingStyle.fill;
  static final Paint playerArrowPaint = Paint()
    ..color = Colors.black
    ..style = PaintingStyle.fill;

  static final Paint targetPaint = Paint()
    ..color = darkGreen
    ..style = PaintingStyle.fill;
  static final Paint targetCorePaint = Paint()
    ..color = gold
    ..style = PaintingStyle.fill;

  static final Paint enemyPaint = Paint()
    ..color = Colors.red
    ..style = PaintingStyle.fill;
  static final Paint enemyArrowPaint = Paint()
    ..color = Colors.blue
    ..style = PaintingStyle.fill;

  static final Paint blockPaint = Paint()
    ..color = gray
    ..style = PaintingStyle.fill;
  static final Paint blockBorderPaint = Paint()
    ..color = brown
    ..style = PaintingStyle.stroke
    ..strokeWidth = 4;
  static final Paint bouncingBlockBorderPaint = Paint()
    ..color = darkBlue
    ..style = PaintingStyle.stroke
    ..strokeWidth = 4;

  static final Paint laserPaint = Paint()
    ..color = neonPurple
    ..style = PaintingStyle.fill;
}

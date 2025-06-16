import 'package:flutter_test/flutter_test.dart';
import 'package:flow/types.dart';

void main() {
  group('Player class', () {
    test('Initialize position', () {
      final Player player = Player();
      const Offset initialPosition = Offset(100, 200);

      player.initializePosition(initialPosition);

      expect(player.centerPosition, initialPosition);
      expect(player.alive, true);
      expect(player.points, 0);
    });

    test('Update position and speed', () {
      final Player player = Player();
      const Offset initialPosition = Offset(100, 200);
      const Offset pointerPosition = Offset(300, 400);
      const Offset bounds = Offset(500, 500);
      final List<Block> blocks = <Block>[];

      player.initializePosition(initialPosition);
      player.setAngle(pointerPosition);
      player.updatePositionAndSpeed(pointerPosition, bounds, blocks);

      // Validate the player position is updated
      expect(player.centerPosition.dx, isNot(equals(initialPosition.dx)));
      expect(player.centerPosition.dy, isNot(equals(initialPosition.dy)));
    });

    test('Update position and speed when the player meets a block', () {
      final Player player = Player();
      const Offset initialPosition = Offset(100, 200);
      const Offset pointerPosition = Offset(300, 400);
      const Offset bounds = Offset(500, 500);
      final List<Block> blocks = <Block>[
        Block(50, 50, const Offset(200, 300)),
      ];

      player.initializePosition(initialPosition);

      final Offset initialPlayerPosition = player.centerPosition;

      player.setAngle(pointerPosition);
      player.updatePositionAndSpeed(pointerPosition, bounds, blocks);

      expect(player.centerPosition.dx, isNot(equals(initialPlayerPosition.dx)));
      expect(player.centerPosition.dy, isNot(equals(initialPlayerPosition.dy)));
      expect(player.centerPosition.dx, lessThanOrEqualTo(blocks[0].position.dx + blocks[0].width));
      expect(player.centerPosition.dy, lessThanOrEqualTo(blocks[0].position.dy + blocks[0].height));
    });

    test('Set angle', () {
      final Player player = Player();
      const Offset pointerPosition = Offset(300, 400);
      const Offset initialPosition = Offset(100, 200);

      player.initializePosition(initialPosition);
      player.setAngle(pointerPosition);

      player.updatePositionAndSpeed(pointerPosition, const Offset(500, 500), []);

      expect(player.centerPosition.dx, isNot(equals(initialPosition.dx)));
      expect(player.centerPosition.dy, isNot(equals(initialPosition.dy)));
    });

    test('Player death', () {
      final player = Player();
      const Offset initialPosition = Offset(100, 200);

      player.initializePosition(initialPosition);
      player.death();

      expect(player.alive, false);
      expect(player.centerPosition, Offset.zero);
    });
  });
}

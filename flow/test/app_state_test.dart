import 'package:flow/app_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flow/types.dart';

void main() {
  group('Game state', () {
    test('Initialization of player and targets', () {
      Offset pointerPosition = const Offset(100, 200);

      AppState.initializeGameState(pointerPosition);

      expect(AppState.player.centerPosition, pointerPosition);
      expect(AppState.targets.length, 3);
    });

    test('Create enemies, blocks, and lasers based on Player\'s points', () {
      Offset pointerPosition = const Offset(100, 200);
      AppState.initializeGameState(pointerPosition);

      expect(AppState.enemies.isEmpty, true);
      expect(AppState.blocks.isEmpty, true);
      expect(AppState.lasers.isEmpty, true);

      AppState.player.points = 10;
      AppState.updateGameState();

      expect(AppState.enemies.length, 1);
      expect(AppState.blocks.isEmpty, true);
      expect(AppState.lasers.isEmpty, true);

      AppState.player.points += 20;
      AppState.updateGameState();

      expect(AppState.enemies.length, 5);
      expect(AppState.blocks.length, 1);
      expect(AppState.lasers.isEmpty, true);
    });

    test('Player fulfills victory condition', () {
      Offset pointerPosition = const Offset(100, 200);
      AppState.initializeGameState(pointerPosition);

      AppState.enemies.add(Enemy(const Offset(300, 400), 20, 0, 10));
      AppState.blocks.add(Block(100, 20, const Offset(500, 500)));
      AppState.lasers.add(Laser(const Offset(1000, 0), const Offset(1000, 1000)));

      AppState.player.points = AppState.winningCondition;
      AppState.updateGameState();

      expect(AppState.player.alive, false);
      expect(AppState.enemies.isEmpty, true);
      expect(AppState.blocks.isEmpty, true);
      expect(AppState.lasers.isEmpty, true);
    });
  });
}

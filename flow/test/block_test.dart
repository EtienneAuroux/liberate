import 'package:flutter_test/flutter_test.dart';
import 'package:flow/types.dart';

void main() {
  group('Block class', () {
    test('Block initialization', () {
      final Block block = Block(100, 50, const Offset(10, 20));

      expect(block.width, 100);
      expect(block.height, 50);
      expect(block.position, const Offset(10, 20));
    });
  });

  group('BouncingBlock class', () {
    test('BouncingBlock initialization with valid chock value', () {
      final bouncingBlock = BouncingBlock(100, 50, const Offset(10, 20), 1.5);

      expect(bouncingBlock.width, 100);
      expect(bouncingBlock.height, 50);
      expect(bouncingBlock.position, const Offset(10, 20));
      expect(bouncingBlock.chock, 1.5);
    });

    test('BouncingBlock initialization with invalid chock value', () {
      expect(() => BouncingBlock(100, 50, const Offset(10, 20), 2.5), throwsAssertionError);
      expect(() => BouncingBlock(100, 50, const Offset(10, 20), 0), throwsAssertionError);
    });
  });
}

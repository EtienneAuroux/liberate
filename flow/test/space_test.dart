import 'package:flow/conversions.dart';
import 'package:flow/space.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test/test.dart' as test;

void main() {
  testWidgets('C-layer integration test', (WidgetTester tester) async {
    await tester.pumpWidget(const Space());

    await tester.drag(find.byWidget(const SpaceWidget()), const Offset(500, 300));
    await tester.pump();
  });

  group('Zoom dampening factor calculation', () {
    Conversions conversions = Conversions();
    test.test('Edge case, scale = 0', () {
      double dampenedZoom = conversions.dampenZoom(0);

      expect(dampenedZoom, 1);
    });

    test.test('Rest case, scale = 1', () {
      double dampenedZoom = conversions.dampenZoom(1);

      expect(dampenedZoom, 1);
    });

    test.test('Zoom case, scale > 1', () {
      double dampenedZoom = conversions.dampenZoom(11);

      expect(dampenedZoom, 2);
    });

    test.test('Unzoom case, 0 < scale < 1', () {
      double dampenedZoom = conversions.dampenZoom(0.5);

      expect(dampenedZoom, 0.95);
    });
  });
}

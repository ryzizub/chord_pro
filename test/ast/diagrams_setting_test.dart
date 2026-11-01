import 'package:chord_pro/chord_pro.dart';
import 'package:test/test.dart';

void main() {
  group('DiagramsSetting.toString', () {
    test('names the flag and the position', () {
      expect(
        DiagramsSetting.fromValue('top').toString(),
        'DiagramsSetting(enabled: true, position: top)',
      );
    });

    test('shows a null position when only the flag was set', () {
      expect(
        DiagramsSetting.fromValue('off').toString(),
        'DiagramsSetting(enabled: false, position: null)',
      );
    });
  });
}

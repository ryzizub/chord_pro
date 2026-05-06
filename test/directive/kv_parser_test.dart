import 'package:chord_pro/src/directive/kv_parser.dart';
import 'package:test/test.dart';

void main() {
  group('parseKv', () {
    test('plain key=value pairs', () {
      expect(parseKv('a=1 b=2'), {'a': '1', 'b': '2'});
    });

    test('quoted value preserves whitespace', () {
      expect(parseKv('label="My Label" id=x'), {
        'label': 'My Label',
        'id': 'x',
      });
    });

    test('single-quoted value with escape', () {
      expect(parseKv(r"label='it\'s nice'"), {'label': "it's nice"});
    });

    test('bare attribute -> empty value', () {
      expect(parseKv('persist label="X"'), {'persist': '', 'label': 'X'});
    });

    test('lowercases keys', () {
      expect(parseKv('Foo=bar BAZ=qux'), {'foo': 'bar', 'baz': 'qux'});
    });
  });

  group('parseKv with defaultKey', () {
    test('bare leading value goes to defaultKey', () {
      expect(parseKv('Verse 1', defaultKey: 'label'), {'label': 'Verse 1'});
    });

    test('bare leading value coexists with explicit attrs', () {
      expect(
        parseKv('Verse 1 cc=mychorus', defaultKey: 'label'),
        {'label': 'Verse 1', 'cc': 'mychorus'},
      );
    });

    test('explicit label= takes precedence over bare default', () {
      // Spec: explicit `label="X"` wins; the bare prefix is not present.
      expect(
        parseKv('label="Final"', defaultKey: 'label'),
        {'label': 'Final'},
      );
    });

    test('quoted bare default preserves whitespace', () {
      expect(
        parseKv('"Final Chorus" extra=1', defaultKey: 'label'),
        {'label': 'Final Chorus', 'extra': '1'},
      );
    });

    test('shape default key for grid 4x4 form', () {
      expect(parseKv('4x4', defaultKey: 'shape'), {'shape': '4x4'});
    });
  });
}

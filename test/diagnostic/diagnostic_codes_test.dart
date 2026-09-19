import 'package:chord_pro/chord_pro.dart';
import 'package:test/test.dart';

List<DiagnosticCode> _codes(String source, {bool strict = false}) =>
    ChordPro.parse(source, strict: strict)
        .diagnostics
        .map((d) => d.code)
        .toList();

void main() {
  group('diagnostics carry a code for every condition the parser reports', () {
    test('unterminated section', () {
      expect(
        _codes('{start_of_chorus}\n[C]hi\n'),
        [DiagnosticCode.unterminatedSection],
      );
    });

    test('nested section is auto-closed', () {
      expect(
        _codes('{start_of_verse}\na\n{start_of_chorus}\nb\n{end_of_chorus}'),
        [DiagnosticCode.nestedSection],
      );
    });

    test('stray end directive', () {
      expect(_codes('[C]hi\n{end_of_chorus}'), [DiagnosticCode.strayEnd]);
    });

    test('mismatched end directive', () {
      expect(
        _codes('{start_of_verse}\na\n{end_of_chorus}'),
        [DiagnosticCode.mismatchedEnd],
      );
    });

    test('empty and malformed {image}', () {
      expect(_codes('{image}'), [DiagnosticCode.emptyImage]);
      expect(_codes('{image:}'), [DiagnosticCode.emptyImage]);
      // `{image: ""}` names nothing, so it is malformed rather than an
      // image with no source.
      expect(_codes('{image: ""}'), [DiagnosticCode.malformedImage]);
    });

    test('malformed {define} / {chord}', () {
      expect(
        _codes('{define: ""}'),
        [DiagnosticCode.malformedChordDefinition],
      );
      expect(
        _codes('{chord: []}'),
        [DiagnosticCode.malformedChordDefinition],
      );
      // A body that names a chord is fine, however sparse.
      expect(_codes('{define: G}'), isEmpty);
    });

    test('empty {meta}', () {
      expect(_codes('{meta}'), [DiagnosticCode.emptyMeta]);
      expect(_codes('{meta:}'), [DiagnosticCode.emptyMeta]);
    });

    test('a numeric metadata directive given a non-number', () {
      final result = ChordPro.parse('{capo: high}\n{year: MCMXCIX}\n'
          '{tempo: fast}\n{columns: many}\n{transpose: up}');
      expect(
        result.diagnostics.map((d) => d.code),
        everyElement(DiagnosticCode.invalidNumericValue),
      );
      expect(result.diagnostics, hasLength(5));
      // The message names the directive and the offending value.
      expect(result.diagnostics.first.message, contains('capo'));
      expect(result.diagnostics.first.message, contains('high'));
      // The span points at the directive, not at line 1 by default.
      expect(result.diagnostics[1].span.line, 2);
      // And the value is still dropped rather than guessed at.
      expect(result.songs.first.metadata.capo, isNull);
    });

    test('a chorus recall inside an open section', () {
      expect(
        _codes('{start_of_verse}\n[C]a\n{chorus}\n[G]b\n{end_of_verse}'),
        [DiagnosticCode.chorusRecallInsideSection],
      );
    });

    group('settings.strict', () {
      test('warns when the song declares no key', () {
        expect(_codes('{title: x}', strict: true), [DiagnosticCode.missingKey]);
      });

      test('a {meta: key …} declaration satisfies it', () {
        // The check reads the reduced metadata, so the `{meta}` form
        // counts exactly as `{key}` does.
        expect(_codes('{meta: key D}', strict: true), isEmpty);
        expect(_codes('{key: D}', strict: true), isEmpty);
      });

      test('the span points at the song that is missing the key', () {
        final result = ChordPro.parse(
          '{title: A}\n{key: C}\n{new_song}\n{title: B}\n',
          strict: true,
        );
        expect(result.diagnostics, hasLength(1));
        expect(result.diagnostics.single.code, DiagnosticCode.missingKey);
        // Line 4 is `{title: B}`, the second song's first directive —
        // not line 1, which belongs to the song that has a key.
        expect(result.diagnostics.single.span.line, 4);
      });
    });

    test('a clean song produces no diagnostics', () {
      expect(
        _codes('{title: x}\n{start_of_verse}\n[C]hi\n{end_of_verse}'),
        isEmpty,
      );
    });
  });
}

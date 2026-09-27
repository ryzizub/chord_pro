/// Enforces the direction of imports between the pipeline stages.
///
/// Each directory under `lib/src/` is one stage of the one-pass parser (see
/// the diagram in `CLAUDE.md`). A stage may import only stages below it, so
/// the lower stages stay independently testable and the dependency graph
/// stays a DAG apart from the one declared pair: `ast` and `diagnostic` form
/// the data model together (`Metadata` reports diagnostics, `ParseResult`
/// holds songs).
///
/// A new stage directory must be added to [_tiers] before it can be imported.
library;

import 'dart:io';

import 'package:test/test.dart';

/// Stage directory → tier. A file may import a stage of a lower tier, its
/// own stage, or a stage listed for it in [_sameTierPeers].
const _tiers = <String, int>{
  'util': 0,
  'source': 0,
  'chord': 1,
  'directive': 1,
  'inline': 2,
  'ast': 3,
  'diagnostic': 3,
  'assembler': 4,
  // `lib/src/chord_pro.dart`, the public entry point.
  'chord_pro.dart': 5,
};

/// Same-tier stages that may import each other.
const _sameTierPeers = <String, Set<String>>{
  'ast': {'diagnostic'},
  'diagnostic': {'ast'},
};

final _importPattern = RegExp(
  r'''^import\s+'(?:package:chord_pro/src/|((?:\.\./)+))([^']+)';''',
  multiLine: true,
);

void main() {
  final files = Directory('lib/src')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .toList();

  test('every file under lib/src belongs to a known stage', () {
    final unknown = files
        .map(_stageOf)
        .where((stage) => !_tiers.containsKey(stage))
        .toSet();
    expect(unknown, isEmpty, reason: 'add new stages to _tiers');
  });

  test('stages import only lower tiers', () {
    final violations = <String>[];
    for (final file in files) {
      final from = _stageOf(file);
      final fromTier = _tiers[from]!;
      for (final match in _importPattern.allMatches(file.readAsStringSync())) {
        // Relative imports that stay inside the stage directory do not
        // match the pattern; `../x/…` and `package:chord_pro/src/x/…` do.
        final to = match.group(2)!.split('/').first;
        if (to == from) continue;
        final toTier = _tiers[to];
        final allowed = toTier != null &&
            (toTier < fromTier ||
                (_sameTierPeers[from]?.contains(to) ?? false));
        if (!allowed) violations.add('${_rel(file)} imports $to');
      }
    }
    expect(violations, isEmpty);
  });

  test('src files never import the public barrel', () {
    final offenders = files
        .where(
          (f) => f.readAsStringSync().contains(
                "import 'package:chord_pro/chord_pro.dart'",
              ),
        )
        .map(_rel)
        .toList();
    expect(offenders, isEmpty);
  });
}

String _rel(File file) => file.path.replaceAll(r'\', '/');

String _stageOf(File file) {
  final parts = _rel(file).split('/');
  final i = parts.indexOf('src');
  return parts[i + 1];
}

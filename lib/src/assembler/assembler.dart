import 'package:chord_pro/src/ast/metadata.dart';
import 'package:chord_pro/src/ast/song.dart';
import 'package:chord_pro/src/diagnostic/diagnostic.dart';
import 'package:chord_pro/src/diagnostic/parse_result.dart';
import 'package:chord_pro/src/directive/directive.dart';
import 'package:chord_pro/src/directive/directive_parser.dart';
import 'package:chord_pro/src/source/scanner.dart';

/// Parses [source] into one or more [Song]s plus diagnostics.
ParseResult assemble(String source) {
  final lines = scan(source);
  final diagnostics = <Diagnostic>[];
  final songs = <Song>[];

  var pending = <Directive>[];

  void flushSong() {
    songs.add(
      Song(
        metadata: reduceMetadata(_expandMeta(pending, diagnostics)),
        directives: List.unmodifiable(pending),
      ),
    );
    pending = <Directive>[];
  }

  for (final line in lines) {
    final directive = parseDirectiveLine(line);
    if (directive == null) continue;

    if (directive.name == 'new_song' || directive.name == 'ns') {
      flushSong();
      continue;
    }
    pending.add(directive);
  }

  // Always emit at least one song, even for empty input, so callers can
  // treat `songs.first` as total.
  if (pending.isNotEmpty || songs.isEmpty) flushSong();

  return ParseResult(songs: songs, diagnostics: diagnostics);
}

/// Expands `{meta: key value}` directives into synthetic `{key: value}`
/// directives so [reduceMetadata] does not need to know about `meta`.
Iterable<Directive> _expandMeta(
  Iterable<Directive> directives,
  List<Diagnostic> diagnostics,
) sync* {
  for (final d in directives) {
    if (d.name != 'meta') {
      yield d;
      continue;
    }
    final value = d.value;
    if (value == null || value.isEmpty) {
      diagnostics.add(
        Diagnostic(
          severity: DiagnosticSeverity.warning,
          message: 'Empty {meta} directive.',
          span: d.span,
        ),
      );
      continue;
    }
    final space = _firstWhitespace(value);
    final String key;
    final String body;
    if (space < 0) {
      key = value;
      body = '';
    } else {
      key = value.substring(0, space);
      body = value.substring(space + 1).trimLeft();
    }
    if (key.isEmpty) {
      diagnostics.add(
        Diagnostic(
          severity: DiagnosticSeverity.warning,
          message: 'Malformed {meta} directive.',
          span: d.span,
        ),
      );
      continue;
    }
    yield Directive(
      name: key.toLowerCase(),
      selector: d.selector,
      polarity: d.polarity,
      value: body,
      span: d.span,
      fromMeta: true,
    );
  }
}

int _firstWhitespace(String s) {
  for (var i = 0; i < s.length; i++) {
    final ch = s.codeUnitAt(i);
    if (ch == 0x20 || ch == 0x09) return i;
  }
  return -1;
}

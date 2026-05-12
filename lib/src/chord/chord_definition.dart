import 'package:chord_pro/src/source/source_span.dart';

/// A parsed `{define}` or `{chord}` body.
///
/// The ChordPro spec for `{define}` is:
/// `Name [base-fret N] [frets P+] [fingers P+] [keys N+]
///       [copy NAME] [copyall NAME] [display NAME]
///       [format "FORMAT"] [diagram on|off|COLOUR]`
///
/// Per `lib/ChordPro/Song.pm:2483-2616`. Bracketed names (`[Name]`)
/// declare a transposable definition (ChordPro 6.100); the parser
/// discards any other attributes for those.
class ChordDefinition {
  /// Creates a new [ChordDefinition].
  const ChordDefinition({
    required this.name,
    required this.raw,
    required this.span,
    this.baseFret,
    this.frets = const [],
    this.fingers = const [],
    this.keys = const [],
    this.display,
    this.format,
    this.copy,
    this.copyall,
    this.diagram,
    this.isTransposable = false,
  });

  /// Chord name being defined (e.g. `G`, `Am/C`). For transposable
  /// definitions the surrounding `[...]` brackets are stripped.
  final String name;

  /// `base-fret N` — base fret offset (1-based); `null` if not given.
  final int? baseFret;

  /// `frets F+` — fret values, in string order. `null` means muted.
  ///
  /// Spec regex (`Song.pm:2528`): `^(?:-?[0-9]+|[-xXN])$`. Negative
  /// integers and the literal characters `-`, `x`, `X`, `N` are all
  /// normalised to `null`.
  final List<int?> frets;

  /// `fingers P+` — finger assignments in string order. Each entry is
  /// either an `int` (digit), a `String` (single letter `A–M`, `O–W`,
  /// `Y`, `Z` per spec), or `null` (muted: `-`, `x`, `X`, `N`).
  final List<Object?> fingers;

  /// `keys K+` — keyboard offsets relative to the root (e.g. `0 4 7`
  /// for a major triad). Added in ChordPro 0.979.
  final List<int> keys;

  /// `display NAME` — replacement chord name to render (5.989).
  final String? display;

  /// `format "FORMAT"` — printf-style format string with `%{...}`
  /// substitutions. Stored verbatim; the parser does not interpret
  /// the format string.
  final String? format;

  /// `copy NAME` — name of an existing definition to copy
  /// frets/fingers/keys/base-fret from.
  final String? copy;

  /// `copyall NAME` — like [copy] but also copies display + format.
  final String? copyall;

  /// `diagram on|off|COLOUR` — controls diagram visibility (6.010).
  final String? diagram;

  /// Whether the source name was bracketed (`[Name]`), making the
  /// definition transposable. Added in ChordPro 6.100.
  final bool isTransposable;

  /// Original directive value for round-tripping.
  final String raw;

  /// Span covering the original `{define}` / `{chord}` directive.
  final SourceSpan span;
}

final RegExp _fretRe = RegExp(r'^(?:-?\d+|[-xXN])$');
final RegExp _fingerNumericRe = RegExp(r'^\d+$');
final RegExp _fingerLetterRe = RegExp(r'^[A-MO-WYZ]$');
final RegExp _fingerMutedRe = RegExp(r'^[-xXN]$');

const Set<String> _keywords = {
  'base-fret',
  'base_fret',
  'frets',
  'fingers',
  'keys',
  'copy',
  'copyall',
  'display',
  'format',
  'diagram',
};

/// Parses a `{define}` / `{chord}` value body.
///
/// Returns `null` when the body is empty or has no name. Unknown
/// keywords are ignored rather than raising.
ChordDefinition? parseChordDefinition(
  String value, {
  required SourceSpan span,
}) {
  final tokens = _tokenize(value);
  if (tokens.isEmpty) return null;

  var name = tokens.first;
  var isTransposable = false;
  if (name.length >= 2 && name.startsWith('[') && name.endsWith(']')) {
    name = name.substring(1, name.length - 1);
    isTransposable = true;
  }

  if (isTransposable) {
    // Per spec, bracketed-name definitions cannot carry attributes.
    return ChordDefinition(
      name: name,
      raw: value,
      span: span,
      isTransposable: true,
    );
  }

  int? baseFret;
  final frets = <int?>[];
  final fingers = <Object?>[];
  final keys = <int>[];
  String? display;
  String? format;
  String? copy;
  String? copyall;
  String? diagram;

  for (var i = 1; i < tokens.length;) {
    final tok = tokens[i].toLowerCase();
    switch (tok) {
      case 'base-fret':
      case 'base_fret':
        if (i + 1 < tokens.length) {
          baseFret = int.tryParse(tokens[i + 1]);
          i += 2;
        } else {
          i++;
        }
      case 'frets':
        i++;
        while (
            i < tokens.length && !_keywords.contains(tokens[i].toLowerCase())) {
          frets.add(_parseFret(tokens[i]));
          i++;
        }
      case 'fingers':
        i++;
        while (
            i < tokens.length && !_keywords.contains(tokens[i].toLowerCase())) {
          fingers.add(_parseFinger(tokens[i]));
          i++;
        }
      case 'keys':
        i++;
        while (
            i < tokens.length && !_keywords.contains(tokens[i].toLowerCase())) {
          final n = int.tryParse(tokens[i]);
          if (n != null) keys.add(n);
          i++;
        }
      case 'display':
        if (i + 1 < tokens.length) {
          display = tokens[i + 1];
          i += 2;
        } else {
          i++;
        }
      case 'format':
        if (i + 1 < tokens.length) {
          format = tokens[i + 1];
          i += 2;
        } else {
          i++;
        }
      case 'copy':
        if (i + 1 < tokens.length) {
          copy = tokens[i + 1];
          i += 2;
        } else {
          i++;
        }
      case 'copyall':
        if (i + 1 < tokens.length) {
          copyall = tokens[i + 1];
          i += 2;
        } else {
          i++;
        }
      case 'diagram':
        if (i + 1 < tokens.length) {
          diagram = tokens[i + 1];
          i += 2;
        } else {
          i++;
        }
      default:
        i++;
    }
  }

  return ChordDefinition(
    name: name,
    baseFret: baseFret,
    frets: frets,
    fingers: fingers,
    keys: keys,
    display: display,
    format: format,
    copy: copy,
    copyall: copyall,
    diagram: diagram,
    isTransposable: isTransposable,
    raw: value,
    span: span,
  );
}

/// Splits [value] on whitespace, but keeps `"…"`-quoted strings as a
/// single token so `format "..."` survives.
List<String> _tokenize(String value) {
  final out = <String>[];
  var i = 0;
  while (i < value.length) {
    final c = value.codeUnitAt(i);
    if (c == 0x20 || c == 0x09) {
      i++;
      continue;
    }
    if (c == 0x22 || c == 0x27) {
      final quote = c;
      final start = i + 1;
      var j = start;
      while (j < value.length && value.codeUnitAt(j) != quote) {
        if (value.codeUnitAt(j) == 0x5C && j + 1 < value.length) {
          j += 2;
          continue;
        }
        j++;
      }
      out.add(value.substring(start, j));
      i = j < value.length ? j + 1 : j;
      continue;
    }
    final start = i;
    while (i < value.length) {
      final cc = value.codeUnitAt(i);
      if (cc == 0x20 || cc == 0x09) break;
      i++;
    }
    out.add(value.substring(start, i));
  }
  return out;
}

int? _parseFret(String s) {
  if (!_fretRe.hasMatch(s)) return null;
  if (s == '-' || s == 'x' || s == 'X' || s == 'N') return null;
  final n = int.tryParse(s);
  if (n == null || n < 0) return null;
  return n;
}

Object? _parseFinger(String s) {
  if (_fingerMutedRe.hasMatch(s)) return null;
  if (_fingerNumericRe.hasMatch(s)) return int.parse(s);
  if (_fingerLetterRe.hasMatch(s)) return s;
  return null;
}

import 'package:chord_pro/src/source/source_span.dart';
import 'package:chord_pro/src/util/equality.dart';

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
  /// Unmodifiable.
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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChordDefinition &&
          other.name == name &&
          other.baseFret == baseFret &&
          listEquals(other.frets, frets) &&
          listEquals(other.fingers, fingers) &&
          listEquals(other.keys, keys) &&
          other.display == display &&
          other.format == format &&
          other.copy == copy &&
          other.copyall == copyall &&
          other.diagram == diagram &&
          other.isTransposable == isTransposable &&
          other.raw == raw &&
          other.span == span;

  @override
  int get hashCode => Object.hash(
        name,
        baseFret,
        Object.hashAll(frets),
        Object.hashAll(fingers),
        Object.hashAll(keys),
        display,
        format,
        copy,
        copyall,
        diagram,
        isTransposable,
        raw,
        span,
      );
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

/// Keywords that take exactly one value, mapped to the key they are
/// collected under (`base_fret` is an alias of `base-fret`).
const Map<String, String> _singleValueKeywords = {
  'base-fret': 'base-fret',
  'base_fret': 'base-fret',
  'display': 'display',
  'format': 'format',
  'copy': 'copy',
  'copyall': 'copyall',
  'diagram': 'diagram',
};

/// Parses a `{define}` / `{chord}` value body.
///
/// Returns `null` when the body is empty or names no chord — `{define: ""}`
/// and `{define: []}` are malformed, not definitions of a chord called
/// "". Unknown keywords are ignored rather than raising.
ChordDefinition? parseChordDefinition(
  String value, {
  required SourceSpan span,
}) {
  final tokens = _tokenize(value);
  if (tokens.isEmpty) return null;

  final parsedName = _parseName(tokens.first);
  if (parsedName == null) return null;
  final name = parsedName.name;

  if (parsedName.isTransposable) {
    // Per spec, bracketed-name definitions cannot carry attributes.
    return ChordDefinition(
      name: name,
      raw: value,
      span: span,
      isTransposable: true,
    );
  }

  final singles = <String, String>{};
  final frets = <int?>[];
  final fingers = <Object?>[];
  final keys = <int>[];

  for (var i = 1; i < tokens.length;) {
    final tok = tokens[i].toLowerCase();
    final singleKey = _singleValueKeywords[tok];
    if (singleKey != null) {
      // A single-value keyword takes the next token, whatever it is; the
      // last repeat wins.
      if (i + 1 < tokens.length) {
        singles[singleKey] = tokens[i + 1];
        i += 2;
      } else {
        i++;
      }
      continue;
    }
    switch (tok) {
      case 'frets':
        final run = _valueRun(tokens, i + 1);
        frets.addAll(run.values.map(_parseFret));
        i = run.end;
      case 'fingers':
        final run = _valueRun(tokens, i + 1);
        fingers.addAll(run.values.map(_parseFinger));
        i = run.end;
      case 'keys':
        final run = _valueRun(tokens, i + 1);
        keys.addAll(run.values.map(int.tryParse).whereType<int>());
        i = run.end;
      default:
        i++;
    }
  }

  final baseFret = singles['base-fret'];
  return ChordDefinition(
    name: name,
    baseFret: baseFret == null ? null : int.tryParse(baseFret),
    frets: List.unmodifiable(frets),
    fingers: List.unmodifiable(fingers),
    keys: List.unmodifiable(keys),
    display: singles['display'],
    format: singles['format'],
    copy: singles['copy'],
    copyall: singles['copyall'],
    diagram: singles['diagram'],
    raw: value,
    span: span,
  );
}

/// Reads the chord name from [token], stripping `[...]` brackets that mark
/// a transposable definition. Returns `null` when the name is blank.
({String name, bool isTransposable})? _parseName(String token) {
  final isTransposable =
      token.length >= 2 && token.startsWith('[') && token.endsWith(']');
  final name = isTransposable ? token.substring(1, token.length - 1) : token;
  if (name.trim().isEmpty) return null;
  return (name: name, isTransposable: isTransposable);
}

/// Collects the tokens from [start] up to (not including) the next
/// keyword, and the index where that run ends.
({List<String> values, int end}) _valueRun(List<String> tokens, int start) {
  var end = start;
  while (
      end < tokens.length && !_keywords.contains(tokens[end].toLowerCase())) {
    end++;
  }
  return (values: tokens.sublist(start, end), end: end);
}

/// Splits [value] on whitespace, but keeps `"…"`-quoted strings as a
/// single token so `format "..."` survives.
List<String> _tokenize(String value) {
  final out = <String>[];
  var i = 0;
  while (i < value.length) {
    final c = value.codeUnitAt(i);
    if (_isBlank(c)) {
      i++;
      continue;
    }
    final read =
        (c == 0x22 || c == 0x27) ? _readQuoted(value, i) : _readBare(value, i);
    out.add(read.token);
    i = read.next;
  }
  return out;
}

bool _isBlank(int c) => c == 0x20 || c == 0x09;

/// Reads a quoted token whose opening quote is at [quoteAt]. Backslash
/// skips the next character; an unterminated quote runs to the end.
({String token, int next}) _readQuoted(String value, int quoteAt) {
  final quote = value.codeUnitAt(quoteAt);
  final start = quoteAt + 1;
  var j = start;
  while (j < value.length && value.codeUnitAt(j) != quote) {
    final escaped = value.codeUnitAt(j) == 0x5C && j + 1 < value.length;
    j += escaped ? 2 : 1;
  }
  return (
    token: value.substring(start, j),
    next: j < value.length ? j + 1 : j,
  );
}

/// Reads a whitespace-delimited token starting at [start].
({String token, int next}) _readBare(String value, int start) {
  var i = start;
  while (i < value.length && !_isBlank(value.codeUnitAt(i))) {
    i++;
  }
  return (token: value.substring(start, i), next: i);
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

import 'package:chord_pro/src/source/source_span.dart';

/// A parsed `{define}` or `{chord}` body.
///
/// The ChordPro spec for `{define}` is:
/// `Name base-fret N frets F1 F2 F3 F4 F5 F6 [fingers N1 N2 N3 N4 N5 N6]`
/// Unknown tokens are preserved in [raw] and surfaced via diagnostics.
class ChordDefinition {
  /// Creates a new [ChordDefinition].
  const ChordDefinition({
    required this.name,
    required this.raw,
    required this.span,
    this.baseFret,
    this.frets = const [],
    this.fingers = const [],
  });

  /// Chord name being defined (e.g. `G`, `Am/C`).
  final String name;

  /// Base fret offset (1-based); `null` if not specified.
  final int? baseFret;

  /// Fret values, in string order. `null` means muted (`x`).
  final List<int?> frets;

  /// Optional finger assignments per string. `null` means unassigned.
  final List<int?> fingers;

  /// Original directive value for round-tripping.
  final String raw;

  /// Span covering the original `{define}` / `{chord}` directive.
  final SourceSpan span;
}

final RegExp _whitespace = RegExp(r'\s+');

/// Parses a `{define}` / `{chord}` value body.
///
/// Returns `null` when the body is empty or has no name. Unknown
/// keywords are ignored rather than raising.
ChordDefinition? parseChordDefinition(
  String value, {
  required SourceSpan span,
}) {
  final tokens = value.split(_whitespace).where((t) => t.isNotEmpty).toList();
  if (tokens.isEmpty) return null;

  final name = tokens.first;
  int? baseFret;
  final frets = <int?>[];
  final fingers = <int?>[];

  for (var i = 1; i < tokens.length;) {
    final tok = tokens[i].toLowerCase();
    switch (tok) {
      case 'base-fret':
        if (i + 1 < tokens.length) {
          baseFret = int.tryParse(tokens[i + 1]);
          i += 2;
        } else {
          i++;
        }
      case 'frets':
        i++;
        while (i < tokens.length && !_isKeyword(tokens[i])) {
          frets.add(_parseFret(tokens[i]));
          i++;
        }
      case 'fingers':
        i++;
        while (i < tokens.length && !_isKeyword(tokens[i])) {
          fingers.add(_parseFret(tokens[i]));
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
    raw: value,
    span: span,
  );
}

bool _isKeyword(String s) {
  final l = s.toLowerCase();
  return l == 'base-fret' || l == 'frets' || l == 'fingers';
}

int? _parseFret(String s) {
  if (s == 'x' || s == 'X' || s == '-') return null;
  return int.tryParse(s);
}

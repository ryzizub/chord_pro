/// Which chord notation system a [Chord] is expressed in.
enum ChordSystem {
  /// Absolute letter chords: `C`, `Am`, `F#maj7`.
  letter,

  /// Nashville number system: `1`, `4m`, `b7`.
  nashville,

  /// Roman numeral system: `I`, `iv`, `V7`.
  roman,
}

/// How to spell a chromatic root note when transposing.
enum AccidentalPreference {
  /// Spell with sharps (`C#`, `D#`, `F#`, `G#`, `A#`).
  sharps,

  /// Spell with flats (`Db`, `Eb`, `Gb`, `Ab`, `Bb`).
  flats,
}

/// A parsed chord.
///
/// Chord parsing is intentionally forgiving: unrecognised input is
/// preserved verbatim on [raw] with [system] set to [ChordSystem.letter]
/// and [root] set to the whole string. Downstream stages should treat
/// `tryParse` as the source of truth and compare by [raw] when needed.
class Chord {
  /// Creates a new [Chord].
  const Chord({
    required this.system,
    required this.root,
    required this.raw,
    this.quality,
    this.extensions = const [],
    this.bass,
  });

  /// Notation system the chord is expressed in.
  final ChordSystem system;

  /// Root of the chord (e.g. `C`, `F#`, `1`, `IV`).
  final String root;

  /// Optional quality marker (`m`, `maj`, `dim`, `aug`, `sus2`, ...).
  final String? quality;

  /// Extensions after the quality (e.g. `7`, `b9`, `add11`).
  final List<String> extensions;

  /// Bass note for slash chords (e.g. `G/B` → bass root `B`).
  final Chord? bass;

  /// The original unparsed chord string.
  final String raw;

  /// Attempts to parse [raw].
  ///
  /// Returns `null` if [raw] is empty or starts with whitespace; never
  /// throws. Unknown bodies are captured via [root] + [raw] so callers
  /// can still display them.
  static Chord? tryParse(String raw) {
    if (raw.isEmpty) return null;
    if (_isWhitespace(raw.codeUnitAt(0))) return null;

    // No-chord (rest) marker.
    if (raw == 'NC' || raw == 'N.C.' || raw == 'N.C') {
      return Chord(system: ChordSystem.letter, root: raw, raw: raw);
    }

    // Split bass note on first unescaped '/'.
    final slash = raw.indexOf('/');
    final head = slash < 0 ? raw : raw.substring(0, slash);
    final tail = slash < 0 ? null : raw.substring(slash + 1);
    if (head.isEmpty) return null;

    final headParsed = _parseSimple(head);
    if (headParsed == null) return null;

    Chord? bass;
    if (tail != null && tail.isNotEmpty) {
      final parsedBass = _parseSimple(tail);
      if (parsedBass != null) {
        bass = Chord(
          system: parsedBass.system,
          root: parsedBass.root,
          quality: parsedBass.quality,
          extensions: parsedBass.extensions,
          raw: tail,
        );
      }
    }

    return Chord(
      system: headParsed.system,
      root: headParsed.root,
      quality: headParsed.quality,
      extensions: headParsed.extensions,
      bass: bass,
      raw: raw,
    );
  }

  /// Transposes the chord by [semitones].
  ///
  /// Letter chords are remapped through the chromatic scale; chords in
  /// other systems are returned unchanged because Nashville and Roman
  /// notation already abstract over key. Returns `this` when the root
  /// is unrecognised.
  Chord transpose(
    int semitones, {
    AccidentalPreference accidentals = AccidentalPreference.sharps,
  }) {
    if (system != ChordSystem.letter) return this;
    final newRoot = transposeRoot(root, semitones, accidentals: accidentals);
    if (newRoot == null) return this;
    final newBass = bass?.transpose(semitones, accidentals: accidentals);
    final raw = _renderLetter(newRoot, quality, extensions, newBass);
    return Chord(
      system: system,
      root: newRoot,
      quality: quality,
      extensions: extensions,
      bass: newBass,
      raw: raw,
    );
  }

  @override
  String toString() => raw;
}

/// Transposes a single root spelling such as `F#` or `Bb` by
/// [semitones], returning the transposed spelling or `null` when
/// [root] is not a recognised letter root. Unicode accidentals
/// (`♯`/`♭`) and German `H` (= B natural) are accepted on input.
String? transposeRoot(
  String root,
  int semitones, {
  AccidentalPreference accidentals = AccidentalPreference.sharps,
}) {
  final s = _rootToSemitone[_canonicaliseRoot(root)];
  if (s == null) return null;
  final shifted = (s + semitones) % 12;
  final positive = shifted < 0 ? shifted + 12 : shifted;
  return accidentals == AccidentalPreference.flats
      ? _semitoneToFlat[positive]
      : _semitoneToSharp[positive];
}

String _canonicaliseRoot(String root) {
  if (root.isEmpty) return root;
  // German H → B natural.
  final canonical = StringBuffer();
  for (var i = 0; i < root.length; i++) {
    final c = root.codeUnitAt(i);
    if (i == 0 && c == 0x48) {
      canonical.write('B');
    } else if (c == 0x266F) {
      canonical.write('#');
    } else if (c == 0x266D) {
      canonical.write('b');
    } else {
      canonical.writeCharCode(c);
    }
  }
  return canonical.toString();
}

String _renderLetter(
  String root,
  String? quality,
  List<String> extensions,
  Chord? bass,
) {
  final q = quality ?? '';
  final ext = extensions.join();
  final bassPart = bass == null ? '' : '/${bass.raw}';
  return '$root$q$ext$bassPart';
}

const Map<String, int> _rootToSemitone = {
  'C': 0,
  'C#': 1,
  'Db': 1,
  'D': 2,
  'D#': 3,
  'Eb': 3,
  'E': 4,
  'F': 5,
  'F#': 6,
  'Gb': 6,
  'G': 7,
  'G#': 8,
  'Ab': 8,
  'A': 9,
  'A#': 10,
  'Bb': 10,
  'B': 11,
};

const List<String> _semitoneToSharp = [
  'C', 'C#', 'D', 'D#', 'E', 'F', // 0..5
  'F#', 'G', 'G#', 'A', 'A#', 'B', // 6..11
];

const List<String> _semitoneToFlat = [
  'C', 'Db', 'D', 'Eb', 'E', 'F', // 0..5
  'Gb', 'G', 'Ab', 'A', 'Bb', 'B', // 6..11
];

class _Parsed {
  _Parsed(this.system, this.root, this.quality, this.extensions);
  final ChordSystem system;
  final String root;
  final String? quality;
  final List<String> extensions;
}

_Parsed? _parseSimple(String s) {
  final rootEnd = _rootEnd(s);
  if (rootEnd == 0) return null;
  final root = s.substring(0, rootEnd);
  final system = _systemFor(root);
  final rest = s.substring(rootEnd);

  String? quality;
  var cursor = 0;
  for (final q in _qualities) {
    if (rest.startsWith(q, cursor)) {
      quality = q;
      cursor += q.length;
      break;
    }
  }

  final extensions = <String>[];
  if (cursor < rest.length) {
    extensions.add(rest.substring(cursor));
  }

  return _Parsed(system, root, quality, extensions);
}

int _rootEnd(String s) {
  final c0 = s.codeUnitAt(0);
  // Letter (A-H) chord. H is German notation for B.
  if ((c0 >= 0x41 && c0 <= 0x47) || c0 == 0x48) {
    var i = 1;
    if (i < s.length && _isAccidental(s.codeUnitAt(i))) {
      i++;
    }
    return i;
  }
  // Nashville: optional accidental then digit 1..7.
  if (_isAccidental(c0)) {
    if (s.length >= 2 && _isNashvilleDigit(s.codeUnitAt(1))) return 2;
    return 0;
  }
  if (_isNashvilleDigit(c0)) return 1;
  // Roman: sequence of I/V upper- or lower-case.
  if (_isRomanChar(c0)) {
    var i = 1;
    while (i < s.length && _isRomanChar(s.codeUnitAt(i))) {
      i++;
    }
    return i;
  }
  return 0;
}

ChordSystem _systemFor(String root) {
  final c0 = root.codeUnitAt(0);
  if ((c0 >= 0x41 && c0 <= 0x47) || c0 == 0x48) return ChordSystem.letter;
  if (_isNashvilleDigit(c0) || _isAccidental(c0)) {
    return ChordSystem.nashville;
  }
  return ChordSystem.roman;
}

bool _isNashvilleDigit(int c) => c >= 0x31 && c <= 0x37; // 1..7

bool _isRomanChar(int c) =>
    c == 0x49 || c == 0x56 || c == 0x69 || c == 0x76; // I V i v

bool _isAccidental(int c) =>
    c == 0x23 || // '#'
    c == 0x62 || // 'b'
    c == 0x266D || // '♭'
    c == 0x266F; // '♯'

bool _isWhitespace(int c) => c == 0x20 || c == 0x09;

const List<String> _qualities = [
  'maj',
  'min',
  'mi',
  'sus2',
  'sus4',
  'sus',
  'aug',
  'dim',
  'add',
  'ø', // half-diminished
  '°', // diminished
  'm',
  '-',
];

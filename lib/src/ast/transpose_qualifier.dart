/// How a `{transpose}` directive should resolve enharmonic spellings.
///
/// The qualifier is the optional postfix character on the transpose
/// value, per the ChordPro reference parser
/// (`lib/ChordPro/Chords/Transpose.pm:114`):
/// `^([-+]?\d+)(?:([s#♯])|([fb♭])|([k]))?$`.
enum TransposeQualifier {
  /// No qualifier — direction is implied by the sign of the value.
  none,

  /// `s`, `#`, or `♯` — force sharp spellings on resolved roots.
  sharps,

  /// `f`, `b`, or `♭` — force flat spellings on resolved roots.
  flats,

  /// `k` — follow the song's `{key}` for enharmonic preference. Added
  /// in ChordPro 6.100 as part of the keys-and-transpositions rework.
  followKey,
}

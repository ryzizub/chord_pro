/// Horizontal alignment hint for the song's title block, set by the
/// `{titles}` directive.
///
/// Per `lib/ChordPro/Song.pm:2204`, the directive accepts the bare
/// values `left`, `right`, `center`, or the British spelling
/// `centre` (aliased to [center]). The directive is documented as
/// legacy/deprecated but still in active use.
enum TitlesAlignment {
  /// Flush titles to the left margin.
  left,

  /// Centre titles between the margins.
  center,

  /// Flush titles to the right margin.
  right,
}

/// Decodes the bare `{titles: …}` value into a [TitlesAlignment].
///
/// Returns `null` for unrecognised values. Matching is case-insensitive.
TitlesAlignment? parseTitlesAlignment(String value) {
  switch (value.trim().toLowerCase()) {
    case 'left':
      return TitlesAlignment.left;
    case 'center':
    case 'centre':
      return TitlesAlignment.center;
    case 'right':
      return TitlesAlignment.right;
    default:
      return null;
  }
}

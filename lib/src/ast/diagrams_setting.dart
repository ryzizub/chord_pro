/// Where chord diagrams should be rendered, set by the `{diagrams}`
/// directive.
///
/// Per `lib/ChordPro/Song.pm:2235-2247`:
/// `$arg =~ /^(right|bottom|top|below)$/i` — only those four positions
/// are typed. The default position is `bottom`.
enum DiagramsPosition {
  /// Render diagrams above the song body.
  top,

  /// Render diagrams below the song body (default).
  bottom,

  /// Render diagrams to the right of the song body.
  right,

  /// Render diagrams below each line as it appears.
  below,
}

/// Result of a `{diagrams}` (or `{g}`) directive.
///
/// The directive accepts a boolean (`on`/`off`/`1`/`0`/`true`/`false`)
/// and/or a position keyword. A position implicitly enables.
class DiagramsSetting {
  /// Creates a new [DiagramsSetting].
  const DiagramsSetting({required this.enabled, this.position});

  /// Decodes a `{diagrams}` value into a typed setting.
  ///
  /// `null`/empty → enabled (the bare directive form turns diagrams
  /// on). Position keywords also enable.
  factory DiagramsSetting.fromValue(String? value) {
    final v = value?.trim().toLowerCase() ?? '';
    if (v.isEmpty) {
      return const DiagramsSetting(enabled: true);
    }
    switch (v) {
      case 'on':
      case 'true':
      case '1':
      case 'yes':
        return const DiagramsSetting(enabled: true);
      case 'off':
      case 'false':
      case '0':
      case 'no':
        return const DiagramsSetting(enabled: false);
      case 'top':
        return const DiagramsSetting(
          enabled: true,
          position: DiagramsPosition.top,
        );
      case 'bottom':
        return const DiagramsSetting(
          enabled: true,
          position: DiagramsPosition.bottom,
        );
      case 'right':
        return const DiagramsSetting(
          enabled: true,
          position: DiagramsPosition.right,
        );
      case 'below':
        return const DiagramsSetting(
          enabled: true,
          position: DiagramsPosition.below,
        );
      default:
        // Unknown values fall back to enabled with no position so we
        // don't lose the directive entirely.
        return const DiagramsSetting(enabled: true);
    }
  }

  /// Whether chord diagrams should be rendered at all.
  final bool enabled;

  /// Where to render diagrams. `null` when the directive only flipped
  /// the on/off flag without specifying a position.
  final DiagramsPosition? position;
}

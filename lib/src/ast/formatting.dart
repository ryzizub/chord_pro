import 'package:chord_pro/src/directive/directive.dart';

/// Per-target font/size/colour overrides parsed from `{chordfont}` and
/// friends.
class FormattingProps {
  /// Creates a new [FormattingProps].
  const FormattingProps({this.font, this.size, this.colour});

  /// Font family.
  final String? font;

  /// Size; preserved as-is (e.g. `"12"`, `"120%"`, `"14pt"`).
  final String? size;

  /// Colour value; preserved as-is (e.g. `"red"`, `"#ff0000"`).
  final String? colour;

  /// Whether nothing has been set.
  bool get isEmpty => font == null && size == null && colour == null;

  FormattingProps _withFont(String? value) =>
      FormattingProps(font: value, size: size, colour: colour);

  FormattingProps _withSize(String? value) =>
      FormattingProps(font: font, size: value, colour: colour);

  FormattingProps _withColour(String? value) =>
      FormattingProps(font: font, size: size, colour: value);
}

/// Document-wide formatting settings collected from font/size/colour
/// directives such as `{chordfont}`, `{textsize}`, `{titlecolour}`.
class FormattingSettings {
  /// Creates a new [FormattingSettings].
  const FormattingSettings({this.byTarget = const {}});

  /// All declared overrides keyed by target (e.g. `chord`, `text`,
  /// `title`, `chorus`, …).
  final Map<String, FormattingProps> byTarget;

  /// Returns the props for [target] or an empty record.
  FormattingProps forTarget(String target) =>
      byTarget[target] ?? const FormattingProps();

  /// Whether no settings have been declared.
  bool get isEmpty => byTarget.isEmpty;
}

const Set<String> _knownTargets = {
  'chord',
  'chorus',
  'footer',
  'grid',
  'tab',
  'label',
  'toc',
  'text',
  'title',
};

const Map<String, String> _formattingAliases = {
  'cf': 'chordfont',
  'cs': 'chordsize',
  'tf': 'textfont',
  'ts': 'textsize',
};

/// Returns the formatting target + property when [name] is a known
/// font/size/colour directive, or `null` otherwise.
///
/// The accepted target set is closed: `chord`, `chorus`, `footer`,
/// `grid`, `tab`, `label`, `toc`, `text`, `title`. Names ending in
/// `font` / `size` / `colour` / `color` for any other target are
/// treated as unrelated directives and ignored — this avoids
/// misinterpreting custom or future directives that happen to share a
/// suffix. Both `colour` and the American `color` spelling are
/// accepted on input; the returned property is always `colour`.
({String target, String property})? matchFormattingDirective(String name) {
  final canonical = _formattingAliases[name] ?? name;
  for (final suffix in const ['font', 'size', 'colour', 'color']) {
    if (canonical.endsWith(suffix)) {
      final target = canonical.substring(0, canonical.length - suffix.length);
      if (_knownTargets.contains(target)) {
        return (
          target: target,
          property: suffix == 'color' ? 'colour' : suffix,
        );
      }
    }
  }
  return null;
}

/// Reduces a stream of [Directive]s into a [FormattingSettings].
///
/// Only directives matching [matchFormattingDirective] (i.e. font/size/
/// colour for the known target set) contribute; everything else is
/// ignored without diagnostic since the same directive may carry
/// meaning for another consumer.
///
/// Directives carrying a selector contribute when the selector polarity
/// matches [includeSelected] — bare directives always apply, positive
/// `-sel` only when `sel` is in the set, and negative `-!sel` (or legacy
/// `+sel`) only when it is not.
FormattingSettings reduceFormatting(
  Iterable<Directive> directives, {
  Set<String> includeSelected = const {},
}) {
  final byTarget = <String, FormattingProps>{};
  for (final d in directives) {
    if (d.value == null) continue;
    if (d.selector != null) {
      final active = includeSelected.contains(d.selector);
      final applies = switch (d.polarity) {
        Polarity.positive => active,
        Polarity.negative => !active,
        Polarity.none => true,
      };
      if (!applies) continue;
    }
    final match = matchFormattingDirective(d.name);
    if (match == null) continue;
    final current = byTarget[match.target] ?? const FormattingProps();
    byTarget[match.target] = switch (match.property) {
      'font' => current._withFont(d.value),
      'size' => current._withSize(d.value),
      'colour' => current._withColour(d.value),
      _ => current,
    };
  }
  return FormattingSettings(byTarget: Map.unmodifiable(byTarget));
}

import 'package:chord_pro/src/source/source_span.dart';

/// Polarity of a directive selector suffix.
///
/// ChordPro spec form is `{name-sel: …}` (apply only when `sel` is
/// active) and `{name-!sel: …}` (apply only when `sel` is *not*
/// active). The legacy `{name+sel: …}` form is also accepted as a
/// negation. Bare directives carry [Polarity.none].
enum Polarity {
  /// No selector suffix present.
  none,

  /// `-selector` form: active only when the selector is set.
  positive,

  /// `-!selector` (or legacy `+selector`) form: active only when the
  /// selector is not set.
  negative,
}

/// A parsed `{…}` directive.
///
/// Names are lowercased and trimmed. [selector] captures the part after
/// the `-` or `+` suffix (see [polarity]). [value] is the trimmed text
/// after `:` or whitespace; it is `null` for bare directives such as
/// `{new_song}` and the empty string for `{title:}`.
class Directive {
  /// Creates a new [Directive].
  const Directive({
    required this.name,
    required this.span,
    this.selector,
    this.polarity = Polarity.none,
    this.value,
    this.fromMeta = false,
  });

  /// Lowercased directive name (short forms preserved; canonicalise later).
  final String name;

  /// Selector name, without the `-`/`+` prefix.
  final String? selector;

  /// Polarity of the selector.
  final Polarity polarity;

  /// Raw directive value, trimmed. `null` if the directive has no body.
  final String? value;

  /// Span covering the `{…}` in source.
  final SourceSpan span;

  /// Whether this directive was synthesised from a `{meta: key value}`
  /// line rather than appearing as `{key: value}` directly.
  final bool fromMeta;

  /// Whether the directive is in the spec's `x_*` custom namespace.
  ///
  /// ChordPro reserves `x_namespace_directive` for application-specific
  /// extensions and tells unsupporting tools to ignore them. The library
  /// preserves them on `Song.directives` without trying to interpret
  /// them as metadata.
  bool get isCustomExtension => name.startsWith('x_');

  @override
  String toString() {
    final sel = selector == null
        ? ''
        : polarity == Polarity.positive
            ? '-$selector'
            : '+$selector';
    final v = value == null ? '' : ': $value';
    return '{$name$sel$v}';
  }
}

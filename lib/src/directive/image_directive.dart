import 'package:chord_pro/src/directive/kv_parser.dart';
import 'package:chord_pro/src/source/source_span.dart';

/// Where an `{image}` is anchored on the page.
///
/// Per `lib/ChordPro/Song.pm:1917` (`/^(paper|page|allpages|column|float|line)$/`).
/// `allpages` was added in ChordPro 6.080 (experimental); the others
/// were added in 6.040.
enum ImageAnchor {
  /// Anchored to the physical paper.
  paper,

  /// Anchored to the current page.
  page,

  /// Anchored to every page in the song (experimental, 6.080).
  allpages,

  /// Anchored to the current column.
  column,

  /// Free-floating relative to the current line.
  float,

  /// Anchored to the current lyric line.
  line,
}

ImageAnchor? _parseAnchor(String? raw) => switch (raw) {
      'paper' => ImageAnchor.paper,
      'page' => ImageAnchor.page,
      'allpages' => ImageAnchor.allpages,
      'column' => ImageAnchor.column,
      'float' => ImageAnchor.float,
      'line' => ImageAnchor.line,
      _ => null,
    };

/// A parsed `{image: …}` directive.
///
/// The body of an image directive is a list of `key=value` attributes
/// where values may be quoted with `"` or `'` to embed whitespace.
/// Common attributes are surfaced as typed fields; unrecognised
/// attributes are kept verbatim under [attributes].
class ImageDirective {
  /// Creates a new [ImageDirective].
  const ImageDirective({
    required this.span,
    required this.attributes,
    this.src,
    this.width,
    this.height,
    this.scale,
    this.align,
    this.border,
    this.title,
    this.label,
    this.anchor,
    this.anchorEnum,
    this.id,
    this.href,
    this.x,
    this.y,
    this.spread,
    this.bordertrbl,
    this.center,
    this.chord,
    this.type,
    this.persist,
    this.omit,
  });

  /// `src=` — image source path or URI.
  final String? src;

  /// `width=` — explicit width (e.g. `200`, `4cm`).
  final String? width;

  /// `height=` — explicit height.
  final String? height;

  /// `scale=` — relative scale (e.g. `50%`, `0.5`). Comma-separated
  /// `X,Y` form is supported (ChordPro 6.060) and surfaced verbatim.
  final String? scale;

  /// `align=` — horizontal alignment (`left`, `center`, `right`).
  final String? align;

  /// `border=` — frame width.
  final String? border;

  /// `title=` — optional caption (HTML `title` attribute).
  final String? title;

  /// `label=` — visible caption rendered below the image.
  ///
  /// Added in ChordPro 6.040.
  final String? label;

  /// `anchor=` — raw value.
  ///
  /// See [anchorEnum] for the validated form. The raw string is kept
  /// even when the value is not one of the spec-listed values, so
  /// callers can inspect or surface unknown values.
  final String? anchor;

  /// `anchor=` — typed enum.
  ///
  /// Non-null only when [anchor] is one of `paper`, `page`, `allpages`,
  /// `column`, `float`, `line` per the ChordPro 6 spec.
  final ImageAnchor? anchorEnum;

  /// `id=` — caller-defined identifier.
  final String? id;

  /// `href=` — clickable link URL. Added in ChordPro 6.060.
  final String? href;

  /// `x=` — horizontal offset (experimental, ChordPro 6.010 / 6.040).
  final String? x;

  /// `y=` — vertical offset (experimental, ChordPro 6.010 / 6.040).
  final String? y;

  /// `spread=` — full-page-width image at top of page, with this many
  /// points spacing below.
  final String? spread;

  /// `bordertrbl=` — selective border edges (string of `t`/`r`/`b`/`l`
  /// letters).
  ///
  /// Per the spec, the `directives-image/` page uses `trbl=` while the
  /// cheat sheet uses `bordertrbl=`. Both names map to this field.
  final String? bordertrbl;

  /// `center=` — deprecated boolean alias for `align=center`.
  final String? center;

  /// `chord=` — name of a chord to render the diagram for. When set,
  /// the renderer treats this image as a generated chord diagram.
  /// Added in ChordPro 6.040.
  final String? chord;

  /// `type=` — delegated content type (e.g. `svg`). Added in ChordPro
  /// 6.040.
  final String? type;

  /// `persist=` — when truthy, the image asset persists across pages
  /// once defined. Added in ChordPro 6.040.
  final String? persist;

  /// `omit=` — when truthy, the image is suppressed.
  final String? omit;

  /// Every attribute parsed from the body, keyed by lowercased name.
  final Map<String, String> attributes;

  /// Span covering the original `{image: …}` directive.
  final SourceSpan span;
}

/// Parses the body of an `{image: …}` directive.
///
/// Returns `null` when [value] is empty. Malformed or duplicated
/// attributes are kept; the last value for a key wins.
ImageDirective? parseImageDirective(
  String value, {
  required SourceSpan span,
}) {
  if (value.isEmpty) return null;
  final attrs = parseKv(value);

  return ImageDirective(
    span: span,
    src: attrs['src'],
    width: attrs['width'],
    height: attrs['height'],
    scale: attrs['scale'],
    align: attrs['align'],
    border: attrs['border'],
    title: attrs['title'],
    label: attrs['label'],
    anchor: attrs['anchor'],
    anchorEnum: _parseAnchor(attrs['anchor']),
    id: attrs['id'],
    href: attrs['href'],
    x: attrs['x'],
    y: attrs['y'],
    spread: attrs['spread'],
    bordertrbl: attrs['bordertrbl'] ?? attrs['trbl'],
    center: attrs['center'],
    chord: attrs['chord'],
    type: attrs['type'],
    persist: attrs['persist'],
    omit: attrs['omit'],
    attributes: Map.unmodifiable(attrs),
  );
}

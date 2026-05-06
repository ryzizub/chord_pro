/// Typed attribute set for `{start_of_textblock}` per
/// `docs/content/Directives-env_textblock.md` and ChordPro Changes
/// 6.050.
///
/// Textblock-specific attributes plus a subset of `{image}`-inherited
/// attributes are surfaced as typed fields. All values are kept as
/// strings so the renderer can interpret units (`em`, `%`, etc.); the
/// parser does not validate them.
class TextblockAttributes {
  /// Creates a new [TextblockAttributes].
  const TextblockAttributes({
    this.width,
    this.height,
    this.padding,
    this.flush,
    this.vflush,
    this.textstyle,
    this.textsize,
    this.textspacing,
    this.textcolor,
    this.background,
    this.omit,
    this.align,
    this.anchor,
    this.x,
    this.y,
    this.border,
    this.bordertrbl,
    this.id,
    this.persist,
    this.href,
    this.title,
  });

  /// Decodes a [TextblockAttributes] from the parsed start-of-textblock
  /// attribute map.
  factory TextblockAttributes.fromAttributes(Map<String, String> attrs) {
    return TextblockAttributes(
      width: attrs['width'],
      height: attrs['height'],
      padding: attrs['padding'],
      flush: attrs['flush'],
      vflush: attrs['vflush'],
      textstyle: attrs['textstyle'],
      textsize: attrs['textsize'],
      textspacing: attrs['textspacing'],
      // `bgcolor` is the documented alias for `background`.
      textcolor: attrs['textcolor'] ?? attrs['color'],
      background: attrs['background'] ?? attrs['bgcolor'],
      omit: attrs['omit'],
      align: attrs['align'],
      anchor: attrs['anchor'],
      x: attrs['x'],
      y: attrs['y'],
      border: attrs['border'],
      bordertrbl: attrs['bordertrbl'],
      id: attrs['id'],
      persist: attrs['persist'],
      href: attrs['href'],
      title: attrs['title'],
    );
  }

  /// `width=` — block width (pt, `em`, `ex`, `%`).
  final String? width;

  /// `height=` — block height.
  final String? height;

  /// `padding=` — internal padding.
  final String? padding;

  /// `flush=` — horizontal alignment of text inside the block:
  /// `left` / `center` / `right`.
  final String? flush;

  /// `vflush=` — vertical alignment: `top` / `middle` / `bottom`.
  final String? vflush;

  /// `textstyle=` — name of a font style declared in config.
  final String? textstyle;

  /// `textsize=` — font size override.
  final String? textsize;

  /// `textspacing=` — line spacing fraction.
  final String? textspacing;

  /// `textcolor=` — text colour. The `color=` alias is also accepted.
  final String? textcolor;

  /// `background=` — block background colour. The `bgcolor=` alias is
  /// also accepted.
  final String? background;

  /// `omit=` — when truthy, the textblock is suppressed.
  final String? omit;

  /// `align=` — inherited from `{image}`: horizontal alignment of the
  /// block itself on the page.
  final String? align;

  /// `anchor=` — inherited from `{image}`.
  final String? anchor;

  /// `x=` — inherited from `{image}`.
  final String? x;

  /// `y=` — inherited from `{image}`.
  final String? y;

  /// `border=` — inherited from `{image}`.
  final String? border;

  /// `bordertrbl=` — inherited from `{image}`.
  final String? bordertrbl;

  /// `id=` — inherited from `{image}`.
  final String? id;

  /// `persist=` — inherited from `{image}`.
  final String? persist;

  /// `href=` — inherited from `{image}`.
  final String? href;

  /// `title=` — inherited from `{image}`.
  final String? title;
}

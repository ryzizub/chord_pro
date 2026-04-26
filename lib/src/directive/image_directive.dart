import 'package:chord_pro/src/source/source_span.dart';

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
    this.anchor,
    this.id,
  });

  /// `src=` — image source path or URI.
  final String? src;

  /// `width=` — explicit width (e.g. `200`, `4cm`).
  final String? width;

  /// `height=` — explicit height.
  final String? height;

  /// `scale=` — relative scale (e.g. `50%`, `0.5`).
  final String? scale;

  /// `align=` — horizontal alignment (`left`, `center`, `right`).
  final String? align;

  /// `border=` — frame width.
  final String? border;

  /// `title=` — optional caption.
  final String? title;

  /// `anchor=` — `inline`, `float`, etc.
  final String? anchor;

  /// `id=` — caller-defined identifier.
  final String? id;

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
  final attrs = <String, String>{};
  var i = 0;
  while (i < value.length) {
    final ch = value.codeUnitAt(i);
    if (ch == 0x20 || ch == 0x09) {
      i++;
      continue;
    }
    final keyStart = i;
    while (i < value.length) {
      final c = value.codeUnitAt(i);
      if (c == 0x3D || c == 0x20 || c == 0x09) break;
      i++;
    }
    if (i == keyStart) {
      i++;
      continue;
    }
    final key = value.substring(keyStart, i).toLowerCase();
    if (i < value.length && value.codeUnitAt(i) == 0x3D) {
      i++;
      final parsed = _readValue(value, i);
      attrs[key] = parsed.value;
      i = parsed.end;
    } else {
      attrs[key] = '';
    }
  }

  return ImageDirective(
    span: span,
    src: attrs['src'],
    width: attrs['width'],
    height: attrs['height'],
    scale: attrs['scale'],
    align: attrs['align'],
    border: attrs['border'],
    title: attrs['title'],
    anchor: attrs['anchor'],
    id: attrs['id'],
    attributes: Map.unmodifiable(attrs),
  );
}

class _ValueRead {
  _ValueRead(this.value, this.end);
  final String value;
  final int end;
}

_ValueRead _readValue(String s, int start) {
  if (start >= s.length) return _ValueRead('', start);
  final first = s.codeUnitAt(start);
  if (first == 0x22 || first == 0x27) {
    final quote = first;
    final buffer = StringBuffer();
    var i = start + 1;
    while (i < s.length) {
      final c = s.codeUnitAt(i);
      if (c == 0x5C && i + 1 < s.length) {
        buffer.writeCharCode(s.codeUnitAt(i + 1));
        i += 2;
        continue;
      }
      if (c == quote) {
        return _ValueRead(buffer.toString(), i + 1);
      }
      buffer.writeCharCode(c);
      i++;
    }
    return _ValueRead(buffer.toString(), i);
  }
  final end = _findUnquotedEnd(s, start);
  return _ValueRead(s.substring(start, end), end);
}

int _findUnquotedEnd(String s, int start) {
  for (var i = start; i < s.length; i++) {
    final c = s.codeUnitAt(i);
    if (c == 0x20 || c == 0x09) return i;
  }
  return s.length;
}

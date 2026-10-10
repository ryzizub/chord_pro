import 'package:chord_pro/src/directive/directive.dart';
import 'package:chord_pro/src/source/raw_line.dart';
import 'package:chord_pro/src/source/source_span.dart';

/// Result of attempting to parse a single `{…}` directive off a line.
class DirectiveMatch {
  /// Creates a [DirectiveMatch].
  const DirectiveMatch({required this.directive, required this.end});

  /// The parsed directive.
  final Directive directive;

  /// Index one past the closing `}` in the source line.
  final int end;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DirectiveMatch &&
          other.directive == directive &&
          other.end == end;

  @override
  int get hashCode => Object.hash(directive, end);
}

/// Parses the single directive that must span the whole [line].
///
/// Returns `null` if the line is not a pure directive line (i.e. it
/// contains anything other than whitespace outside the `{…}`).
Directive? parseDirectiveLine(RawLine line) {
  final trimmed = line.text.trim();
  if (trimmed.length < 2 || trimmed.codeUnitAt(0) != 0x7B) return null;
  if (trimmed.codeUnitAt(trimmed.length - 1) != 0x7D) return null;

  final startCol = line.text.indexOf('{') + 1;
  final match = parseDirectiveAt(line, startCol - 1);
  if (match == null) return null;
  if (match.end != line.text.trimRight().length) return null;
  return match.directive;
}

/// Parses a directive starting at [offset] (0-based) in [line].
///
/// The character at [offset] must be `{`. Returns `null` if the
/// directive is malformed (no closing `}`, empty name, …).
DirectiveMatch? parseDirectiveAt(RawLine line, int offset) {
  final text = line.text;
  if (offset >= text.length || text.codeUnitAt(offset) != 0x7B) return null;

  // Find closing brace, honouring `\}` escapes inside the value.
  var end = -1;
  for (var i = offset + 1; i < text.length; i++) {
    final ch = text.codeUnitAt(i);
    if (ch == 0x5C && i + 1 < text.length) {
      i++;
      continue;
    }
    if (ch == 0x7D) {
      end = i;
      break;
    }
  }
  if (end < 0) return null;

  final inner = text.substring(offset + 1, end);
  final parsed = _parseInner(inner);
  if (parsed == null) return null;

  return DirectiveMatch(
    directive: Directive(
      name: parsed.name,
      selector: parsed.selector,
      polarity: parsed.polarity,
      value: parsed.value,
      span: SourceSpan(
        line: line.number,
        column: offset + 1,
        length: end - offset + 1,
      ),
    ),
    end: end + 1,
  );
}

class _Parsed {
  _Parsed(this.name, this.selector, this.polarity, this.value);
  final String name;
  final String? selector;
  final Polarity polarity;
  final String? value;
}

_Parsed? _parseInner(String inner) {
  // Split name[±selector] from optional value on first ':' or whitespace.
  final splitAt = _findHeadEnd(inner);
  final String head;
  String? value;
  if (splitAt < 0) {
    head = inner.trim();
  } else {
    head = inner.substring(0, splitAt).trim();
    final isColon = inner.codeUnitAt(splitAt) == 0x3A;
    value = inner.substring(splitAt + (isColon ? 1 : 0)).trim();
  }
  if (head.isEmpty) return null;
  return _splitSelector(head, value);
}

/// Index of the first `:`, space or tab in [inner], or -1 if none.
int _findHeadEnd(String inner) {
  for (var i = 0; i < inner.length; i++) {
    final ch = inner.codeUnitAt(i);
    if (ch == 0x3A || ch == 0x20 || ch == 0x09) return i;
  }
  return -1;
}

// Split selector off head.
// Spec form (ChordPro reference): `name-selector` (positive) or
// `name-selector!` (negative — `!` is *postfixed* to the selector).
// For backward compatibility this parser also accepts two non-spec
// forms used by earlier releases of this library:
// `name-!selector` (prefix `!`) and the legacy `name+selector`.
_Parsed _splitSelector(String head, String? value) {
  final sep = _selectorSeparator(head);
  if (sep <= 0) return _Parsed(head.toLowerCase(), null, Polarity.none, value);
  final (:selector, :negated) = _readSelector(head, sep);
  if (selector.isEmpty) {
    return _Parsed(head.toLowerCase(), null, Polarity.none, value);
  }
  return _Parsed(
    head.substring(0, sep).trim().toLowerCase(),
    selector.toLowerCase(),
    negated ? Polarity.negative : Polarity.positive,
    value,
  );
}

/// Index of the first `-` or `+` in [head], or -1 if neither occurs.
int _selectorSeparator(String head) {
  final dash = head.indexOf('-');
  final plus = head.indexOf('+');
  if (dash < 0) return plus;
  if (plus < 0) return dash;
  return dash < plus ? dash : plus;
}

/// Reads the selector after the separator at [sep], stripping a `!`
/// negation marker.
({String selector, bool negated}) _readSelector(String head, int sep) {
  var sel = head.substring(sep + 1).trim();
  final isLegacyPlus = head.codeUnitAt(sep) == 0x2B;
  var negated = isLegacyPlus;
  // Spec form: trailing `!` on the selector.
  if (sel.length > 1 && sel.endsWith('!')) {
    sel = sel.substring(0, sel.length - 1).trim();
    negated = true;
  }
  // Non-spec leading `!` retained for backward compatibility.
  if (!isLegacyPlus && sel.startsWith('!')) {
    sel = sel.substring(1).trim();
    negated = true;
  }
  return (selector: sel, negated: negated);
}

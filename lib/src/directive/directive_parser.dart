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
  var splitAt = -1;
  var splitIsColon = false;
  for (var i = 0; i < inner.length; i++) {
    final ch = inner.codeUnitAt(i);
    if (ch == 0x3A) {
      splitAt = i;
      splitIsColon = true;
      break;
    }
    if (ch == 0x20 || ch == 0x09) {
      splitAt = i;
      break;
    }
  }

  final String head;
  String? value;
  if (splitAt < 0) {
    head = inner.trim();
    value = null;
  } else {
    head = inner.substring(0, splitAt).trim();
    final rest = inner.substring(splitAt + (splitIsColon ? 1 : 0));
    value = rest.trim();
  }
  if (head.isEmpty) return null;

  // Split selector off head.
  var polarity = Polarity.none;
  String? selector;
  var name = head;
  final dash = head.indexOf('-');
  final plus = head.indexOf('+');
  final sep = dash >= 0 && (plus < 0 || dash < plus)
      ? dash
      : plus >= 0
          ? plus
          : -1;
  if (sep > 0) {
    final sel = head.substring(sep + 1).trim();
    if (sel.isNotEmpty) {
      name = head.substring(0, sep).trim();
      selector = sel.toLowerCase();
      polarity =
          head.codeUnitAt(sep) == 0x2D ? Polarity.positive : Polarity.negative;
    }
  }

  return _Parsed(name.toLowerCase(), selector, polarity, value);
}

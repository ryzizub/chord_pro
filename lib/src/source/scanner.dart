import 'package:chord_pro/src/source/raw_line.dart';

/// Splits [source] into [RawLine]s, preserving 1-based line numbers.
///
/// Recognises `\n`, `\r\n`, and lone `\r` as line terminators. An empty
/// input produces an empty list; a trailing newline does not produce a
/// trailing blank line.
///
/// Per ChordPro 6.01:
///  - A line ending with `\` is continued by the following line; the
///    backslash and the leading whitespace of the next line are
///    discarded. The continued line keeps the line number where it
///    started.
///  - `\uXXXX` (4 hex digits) anywhere in the text is replaced by the
///    corresponding Unicode code point.
List<RawLine> scan(String source) {
  if (source.isEmpty) return const [];

  final physical = <RawLine>[];
  final buffer = StringBuffer();
  var lineNumber = 1;

  void flush() {
    physical.add(RawLine(number: lineNumber, text: buffer.toString()));
    buffer.clear();
    lineNumber++;
  }

  for (var i = 0; i < source.length; i++) {
    final ch = source.codeUnitAt(i);
    if (ch == 0x0A) {
      flush();
    } else if (ch == 0x0D) {
      flush();
      if (i + 1 < source.length && source.codeUnitAt(i + 1) == 0x0A) i++;
    } else {
      buffer.writeCharCode(ch);
    }
  }
  if (buffer.isNotEmpty) flush();

  final result = <RawLine>[];
  for (var i = 0; i < physical.length; i++) {
    final start = physical[i];
    var text = start.text;
    while (_endsWithUnescapedBackslash(text) && i + 1 < physical.length) {
      text =
          text.substring(0, text.length - 1) + _stripLead(physical[i + 1].text);
      i++;
    }
    result
        .add(RawLine(number: start.number, text: _resolveUnicodeEscapes(text)));
  }

  return result;
}

bool _endsWithUnescapedBackslash(String s) {
  if (s.isEmpty) return false;
  if (s.codeUnitAt(s.length - 1) != 0x5C) return false;
  // Count trailing backslashes; an odd count means the last one is not
  // itself escaped, so it acts as a continuation marker.
  var count = 0;
  for (var i = s.length - 1; i >= 0 && s.codeUnitAt(i) == 0x5C; i--) {
    count++;
  }
  return count.isOdd;
}

String _stripLead(String s) {
  var i = 0;
  while (i < s.length) {
    final c = s.codeUnitAt(i);
    if (c == 0x20 || c == 0x09) {
      i++;
    } else {
      break;
    }
  }
  return i == 0 ? s : s.substring(i);
}

String _resolveUnicodeEscapes(String s) {
  if (s.length < 6) return s;
  final out = StringBuffer();
  var i = 0;
  while (i < s.length) {
    final ch = s.codeUnitAt(i);
    if (ch == 0x5C && i + 5 < s.length && s.codeUnitAt(i + 1) == 0x75) {
      final hex = s.substring(i + 2, i + 6);
      final code = int.tryParse(hex, radix: 16);
      if (code != null) {
        out.writeCharCode(code);
        i += 6;
        continue;
      }
    }
    out.writeCharCode(ch);
    i++;
  }
  return out.toString();
}

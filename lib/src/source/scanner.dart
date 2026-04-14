import 'package:chord_pro/src/source/raw_line.dart';

/// Splits [source] into [RawLine]s, preserving 1-based line numbers.
///
/// Recognises `\n`, `\r\n`, and lone `\r` as line terminators. An empty
/// input produces an empty list; a trailing newline does not produce a
/// trailing blank line.
List<RawLine> scan(String source) {
  if (source.isEmpty) return const [];

  final lines = <RawLine>[];
  final buffer = StringBuffer();
  var lineNumber = 1;

  void flush() {
    lines.add(RawLine(number: lineNumber, text: buffer.toString()));
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

  return lines;
}

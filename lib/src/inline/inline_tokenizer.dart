import 'package:chord_pro/src/chord/chord.dart';
import 'package:chord_pro/src/directive/directive_parser.dart';
import 'package:chord_pro/src/inline/inline_token.dart';
import 'package:chord_pro/src/source/raw_line.dart';
import 'package:chord_pro/src/source/source_span.dart';

/// Tokenizes a single [line] of lyric/chord content.
///
/// Recognises:
///  - `[chord]` → [ChordToken]
///  - `[*marker]` → [AnnotationToken]
///  - `{…}` embedded in the line → [InlineDirectiveToken]
///  - everything else → [TextToken]
///
/// Backslash escapes (`\[`, `\]`, `\{`, `\}`, `\\`) are honoured and
/// unescaped in the emitted [TextToken]s.
List<InlineToken> tokenizeInline(RawLine line) {
  final text = line.text;
  final out = <InlineToken>[];
  final buffer = StringBuffer();
  var bufferStart = 0;

  void flushText(int endCol) {
    if (buffer.isEmpty) return;
    out.add(
      TextToken(
        text: buffer.toString(),
        span: SourceSpan(
          line: line.number,
          column: bufferStart + 1,
          length: endCol - bufferStart,
        ),
      ),
    );
    buffer.clear();
  }

  var i = 0;
  while (i < text.length) {
    final ch = text.codeUnitAt(i);

    if (ch == 0x5C && i + 1 < text.length) {
      // Backslash escape.
      if (buffer.isEmpty) bufferStart = i;
      buffer.writeCharCode(text.codeUnitAt(i + 1));
      i += 2;
      continue;
    }

    if (ch == 0x5B) {
      flushText(i);
      final closed = _findUnescaped(text, i + 1, 0x5D);
      if (closed < 0) {
        // Unterminated — treat '[' as literal text and continue.
        if (buffer.isEmpty) bufferStart = i;
        buffer.writeCharCode(ch);
        i++;
        continue;
      }
      final inner = text.substring(i + 1, closed);
      final span = SourceSpan(
        line: line.number,
        column: i + 1,
        length: closed - i + 1,
      );
      if (inner.startsWith('*')) {
        out.add(AnnotationToken(text: inner.substring(1), span: span));
      } else {
        out.add(
          ChordToken(raw: inner, chord: Chord.tryParse(inner), span: span),
        );
      }
      i = closed + 1;
      bufferStart = i;
      continue;
    }

    if (ch == 0x7B) {
      flushText(i);
      final match = parseDirectiveAt(line, i);
      if (match == null) {
        if (buffer.isEmpty) bufferStart = i;
        buffer.writeCharCode(ch);
        i++;
        continue;
      }
      out.add(
        InlineDirectiveToken(
          directive: match.directive,
          span: match.directive.span,
        ),
      );
      i = match.end;
      bufferStart = i;
      continue;
    }

    if (buffer.isEmpty) bufferStart = i;
    buffer.writeCharCode(ch);
    i++;
  }

  flushText(i);
  return out;
}

int _findUnescaped(String text, int start, int target) {
  for (var i = start; i < text.length; i++) {
    final ch = text.codeUnitAt(i);
    if (ch == 0x5C && i + 1 < text.length) {
      i++;
      continue;
    }
    if (ch == target) return i;
  }
  return -1;
}

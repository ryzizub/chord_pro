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
///  - `[ ]+` (whitespace-only) and `[|]` (pipe-only) → [AnnotationToken]
///    per ChordPro 6.020/6.080 emergency-bracket recovery
///    (Song.pm:941–948)
///  - `[]` (empty) → no token (zero-width placeholder)
///  - `{…}` embedded in the line → [InlineDirectiveToken]
///  - everything else → [TextToken]
///
/// Backslash escapes (`\[`, `\]`, `\{`, `\}`, `\\`) are honoured and
/// unescaped in the emitted [TextToken]s.
///
/// When [notesMode] is `true`, lowercase `a`–`g` are accepted as letter
/// chord roots inside `[…]` brackets (mirrors the `settings.notes` config).
///
/// The returned list is unmodifiable: parsed lines are values, and
/// mutating one in place would corrupt a shared `Line`.
List<InlineToken> tokenizeInline(RawLine line, {bool notesMode = false}) {
  final text = line.text;
  final out = <InlineToken>[];
  final pending = _PendingText(line.number);

  var i = 0;
  while (i < text.length) {
    final ch = text.codeUnitAt(i);

    if (ch == 0x5C && i + 1 < text.length) {
      // Backslash escape.
      pending.write(i, text.codeUnitAt(i + 1));
      i += 2;
      continue;
    }

    if (ch != 0x5B && ch != 0x7B) {
      pending.write(i, ch);
      i++;
      continue;
    }

    pending.flushInto(out, i);
    final markup = ch == 0x5B
        ? _bracketAt(line, i, notesMode: notesMode)
        : _directiveAt(line, i);
    if (markup == null) {
      // Unterminated `[` or unparseable `{` — keep it as literal text.
      pending.write(i, ch);
      i++;
      continue;
    }
    if (markup.token case final token?) out.add(token);
    i = markup.end;
  }

  pending.flushInto(out, i);
  return List.unmodifiable(out);
}

/// Literal text gathered between markup, emitted as one [TextToken].
class _PendingText {
  _PendingText(this.lineNumber);

  final int lineNumber;
  final StringBuffer _buffer = StringBuffer();
  int _start = 0;

  /// Appends [codeUnit], read from column index [at] of the source line.
  void write(int at, int codeUnit) {
    if (_buffer.isEmpty) _start = at;
    _buffer.writeCharCode(codeUnit);
  }

  /// Emits the gathered text, ending before index [end], into [out].
  void flushInto(List<InlineToken> out, int end) {
    if (_buffer.isEmpty) return;
    out.add(
      TextToken(
        text: _buffer.toString(),
        span: SourceSpan(
          line: lineNumber,
          column: _start + 1,
          length: end - _start,
        ),
      ),
    );
    _buffer.clear();
  }
}

/// A `[…]` or `{…}` construct recognised at some column: the `token` it
/// produces (none for an empty `[]`) and the `end` index just past it.
typedef _Markup = ({InlineToken? token, int end});

/// Parses the `[…]` bracket opening at [open], or returns `null` when it
/// is never closed.
_Markup? _bracketAt(RawLine line, int open, {required bool notesMode}) {
  final text = line.text;
  final closed = _findUnescaped(text, open + 1, 0x5D);
  if (closed < 0) return null;
  final span = SourceSpan(
    line: line.number,
    column: open + 1,
    length: closed - open + 1,
  );
  final inner = text.substring(open + 1, closed);
  return (
    token: _bracketToken(inner, span, notesMode: notesMode),
    end: closed + 1,
  );
}

InlineToken? _bracketToken(
  String inner,
  SourceSpan span, {
  required bool notesMode,
}) {
  // Empty `[]` is a zero-width placeholder per ChordPro 6.080
  // emergency-bracket handling — emit no token.
  if (inner.isEmpty) return null;
  // `[^]` is the chord-recall operator per ChordPro 6.070.
  if (inner == '^') return ChordRecallToken(span: span);
  if (inner.startsWith('*')) {
    return AnnotationToken(text: inner.substring(1), span: span);
  }
  if (inner == '|' || _isWhitespaceOnly(inner)) {
    // ChordPro 6.020/6.080 emergency-bracket: pipe-only or
    // whitespace-only contents become an annotation
    // (Song.pm:941–948).
    return AnnotationToken(text: inner, span: span);
  }
  return ChordToken(
    raw: inner,
    chord: Chord.tryParse(inner, notesMode: notesMode),
    span: span,
  );
}

/// Parses the inline `{…}` directive opening at [open], or returns `null`
/// when it is not a well-formed directive.
_Markup? _directiveAt(RawLine line, int open) {
  final match = parseDirectiveAt(line, open);
  if (match == null) return null;
  return (
    token: InlineDirectiveToken(
      directive: match.directive,
      span: match.directive.span,
    ),
    end: match.end,
  );
}

bool _isWhitespaceOnly(String s) {
  for (var i = 0; i < s.length; i++) {
    final c = s.codeUnitAt(i);
    if (c != 0x20 && c != 0x09) return false;
  }
  return s.isNotEmpty;
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

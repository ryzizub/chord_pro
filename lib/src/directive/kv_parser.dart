/// Parses a `key=value` attribute string per ChordPro `parse_kv`
/// semantics.
///
/// Values may be quoted with `"` or `'` to embed whitespace; backslash
/// escapes `\X` inside quoted values insert the literal `X`. Unquoted
/// values terminate at the next whitespace.
///
/// When [defaultKey] is non-null, a leading bare value (no `=` before
/// the next whitespace) is treated as `defaultKey="that value"`.
/// This matches the spec's backward-compat handling for section-start
/// labels (`{start_of_verse: Verse 1}` becomes
/// `label="Verse 1"`) and for similar directives like
/// `{chorus: Final}` (becomes `label="Final"`) and
/// `{start_of_grid: 4x4}` (becomes `shape="4x4"`).
///
/// Returns a fresh map; the caller owns it.
Map<String, String> parseKv(
  String input, {
  String? defaultKey,
}) {
  final out = <String, String>{};
  if (input.isEmpty) return out;

  var i = 0;
  var first = true;
  while (i < input.length) {
    final ch = input.codeUnitAt(i);
    if (ch == 0x20 || ch == 0x09) {
      i++;
      continue;
    }
    final keyStart = i;
    var sawEquals = false;
    while (i < input.length) {
      final c = input.codeUnitAt(i);
      if (c == 0x3D) {
        sawEquals = true;
        break;
      }
      if (c == 0x20 || c == 0x09) break;
      i++;
    }
    final keyEnd = i;
    final keySpan = input.substring(keyStart, keyEnd);
    if (sawEquals) {
      final key = keySpan.toLowerCase();
      i++; // consume '='
      final parsed = _readValue(input, i);
      out[key] = parsed.value;
      i = parsed.end;
      first = false;
    } else if (first && defaultKey != null && !out.containsKey(defaultKey)) {
      // Leading bare value -> defaultKey="...". Re-read from keyStart
      // and grab everything up to the next whitespace-followed-by-key=value.
      final value = _readBareDefault(input, keyStart);
      out[defaultKey] = value.value;
      i = value.end;
      first = false;
    } else {
      // Bare attribute (no `=`): empty value.
      if (keySpan.isNotEmpty) {
        out[keySpan.toLowerCase()] = '';
      }
      first = false;
    }
  }
  return out;
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

/// Reads the bare-default leading value: everything from [start] up to
/// the next whitespace-then-`key=` boundary (or end of input).
///
/// Quoted segments are returned with the surrounding quotes stripped
/// and backslash escapes resolved.
_ValueRead _readBareDefault(String s, int start) {
  // If the bare value is quoted, just delegate to _readValue.
  if (start < s.length) {
    final c = s.codeUnitAt(start);
    if (c == 0x22 || c == 0x27) return _readValue(s, start);
  }
  // Otherwise, walk forward looking for whitespace followed by something
  // that looks like another key= boundary.
  final buffer = StringBuffer();
  var i = start;
  while (i < s.length) {
    final c = s.codeUnitAt(i);
    if (c == 0x20 || c == 0x09) {
      // Peek ahead — does the next non-whitespace token look like
      // `key=value`? If so, stop. Otherwise consume the whitespace as
      // part of the bare value.
      var j = i;
      while (j < s.length) {
        final cc = s.codeUnitAt(j);
        if (cc != 0x20 && cc != 0x09) break;
        j++;
      }
      if (_isKeyEqualsBoundary(s, j)) {
        return _ValueRead(buffer.toString().trimRight(), i);
      }
      buffer.writeCharCode(c);
      i++;
      continue;
    }
    buffer.writeCharCode(c);
    i++;
  }
  return _ValueRead(buffer.toString().trimRight(), i);
}

/// Returns true when [s] starting at [start] contains `key=` where
/// `key` is `[A-Za-z_][\w-]*`.
bool _isKeyEqualsBoundary(String s, int start) {
  var i = start;
  if (i >= s.length) return false;
  final first = s.codeUnitAt(i);
  if (!_isKeyStart(first)) return false;
  i++;
  while (i < s.length) {
    final c = s.codeUnitAt(i);
    if (c == 0x3D) return true;
    if (!_isKeyContinue(c)) return false;
    i++;
  }
  return false;
}

bool _isKeyStart(int c) =>
    (c >= 0x41 && c <= 0x5A) || // A-Z
    (c >= 0x61 && c <= 0x7A) || // a-z
    c == 0x5F; // _

bool _isKeyContinue(int c) =>
    _isKeyStart(c) ||
    (c >= 0x30 && c <= 0x39) || // 0-9
    c == 0x2D; // -

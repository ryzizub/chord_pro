/// Bidirectional spec-coverage guard.
///
/// `spec_audit_test.dart` checks the *spec → implementation* direction:
/// every published ChordPro rule gets a test. This file checks the
/// reverse direction — *implementation → ledger* — so that nothing the
/// parser recognises can exist without being written down in one of the
/// two ledgers:
///
///   - `chordpro-spec-checklist.md` — spec-mandated behaviour.
///   - `doc/reference/non-spec-extensions.md` — deliberate leniencies.
///
/// Motivation: `{colb}` (a non-spec shorthand for `{column_break}`, used
/// because the spec's `{cb}` is already taken by `{comment_box}`) shipped
/// undocumented for several releases. Spec-outward audits could not see
/// it, because it is not a spec feature and so nothing in the checklist
/// ever pointed at it. This test closes that class of gap: every name the
/// parser dispatches on must appear in a ledger, or the build fails.
///
/// Scope: directive names, metadata names, formatting directive names and
/// chord-quality tokens. Attribute names (`label=`, `shape=`, `anchor=`,
/// …) form a separate ledger and are deliberately out of scope here.
library;

import 'dart:io';

import 'package:test/test.dart';

const _checklistPath = 'chordpro-spec-checklist.md';
const _nonSpecPath = 'doc/reference/non-spec-extensions.md';
const _assemblerPath = 'lib/src/assembler/assembler.dart';
const _metadataPath = 'lib/src/ast/metadata.dart';
const _formattingPath = 'lib/src/ast/formatting.dart';
const _chordPath = 'lib/src/chord/chord.dart';

/// Names deliberately absent from both ledgers.
///
/// Keep this empty if at all possible. Every entry needs a comment saying
/// why the name is neither a spec obligation nor a documented extension —
/// otherwise it belongs in one of the two ledgers instead.
const _allowlist = <String>{};

void main() {
  final documented = _documentedTokens();

  group('§coverage implementation → ledger', () {
    test('assembler directive names are all documented', () {
      _expectDocumented(_assemblerNames(), documented, _assemblerPath);
    });

    test('metadata names are all documented', () {
      _expectDocumented(_metadataNames(), documented, _metadataPath);
    });

    test('formatting directive names are all documented', () {
      _expectDocumented(_formattingNames(), documented, _formattingPath);
    });

    test('chord quality tokens are all documented', () {
      _expectDocumented(_chordQualities(), documented, _chordPath);
    });
  });

  group('§coverage extraction backstop', () {
    // Guards against a silent vacuous pass: if a helper is renamed or the
    // source syntax shifts so a regex stops matching, the tests above
    // would pass while checking nothing. The floors sit well below the
    // real counts so ordinary additions never trip them.
    test('ledger and source extraction return plausible counts', () {
      expect(documented.length, greaterThan(200), reason: 'ledger tokens');
      expect(_assemblerNames().length, greaterThan(30), reason: 'assembler');
      expect(_metadataNames().length, greaterThan(30), reason: 'metadata');
      expect(_formattingNames().length, greaterThan(20), reason: 'formatting');
      expect(_chordQualities().length, greaterThan(10), reason: 'qualities');
    });
  });
}

void _expectDocumented(
  Set<String> found,
  Set<String> documented,
  String source,
) {
  final missing = <String>[];
  for (final name in found) {
    if (documented.contains(name) || _allowlist.contains(name)) continue;
    missing.add(name);
  }
  missing.sort();
  expect(
    missing,
    isEmpty,
    reason: 'Recognised by $source but documented in neither\n'
        '  $_checklistPath (spec obligations)\n'
        '  $_nonSpecPath (deliberate leniencies)\n'
        'Add each to whichever ledger applies — a name the parser acts '
        'on but nobody wrote down is exactly the drift this test exists '
        'to catch.\n'
        'Missing: $missing',
  );
}

// ---------------------------------------------------------------------
// Ledger side: what the docs say
// ---------------------------------------------------------------------

final _codeSpan = RegExp(r'`([^`\n]+)`');
final _splitters = RegExp(r'[\s/:=,.|]+');
// `'` is the apostrophe: a raw string cannot contain its own quote,
// and RegExp resolves the escape itself.
final _leadingJunk = RegExp(r'^[{<"\u0027]+');
final _trailingJunk = RegExp(r'[}>"\u0027!]+$');

/// Every token named in either ledger.
///
/// Each inline code span contributes both its whole normalised form and
/// its parts, so `` `chordpro.songsource` `` documents the dotted name
/// *and* the bare `songsource`, and `` `{ns toc=no}` `` documents `ns`.
Set<String> _documentedTokens() {
  const paths = [_checklistPath, _nonSpecPath];
  final out = <String>{};
  for (final path in paths) {
    for (final match in _codeSpan.allMatches(_read(path))) {
      final whole = _normalise(match.group(1)!);
      if (whole.isEmpty) continue;
      out.add(whole);
      for (final piece in whole.split(_splitters)) {
        final part = _normalise(piece);
        if (part.isNotEmpty) out.add(part);
      }
    }
  }
  return out;
}

/// Strips directive braces, markup angle brackets, quotes and the
/// trailing `!` of a negated selector.
String _normalise(String s) {
  var t = s.trim();
  t = t.replaceAll(_leadingJunk, '');
  t = t.replaceAll(_trailingJunk, '');
  return t.trim();
}

// ---------------------------------------------------------------------
// Implementation side: what the parser dispatches on
// ---------------------------------------------------------------------

final _caseLiteral = RegExp("case '([^']+)':");
final _nameCompare = RegExp(r"\.name (?:==|!=) '([^']+)'");
final _quoted = RegExp("'([^']*)'");

/// Directive names the assembler switches or compares on.
Set<String> _assemblerNames() {
  final src = _read(_assemblerPath);
  final out = <String>{};
  for (final match in _caseLiteral.allMatches(src)) {
    out.add(match.group(1)!);
  }
  for (final match in _nameCompare.allMatches(src)) {
    out.add(match.group(1)!);
  }
  return out;
}

/// Metadata directive names, aliases and reserved auto-generated names.
Set<String> _metadataNames() {
  const collections = [
    '_metadataAliases',
    '_listMetadataNames',
    '_intMetadataNames',
    '_scalarMetadataNames',
    '_multiValuedMetadataNames',
    '_reservedAutogeneratedNames',
  ];
  final src = _read(_metadataPath);
  final out = <String>{};
  for (final name in collections) {
    out.addAll(_constMembers(src, name));
  }
  return out;
}

/// Formatting directive names, expanded from the known target set.
///
/// The bare targets (`chord`, `tab`, …) are not themselves directives, so
/// this checks the names users actually write — `chordfont`, `tabsize`,
/// `labelcolour` — against the checklist's §9 table.
Set<String> _formattingNames() {
  const suffixes = ['font', 'size', 'colour'];
  final src = _read(_formattingPath);
  final out = <String>{};
  for (final target in _constMembers(src, '_knownTargets')) {
    for (final suffix in suffixes) {
      out.add('$target$suffix');
    }
  }
  out.addAll(_constMembers(src, '_formattingAliases'));
  return out;
}

/// Chord quality / qualifier tokens.
Set<String> _chordQualities() {
  return _constMembers(_read(_chordPath), '_qualities');
}

/// Returns every single-quoted string inside the `const` collection
/// literal declared as [name] in [src].
Set<String> _constMembers(String src, String name) {
  final match = RegExp('$name\\s*=\\s*[{\\[]').firstMatch(src);
  if (match == null) return const {};
  final openIndex = match.end - 1;
  final open = src[openIndex];
  final close = open == '{' ? '}' : ']';
  var depth = 0;
  var end = -1;
  for (var i = openIndex; i < src.length; i++) {
    final ch = src[i];
    if (ch == open) {
      depth++;
    } else if (ch == close) {
      depth--;
      if (depth == 0) {
        end = i;
        break;
      }
    }
  }
  if (end < 0) return const {};
  final out = <String>{};
  for (final m in _quoted.allMatches(src.substring(openIndex + 1, end))) {
    out.add(m.group(1)!);
  }
  return out;
}

String _read(String path) => File(path).readAsStringSync();

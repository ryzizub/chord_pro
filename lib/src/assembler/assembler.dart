import 'package:chord_pro/src/ast/diagrams_setting.dart';
import 'package:chord_pro/src/ast/formatting.dart';
import 'package:chord_pro/src/ast/line.dart';
import 'package:chord_pro/src/ast/metadata.dart';
import 'package:chord_pro/src/ast/section.dart';
import 'package:chord_pro/src/ast/song.dart';
import 'package:chord_pro/src/ast/titles_alignment.dart';
import 'package:chord_pro/src/chord/chord_definition.dart';
import 'package:chord_pro/src/diagnostic/diagnostic.dart';
import 'package:chord_pro/src/diagnostic/parse_result.dart';
import 'package:chord_pro/src/directive/directive.dart';
import 'package:chord_pro/src/directive/directive_parser.dart';
import 'package:chord_pro/src/directive/image_directive.dart';
import 'package:chord_pro/src/directive/kv_parser.dart';
import 'package:chord_pro/src/inline/inline_tokenizer.dart';
import 'package:chord_pro/src/source/raw_line.dart';
import 'package:chord_pro/src/source/scanner.dart';
import 'package:chord_pro/src/source/source_span.dart';

/// Parses [source] into one or more [Song]s plus diagnostics.
///
/// [selectors] names the conditional selectors that should be treated as
/// active when reducing metadata and formatting directives. Matching is
/// case-insensitive; selectors are folded to lower-case to match what the
/// directive parser stores.
///
/// [notesMode] mirrors the `settings.notes` configuration option: when
/// `true`, lowercase `a`–`g` are accepted as letter-system chord roots.
ParseResult assemble(
  String source, {
  Set<String> selectors = const {},
  bool notesMode = false,
}) {
  final activeSelectors = selectors.isEmpty
      ? const <String>{}
      : {for (final s in selectors) s.toLowerCase()};
  final lines = scan(source);
  final diagnostics = <Diagnostic>[];
  final songs = <Song>[];

  var directives = <Directive>[];
  var sections = <Section>[];
  var chordDefs = <ChordDefinition>[];
  _OpenSection? open;
  // Set when a `start_of_X-selector(!)` directive doesn't apply for the
  // current selector set: every line until the matching `end_of_X` is
  // suppressed (still appended to the directive stream for round-trip).
  _StartKind? skipUntilEnd;
  // Set by a preceding `{ns toc=no}` (or false/0) — applied to the
  // *next* song that opens. Reset after consumption.
  var pendingTocSuppressed = false;
  // Set by a `{titles}` directive in the current song.
  TitlesAlignment? titlesAlignment;
  // Set by `{diagrams}` (or `{g}` alias) in the current song.
  DiagramsSetting? diagrams;

  void closeLoose() {
    if (open != null && open!.kind == SectionKind.loose) {
      final s = open!.finish();
      if (s != null) sections.add(s);
      open = null;
    }
  }

  void finishSong() {
    if (open != null) {
      if (open!.kind != SectionKind.loose) {
        diagnostics.add(
          Diagnostic(
            severity: DiagnosticSeverity.warning,
            message: 'Unterminated ${open!.kind.name} section at end of song.',
            span: open!.startSpan,
          ),
        );
      }
      final s = open!.finish();
      if (s != null) sections.add(s);
      open = null;
    }
    songs.add(
      Song(
        metadata: reduceMetadata(
          _expandMeta(directives, diagnostics),
          includeSelected: activeSelectors,
        ),
        directives: List.unmodifiable(directives),
        sections: List.unmodifiable(sections),
        chordDefinitions: List.unmodifiable(chordDefs),
        formatting: reduceFormatting(
          directives,
          includeSelected: activeSelectors,
        ),
        tocSuppressed: songs.isNotEmpty && pendingTocSuppressed,
        titlesAlignment: titlesAlignment,
        diagrams: diagrams,
      ),
    );
    pendingTocSuppressed = false;
    titlesAlignment = null;
    diagrams = null;
    directives = <Directive>[];
    sections = <Section>[];
    chordDefs = <ChordDefinition>[];
  }

  for (final line in lines) {
    if (line.isFileComment) continue;

    final directive = parseDirectiveLine(line);

    // Inside a selector-skipped section: consume until the matching end
    // directive arrives. Every directive is still appended to the
    // directive stream so that `Song.directives` is lossless.
    final pending = skipUntilEnd;
    if (pending != null) {
      if (directive != null) {
        directives.add(directive);
        final endKind = _endKindOf(directive.name);
        if (endKind != null &&
            endKind.kind == pending.kind &&
            (endKind.kind != SectionKind.custom ||
                endKind.customKind == pending.customKind)) {
          skipUntilEnd = null;
        }
      }
      continue;
    }

    if (directive != null) {
      directives.add(directive);

      // Song boundary always applies regardless of selectors — splitting
      // songs is structural, not conditional. The optional `toc=` attr
      // (ChordPro 6.040) is captured for the *next* song.
      if (directive.name == 'new_song' || directive.name == 'ns') {
        finishSong();
        final attrs = parseKv(directive.value ?? '');
        pendingTocSuppressed = _isFalsy(attrs['toc']);
        continue;
      }

      // Title-block alignment hint (legacy `{titles}` directive,
      // Song.pm:2204).
      if (directive.name == 'titles' && directive.value != null) {
        titlesAlignment = parseTitlesAlignment(directive.value!);
        continue;
      }

      // Diagrams setting. `{g}` is the spec-listed shorthand for
      // `{diagrams}` per Song.pm:1339.
      if (directive.name == 'diagrams' || directive.name == 'g') {
        diagrams = DiagramsSetting.fromValue(directive.value);
        continue;
      }

      // Legacy `{no_grid}` / `{ng}` — obsolete since 6.020 but still
      // accepted; equivalent to `{diagrams: off}` (Song.pm:1339).
      if (directive.name == 'no_grid' || directive.name == 'ng') {
        diagrams = const DiagramsSetting(enabled: false);
        continue;
      }

      // Selector gate. Per spec, "all directives can be conditionally
      // selected … selection applies to everything in the section, up to
      // and including the final section end directive."
      final applies = _selectorApplies(directive, activeSelectors);
      if (!applies) {
        final startKind = _startKindOf(directive.name);
        if (startKind != null) {
          skipUntilEnd = startKind;
        }
        // Non-section directives are simply suppressed; metadata and
        // formatting reducers already filter selector-tagged directives
        // independently from the directive stream.
        continue;
      }

      // Chord definitions.
      if (directive.name == 'define' || directive.name == 'chord') {
        final value = directive.value;
        if (value != null && value.isNotEmpty) {
          final def = parseChordDefinition(value, span: directive.span);
          if (def != null) {
            chordDefs.add(def);
          } else {
            diagnostics.add(
              Diagnostic(
                severity: DiagnosticSeverity.warning,
                message: 'Malformed {${directive.name}} body.',
                span: directive.span,
              ),
            );
          }
        }
        continue;
      }

      // Chorus recall: bare `{chorus}` (no value) and the labelled
      // forms `{chorus: Final}` / `{chorus: label="Final"}` per
      // ChordPro 6.060 (Song.pm:1755).
      if (directive.name == 'chorus') {
        closeLoose();
        final attrs = parseKv(directive.value ?? '', defaultKey: 'label');
        final label = attrs.remove('label');
        sections.add(
          Section(
            kind: SectionKind.chorus,
            lines: const [],
            span: directive.span,
            isChorusRecall: true,
            label: label,
            attributes: Map<String, String>.unmodifiable(attrs),
          ),
        );
        continue;
      }

      final startKind = _startKindOf(directive.name);
      if (startKind != null) {
        if (open != null && open!.kind != SectionKind.loose) {
          diagnostics.add(
            Diagnostic(
              severity: DiagnosticSeverity.warning,
              message: 'Nested or unclosed ${open!.kind.name} section; '
                  'auto-closing before ${directive.name}.',
              span: directive.span,
            ),
          );
          final s = open!.finish();
          if (s != null) sections.add(s);
          open = null;
        }
        closeLoose();
        // Parse the start-directive body as KV attributes per spec
        // (Song.pm:1382). The bare-value form
        // `{start_of_verse: Verse 1}` is treated as `label="Verse 1"`;
        // for `start_of_grid` the legacy form `{sog: 4x4}` is treated
        // as `shape="4x4"`. An explicit `label="X"` / `shape="X"`
        // always wins.
        final defaultKey =
            startKind.kind == SectionKind.grid ? 'shape' : 'label';
        final attrs = parseKv(directive.value ?? '', defaultKey: defaultKey);
        final label = attrs.remove('label');
        open = _OpenSection(
          kind: startKind.kind,
          customKind: startKind.customKind,
          label: label,
          attributes: Map<String, String>.unmodifiable(attrs),
          startSpan: directive.span,
          notesMode: notesMode,
        );
        continue;
      }

      final commentStyle = _commentStyleOf(directive.name);
      if (commentStyle != null) {
        final value = directive.value ?? '';
        open ??= _OpenSection(
          kind: SectionKind.loose,
          startSpan: directive.span,
          notesMode: notesMode,
        );
        open!.addCommentLine(
          text: value,
          style: commentStyle,
          span: directive.span,
        );
        continue;
      }

      final layoutBreak = _layoutBreakOf(directive.name);
      if (layoutBreak != null) {
        open ??= _OpenSection(
          kind: SectionKind.loose,
          startSpan: directive.span,
          notesMode: notesMode,
        );
        open!.addLayoutBreak(kind: layoutBreak, span: directive.span);
        continue;
      }

      if (directive.name == 'image') {
        final value = directive.value;
        if (value == null || value.isEmpty) {
          diagnostics.add(
            Diagnostic(
              severity: DiagnosticSeverity.warning,
              message: 'Empty {image} directive.',
              span: directive.span,
            ),
          );
          continue;
        }
        final image = parseImageDirective(value, span: directive.span);
        if (image == null) {
          diagnostics.add(
            Diagnostic(
              severity: DiagnosticSeverity.warning,
              message: 'Malformed {image} directive.',
              span: directive.span,
            ),
          );
          continue;
        }
        open ??= _OpenSection(
          kind: SectionKind.loose,
          startSpan: directive.span,
          notesMode: notesMode,
        );
        open!.addImageLine(image: image, span: directive.span);
        continue;
      }

      final endKind = _endKindOf(directive.name);
      if (endKind != null) {
        if (open == null || open!.kind == SectionKind.loose) {
          diagnostics.add(
            Diagnostic(
              severity: DiagnosticSeverity.warning,
              message: 'Stray ${directive.name} without matching start.',
              span: directive.span,
            ),
          );
          continue;
        }
        if (open!.kind != endKind.kind ||
            (endKind.kind == SectionKind.custom &&
                open!.customKind != endKind.customKind)) {
          diagnostics.add(
            Diagnostic(
              severity: DiagnosticSeverity.warning,
              message: 'Mismatched end: expected end of ${open!.kind.name}, '
                  'got ${directive.name}.',
              span: directive.span,
            ),
          );
        }
        final s = open!.finish(directive.span);
        if (s != null) sections.add(s);
        open = null;
        continue;
      }

      // Other directive — not a section boundary. It already landed in
      // `directives` above for metadata reduction and round-tripping.
      continue;
    }

    // Non-directive line: either verbatim (inside tab/grid/abc/ly) or
    // structured lyric/chord content. Blank lines outside any open
    // section are dropped.
    if (open == null) {
      if (line.isBlank) continue;
      open = _OpenSection(
        kind: SectionKind.loose,
        startSpan: line.span,
        notesMode: notesMode,
      );
    }
    open!.addLine(line);
  }

  finishSong();

  return ParseResult(songs: songs, diagnostics: diagnostics);
}

class _StartKind {
  _StartKind(this.kind, [this.customKind]);
  final SectionKind kind;
  final String? customKind;
}

_StartKind? _startKindOf(String name) {
  switch (name) {
    case 'start_of_verse':
    case 'sov':
      return _StartKind(SectionKind.verse);
    case 'start_of_chorus':
    case 'soc':
      return _StartKind(SectionKind.chorus);
    case 'start_of_bridge':
    case 'sob':
      return _StartKind(SectionKind.bridge);
    case 'start_of_tab':
    case 'sot':
      return _StartKind(SectionKind.tab);
    case 'start_of_grid':
    case 'sog':
      return _StartKind(SectionKind.grid);
    case 'start_of_abc':
      return _StartKind(SectionKind.abc);
    case 'start_of_ly':
      return _StartKind(SectionKind.ly);
    case 'start_of_svg':
      return _StartKind(SectionKind.svg);
    case 'start_of_textblock':
      return _StartKind(SectionKind.textblock);
    case 'start_of_grille':
      return _StartKind(SectionKind.grille);
  }
  if (name.startsWith('start_of_')) {
    return _StartKind(SectionKind.custom, name.substring('start_of_'.length));
  }
  return null;
}

LayoutBreak? _layoutBreakOf(String name) {
  switch (name) {
    case 'new_page':
    case 'np':
      return LayoutBreak.newPage;
    case 'new_physical_page':
    case 'npp':
      return LayoutBreak.newPhysicalPage;
    case 'column_break':
    case 'colb':
      return LayoutBreak.columnBreak;
  }
  return null;
}

CommentStyle? _commentStyleOf(String name) {
  switch (name) {
    case 'comment':
    case 'c':
      return CommentStyle.plain;
    case 'comment_italic':
    case 'ci':
      return CommentStyle.italic;
    case 'comment_box':
    case 'cb':
      return CommentStyle.box;
    case 'highlight':
      return CommentStyle.highlight;
  }
  return null;
}

/// Returns whether [d]'s selector resolves against [active] selectors.
///
/// Per the ChordPro spec, a directive without a selector always applies;
/// a positive selector (`{name-sel}`) applies when `sel` is in [active];
/// a negative selector (spec-form `{name-sel!}`, or this library's
/// non-spec `{name-!sel}` / `{name+sel}` legacy forms) applies when it
/// is not.
bool _selectorApplies(Directive d, Set<String> active) {
  final sel = d.selector;
  if (sel == null) return true;
  final isActive = active.contains(sel);
  return switch (d.polarity) {
    Polarity.positive => isActive,
    Polarity.negative => !isActive,
    Polarity.none => true,
  };
}

_StartKind? _endKindOf(String name) {
  switch (name) {
    case 'end_of_verse':
    case 'eov':
      return _StartKind(SectionKind.verse);
    case 'end_of_chorus':
    case 'eoc':
      return _StartKind(SectionKind.chorus);
    case 'end_of_bridge':
    case 'eob':
      return _StartKind(SectionKind.bridge);
    case 'end_of_tab':
    case 'eot':
      return _StartKind(SectionKind.tab);
    case 'end_of_grid':
    case 'eog':
      return _StartKind(SectionKind.grid);
    case 'end_of_abc':
      return _StartKind(SectionKind.abc);
    case 'end_of_ly':
      return _StartKind(SectionKind.ly);
    case 'end_of_svg':
      return _StartKind(SectionKind.svg);
    case 'end_of_textblock':
      return _StartKind(SectionKind.textblock);
    case 'end_of_grille':
      return _StartKind(SectionKind.grille);
  }
  if (name.startsWith('end_of_')) {
    return _StartKind(SectionKind.custom, name.substring('end_of_'.length));
  }
  return null;
}

class _OpenSection {
  _OpenSection({
    required this.kind,
    required this.startSpan,
    this.customKind,
    this.label,
    this.attributes = const {},
    this.notesMode = false,
  });

  final SectionKind kind;
  final String? customKind;
  final String? label;
  final Map<String, String> attributes;
  final SourceSpan startSpan;
  final bool notesMode;
  final List<Line> _lines = [];

  bool get isVerbatim =>
      kind == SectionKind.tab ||
      kind == SectionKind.grid ||
      kind == SectionKind.abc ||
      kind == SectionKind.ly ||
      kind == SectionKind.svg ||
      kind == SectionKind.textblock ||
      kind == SectionKind.grille;

  void addLine(RawLine line) {
    if (isVerbatim) {
      _lines.add(Line.verbatim(verbatim: line.text, span: line.span));
    } else {
      _lines.add(
        Line(
          tokens: tokenizeInline(line, notesMode: notesMode),
          span: line.span,
        ),
      );
    }
  }

  void addCommentLine({
    required String text,
    required CommentStyle style,
    required SourceSpan span,
  }) {
    _lines.add(Line.comment(comment: text, commentStyle: style, span: span));
  }

  void addImageLine({
    required ImageDirective image,
    required SourceSpan span,
  }) {
    _lines.add(Line.image(image: image, span: span));
  }

  void addLayoutBreak({
    required LayoutBreak kind,
    required SourceSpan span,
  }) {
    _lines.add(Line.layoutBreak(layoutBreak: kind, span: span));
  }

  Section? finish([SourceSpan? endSpan]) {
    if (kind == SectionKind.loose && _lines.isEmpty) return null;
    final end = endSpan ?? (_lines.isNotEmpty ? _lines.last.span : startSpan);
    return Section(
      kind: kind,
      label: label,
      customKind: customKind,
      attributes: attributes,
      lines: List.unmodifiable(_lines),
      span: SourceSpan(
        line: startSpan.line,
        column: startSpan.column,
        length: end.line == startSpan.line
            ? (end.column + end.length - startSpan.column)
            : startSpan.length,
      ),
    );
  }
}

/// Expands `{meta: key value}` directives into synthetic `{key: value}`
/// directives so [reduceMetadata] does not need to know about `meta`.
Iterable<Directive> _expandMeta(
  Iterable<Directive> directives,
  List<Diagnostic> diagnostics,
) sync* {
  for (final d in directives) {
    if (d.name != 'meta') {
      yield d;
      continue;
    }
    final value = d.value;
    if (value == null || value.isEmpty) {
      diagnostics.add(
        Diagnostic(
          severity: DiagnosticSeverity.warning,
          message: 'Empty {meta} directive.',
          span: d.span,
        ),
      );
      continue;
    }
    final space = _firstWhitespace(value);
    final String key;
    final String body;
    if (space < 0) {
      key = value;
      body = '';
    } else {
      key = value.substring(0, space);
      body = value.substring(space + 1).trimLeft();
    }
    if (key.isEmpty) {
      diagnostics.add(
        Diagnostic(
          severity: DiagnosticSeverity.warning,
          message: 'Malformed {meta} directive.',
          span: d.span,
        ),
      );
      continue;
    }
    yield Directive(
      name: key.toLowerCase(),
      selector: d.selector,
      polarity: d.polarity,
      value: body,
      span: d.span,
      fromMeta: true,
    );
  }
}

int _firstWhitespace(String s) {
  for (var i = 0; i < s.length; i++) {
    final ch = s.codeUnitAt(i);
    if (ch == 0x20 || ch == 0x09) return i;
  }
  return -1;
}

/// Returns `true` when [value] is in the ChordPro falsy keyword set
/// (`0`, `false`, `null`, `no`, `none`, `off`, or the empty string,
/// case-insensitive). Returns `false` for an absent attribute (Dart
/// `null`).
///
/// Mirrors `key_value_pairs/` from the spec: any non-empty value not in
/// the falsy set is truthy.
bool _isFalsy(String? value) {
  if (value == null) return false;
  final v = value.trim().toLowerCase();
  return v.isEmpty ||
      v == '0' ||
      v == 'false' ||
      v == 'null' ||
      v == 'no' ||
      v == 'none' ||
      v == 'off';
}

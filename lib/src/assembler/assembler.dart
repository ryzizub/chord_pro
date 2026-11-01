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
import 'package:chord_pro/src/source/preprocessor.dart';
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
///
/// [strict] mirrors the `settings.strict` ChordPro configuration option.
/// When `true`, a [DiagnosticSeverity.warning] is emitted for each song that
/// lacks a `{key}` directive. Defaults to `false`, matching the ChordPro
/// 6.100 change that flipped the built-in default from strict to forgiving.
///
/// [preprocessors] is a list of [Preprocessor] functions applied to each
/// physical source line (in order) before the scanner processes it.
/// Mirrors the `parser.preprocess` ChordPro configuration option.
///
/// [altBrackets] is the already-validated two-character alternate chord
/// bracket pair (see `ChordPro.parse`). It is applied to lyric lines only,
/// so verbatim bodies and directive values keep the characters verbatim.
ParseResult assemble(
  String source, {
  Set<String> selectors = const {},
  bool notesMode = false,
  bool strict = false,
  List<Preprocessor> preprocessors = const [],
  String? altBrackets,
}) {
  final activeSelectors = selectors.isEmpty
      ? const <String>{}
      : {for (final s in selectors) s.toLowerCase()};
  final lines = scan(_applyPreprocessors(source, preprocessors));
  final assembler = _Assembler(
    activeSelectors: activeSelectors,
    notesMode: notesMode,
    strict: strict,
    brackets: _AltBrackets.from(altBrackets),
  );
  lines.forEach(assembler.addLine);
  assembler.finishSong();
  return ParseResult(
    songs: assembler.songs,
    diagnostics: assembler.diagnostics,
  );
}

/// The single forward pass behind [assemble].
///
/// Holds the per-pass and per-song state; [addLine] dispatches each
/// [RawLine] to one method per branch, in the load-bearing order of
/// `.claude/rules/assembler.md` (ADR 0009).
class _Assembler {
  _Assembler({
    required this.activeSelectors,
    required this.notesMode,
    required this.strict,
    required this.brackets,
  });

  final Set<String> activeSelectors;
  final bool notesMode;
  final bool strict;
  final _AltBrackets? brackets;
  final diagnostics = <Diagnostic>[];
  final songs = <Song>[];

  List<Directive> directives = <Directive>[];
  List<Section> sections = <Section>[];
  List<ChordDefinition> chordDefs = <ChordDefinition>[];
  _OpenSection? open;
  // Set when a `start_of_X-selector(!)` directive doesn't apply for the
  // current selector set: every line until the matching `end_of_X` is
  // suppressed (still appended to the directive stream for round-trip).
  _StartKind? skipUntilEnd;
  // The suppressed section itself, collecting its body lines. They are
  // tokenized exactly as they would have been had the selector applied,
  // and the finished section is flagged `isSelectorSuppressed` so a
  // renderer can skip it while a re-emitter can still put the body back
  // (issue #36).
  _OpenSection? skipOpen;
  // Span of the `start_of_X` that opened [skipUntilEnd], for diagnostics.
  SourceSpan? skipStartSpan;
  // Nesting depth inside the suppressed section: a same-kind start
  // directive inside it must not be closed by the first inner end.
  int skipDepth = 0;
  // Set by a preceding `{ns toc=no}` (or false/0) — applied to the
  // *next* song that opens. Reset after consumption.
  bool pendingTocSuppressed = false;
  // Set by a `{titles}` directive in the current song.
  TitlesAlignment? titlesAlignment;
  // Set by `{diagrams}` (or `{g}` alias) in the current song.
  DiagramsSetting? diagrams;
  // A `{chorus}` recall auto-closes the section it appeared inside so the
  // recall keeps its place in `sections`. That section's own end
  // directive then has nothing left to close, and reporting it as a stray
  // end would blame the author for the parser's recovery — so it is
  // consumed silently instead.
  _StartKind? recallAutoClosed;

  void addLine(RawLine line) {
    if (line.isFileComment) return;

    final directive = parseDirectiveLine(line);

    if (_addSuppressedLine(line, directive)) return;
    if (_addOpenVerbatimLine(line, directive)) return;

    if (directive != null) {
      _addDirective(directive);
      return;
    }

    // Non-directive line: either verbatim (inside tab/grid/abc/ly) or
    // structured lyric/chord content. Blank lines outside any open
    // section are dropped.
    if (open == null) {
      if (line.isBlank) return;
      open = _OpenSection(
        kind: SectionKind.loose,
        startSpan: line.span,
        notesMode: notesMode,
        altBrackets: brackets,
      );
    }
    open!.addLine(line);
  }

  /// Flushes all per-song state into a [Song]. New per-song state must be
  /// reset here, or it leaks into the next `{new_song}`.
  void finishSong() {
    _closeSuppressedAtEndOfSong();
    _closeOpenAtEndOfSong();
    final metadata = reduceMetadata(
      _expandMeta(directives, diagnostics),
      includeSelected: activeSelectors,
      diagnostics: diagnostics,
    );
    // Checked against the reduced metadata rather than the raw directive
    // stream so `{meta: key D}` counts, and anchored on the song's own
    // first directive so the span points at the right song.
    if (strict && metadata.keys.isEmpty) {
      diagnostics.add(
        Diagnostic(
          severity: DiagnosticSeverity.warning,
          code: DiagnosticCode.missingKey,
          message: 'No {key} directive found (required by settings.strict).',
          span: directives.isEmpty
              ? const SourceSpan(line: 1, column: 1, length: 0)
              : directives.first.span,
        ),
      );
    }
    songs.add(
      Song(
        metadata: metadata,
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
    recallAutoClosed = null;
    directives = <Directive>[];
    sections = <Section>[];
    chordDefs = <ChordDefinition>[];
  }

  void _closeSuppressedAtEndOfSong() {
    if (skipUntilEnd != null) {
      diagnostics.add(
        Diagnostic(
          severity: DiagnosticSeverity.warning,
          code: DiagnosticCode.unterminatedSuppressedSection,
          message: 'Unterminated selector-suppressed '
              '${skipUntilEnd!.kind.name} section; everything up to here '
              'was suppressed.',
          span:
              skipStartSpan ?? const SourceSpan(line: 1, column: 1, length: 0),
        ),
      );
      skipUntilEnd = null;
      skipStartSpan = null;
      skipDepth = 0;
    }
    if (skipOpen != null) {
      final s = skipOpen!.finish();
      if (s != null) sections.add(s);
      skipOpen = null;
    }
  }

  void _closeOpenAtEndOfSong() {
    if (open == null) return;
    if (open!.kind != SectionKind.loose) {
      diagnostics.add(
        Diagnostic(
          severity: DiagnosticSeverity.warning,
          code: DiagnosticCode.unterminatedSection,
          message: 'Unterminated ${open!.kind.name} section at end of song.',
          span: open!.startSpan,
        ),
      );
    }
    _finishOpen();
  }

  /// Finishes the open section, which must be non-null, and appends it to
  /// `sections`.
  void _finishOpen([SourceSpan? endSpan]) {
    final s = open!.finish(endSpan);
    if (s != null) sections.add(s);
    open = null;
  }

  void _closeLoose() {
    if (open != null && open!.kind == SectionKind.loose) {
      _finishOpen();
    }
  }

  /// Ends the selector-suppressed section at its matching end directive.
  void _endSuppressed(SourceSpan endSpan) {
    skipUntilEnd = null;
    skipStartSpan = null;
    final s = skipOpen?.finish(endSpan);
    if (s != null) sections.add(s);
    skipOpen = null;
  }

  /// Handles [line] when it falls inside a selector-suppressed section.
  /// Returns `false` when there is no such section, or when [line] is a
  /// song boundary that ends it.
  bool _addSuppressedLine(RawLine line, Directive? directive) {
    // Inside a selector-skipped section: consume until the matching end
    // directive arrives. Every directive is still appended to the
    // directive stream so that `Song.directives` is lossless — except in
    // a verbatim environment, where the body holds no directives to
    // begin with (see [_addSuppressedVerbatimLine]).
    final pending = skipUntilEnd;
    if (pending == null) return false;
    if (_isVerbatimKind(pending.kind)) {
      _addSuppressedVerbatimLine(line, directive, pending);
      return true;
    }
    // A song boundary is structural and is never conditional, so it ends
    // the suppression rather than being swallowed by it. Falling through
    // (instead of consuming the line) hands the directive to the
    // `{new_song}` branch of [_addDirective], and `finishSong()` reports
    // the unterminated section.
    if (directive != null && _isSongBoundary(directive.name)) return false;
    if (directive != null) {
      _addSuppressedDirective(directive, pending);
      return true;
    }
    // A body line of the suppressed section. Directives inside the
    // range are deliberately not turned into lines: they are already
    // in the directive stream, and re-running them here would apply
    // song-level settings the selector said to skip.
    skipOpen?.addLine(line);
    return true;
  }

  void _addSuppressedVerbatimLine(
    RawLine line,
    Directive? directive,
    _StartKind pending,
  ) {
    // A suppressed verbatim environment obeys the same rule as an open
    // one (see [_addOpenVerbatimLine]): only the matching end directive
    // is a directive, so nothing in the body reaches the directive
    // stream — not even a song boundary. Nesting cannot occur, since an
    // inner `{start_of_X}` is body text too. The body itself is still
    // kept on the suppressed section (issue #36), just as verbatim lines.
    if (directive != null &&
        _sameSection(_endKindOf(directive.name), pending)) {
      directives.add(directive);
      _endSuppressed(directive.span);
    } else {
      skipOpen?.addLine(line);
    }
  }

  void _addSuppressedDirective(Directive directive, _StartKind pending) {
    directives.add(directive);
    if (_sameSection(_startKindOf(directive.name), pending)) {
      // Nested section of the same kind: it must be closed before the
      // suppressed one is.
      skipDepth++;
    } else if (_sameSection(_endKindOf(directive.name), pending)) {
      if (skipDepth > 0) {
        skipDepth--;
      } else {
        _endSuppressed(directive.span);
      }
    }
  }

  /// Adds [line] to an open verbatim section unless it is that section's
  /// end directive. Returns whether [line] was consumed.
  bool _addOpenVerbatimLine(RawLine line, Directive? directive) {
    // Inside a verbatim environment the body is printed as-is, so only
    // the matching `end_of_X` is interpreted; every other line — brace
    // leading or not — is body text (Song.pm:622 for tab, Song.pm:631
    // for the delegated environments, both of which test for their own
    // end directive before the generic directive branch is reached).
    final openVerbatim = open;
    if (openVerbatim == null || !openVerbatim.isVerbatim) return false;
    final closes = directive != null &&
        _sameSection(
          _endKindOf(directive.name),
          _StartKind(openVerbatim.kind, openVerbatim.customKind),
        );
    if (closes) return false;
    openVerbatim.addLine(line);
    return true;
  }

  void _addDirective(Directive directive) {
    // Every directive lands in the stream before any branch decides what
    // else to do with it: `Song.directives` is lossless (ADR 0004).
    directives.add(directive);

    // Song boundary always applies regardless of selectors — splitting
    // songs is structural, not conditional. The optional `toc=` attr
    // (ChordPro 6.040) is captured for the *next* song.
    if (_isSongBoundary(directive.name)) {
      finishSong();
      final attrs = parseKv(directive.value ?? '');
      pendingTocSuppressed = _isFalsy(attrs['toc']);
      return;
    }

    if (_applySongSetting(directive)) return;

    // Selector gate. Per spec, "all directives can be conditionally
    // selected … selection applies to everything in the section, up to
    // and including the final section end directive."
    if (!_selectorApplies(directive, activeSelectors)) {
      _suppress(directive);
      return;
    }

    _addApplyingDirective(directive);
  }

  /// Applies a song-level setting directive. Returns whether [directive]
  /// was one, whether or not its selector applies.
  bool _applySongSetting(Directive directive) {
    final name = directive.name;
    // Settings are conditional like every other directive: "all
    // directives can be conditionally selected"
    // (https://www.chordpro.org/chordpro/chordpro-configuration-selectors/).
    // A suppressed setting is still consumed here, and it already sits in
    // the directive stream.
    final applies = _selectorApplies(directive, activeSelectors);

    // Title-block alignment hint (legacy `{titles}` directive,
    // Song.pm:2204).
    if (name == 'titles' && directive.value != null) {
      if (applies) titlesAlignment = parseTitlesAlignment(directive.value!);
      return true;
    }

    // Diagrams setting. `{g}` is the spec-listed shorthand for
    // `{diagrams}` per Song.pm:1339.
    if (name == 'diagrams' || name == 'g') {
      if (applies) diagrams = DiagramsSetting.fromValue(directive.value);
      return true;
    }

    // Legacy `{no_grid}` / `{ng}` — obsolete since 6.020 but still
    // accepted; equivalent to `{diagrams: off}` (Song.pm:1339).
    if (name == 'no_grid' || name == 'ng') {
      if (applies) diagrams = const DiagramsSetting(enabled: false);
      return true;
    }
    return false;
  }

  /// Handles a directive whose selector does not apply.
  void _suppress(Directive directive) {
    // Non-section directives are simply suppressed; metadata and
    // formatting reducers already filter selector-tagged directives
    // independently from the directive stream.
    final startKind = _startKindOf(directive.name);
    if (startKind == null) return;
    skipUntilEnd = startKind;
    skipStartSpan = directive.span;
    skipDepth = 0;
    // The body is captured rather than dropped, so the suppressed
    // section is opened exactly as an applying one would be — same
    // auto-close of an enclosing section, same attribute parsing,
    // same tokenization — and only the flag differs.
    skipOpen = _startSection(startKind, directive, isSelectorSuppressed: true);
  }

  void _addApplyingDirective(Directive directive) {
    final name = directive.name;

    // Chord definitions.
    if (name == 'define' || name == 'chord') {
      _addChordDefinition(directive);
      return;
    }

    // Chorus recall: bare `{chorus}` (no value) and the labelled
    // forms `{chorus: Final}` / `{chorus: label="Final"}` per
    // ChordPro 6.060 (Song.pm:1755).
    if (name == 'chorus') {
      _addChorusRecall(directive);
      return;
    }

    final startKind = _startKindOf(name);
    if (startKind != null) {
      open = _startSection(startKind, directive);
      return;
    }

    final commentStyle = _commentStyleOf(name);
    if (commentStyle != null) {
      _looseSection(directive.span).addCommentLine(
        text: directive.value ?? '',
        style: commentStyle,
        span: directive.span,
      );
      return;
    }

    final layoutBreak = _layoutBreakOf(name);
    if (layoutBreak != null) {
      _looseSection(directive.span)
          .addLayoutBreak(kind: layoutBreak, span: directive.span);
      return;
    }

    if (name == 'image') {
      _addImage(directive);
      return;
    }

    final endKind = _endKindOf(name);
    if (endKind != null) {
      _endSection(directive, endKind);
      return;
    }

    // Other directive — not a section boundary. It already landed in
    // `directives` in [_addDirective] for metadata reduction and
    // round-tripping.
  }

  void _addChordDefinition(Directive directive) {
    final value = directive.value;
    if (value == null || value.isEmpty) return;
    final def = parseChordDefinition(value, span: directive.span);
    if (def != null) {
      chordDefs.add(def);
    } else {
      diagnostics.add(
        Diagnostic(
          severity: DiagnosticSeverity.warning,
          code: DiagnosticCode.malformedChordDefinition,
          message: 'Malformed {${directive.name}} body.',
          span: directive.span,
        ),
      );
    }
  }

  void _addChorusRecall(Directive directive) {
    // A recall is a section of its own, so an open section has to be
    // closed first — otherwise the recall would be appended to
    // `sections` ahead of the section it appeared inside.
    if (open != null && open!.kind != SectionKind.loose) {
      diagnostics.add(
        Diagnostic(
          severity: DiagnosticSeverity.warning,
          code: DiagnosticCode.chorusRecallInsideSection,
          message: '{chorus} recall inside an open ${open!.kind.name} '
              'section; auto-closing before the recall.',
          span: directive.span,
        ),
      );
      recallAutoClosed = _StartKind(open!.kind, open!.customKind);
      _finishOpen();
    }
    _closeLoose();
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
  }

  /// Closes whatever section is open and returns a new section of
  /// [startKind] opened by [directive]. Shared by applying and
  /// selector-suppressed start directives.
  _OpenSection _startSection(
    _StartKind startKind,
    Directive directive, {
    bool isSelectorSuppressed = false,
  }) {
    if (open != null && open!.kind != SectionKind.loose) {
      diagnostics.add(
        Diagnostic(
          severity: DiagnosticSeverity.warning,
          code: DiagnosticCode.nestedSection,
          message: 'Nested or unclosed ${open!.kind.name} section; '
              'auto-closing before ${directive.name}.',
          span: directive.span,
        ),
      );
      _finishOpen();
    }
    _closeLoose();
    // Parse the start-directive body as KV attributes per spec
    // (Song.pm:1382). The bare-value form
    // `{start_of_verse: Verse 1}` is treated as `label="Verse 1"`;
    // for `start_of_grid` the legacy form `{sog: 4x4}` is treated
    // as `shape="4x4"`. An explicit `label="X"` / `shape="X"`
    // always wins.
    final defaultKey = startKind.kind == SectionKind.grid ? 'shape' : 'label';
    final attrs = parseKv(directive.value ?? '', defaultKey: defaultKey);
    final label = attrs.remove('label');
    recallAutoClosed = null;
    return _OpenSection(
      kind: startKind.kind,
      customKind: startKind.customKind,
      label: label,
      attributes: Map<String, String>.unmodifiable(attrs),
      startSpan: directive.span,
      notesMode: notesMode,
      altBrackets: brackets,
      isSelectorSuppressed: isSelectorSuppressed,
    );
  }

  /// The open section, or a new loose one starting at [span] when none is
  /// open.
  _OpenSection _looseSection(SourceSpan span) => open ??= _OpenSection(
        kind: SectionKind.loose,
        startSpan: span,
        notesMode: notesMode,
        altBrackets: brackets,
      );

  void _addImage(Directive directive) {
    final value = directive.value;
    if (value == null || value.isEmpty) {
      diagnostics.add(
        Diagnostic(
          severity: DiagnosticSeverity.warning,
          code: DiagnosticCode.emptyImage,
          message: 'Empty {image} directive.',
          span: directive.span,
        ),
      );
      return;
    }
    final image = parseImageDirective(value, span: directive.span);
    if (image == null) {
      diagnostics.add(
        Diagnostic(
          severity: DiagnosticSeverity.warning,
          code: DiagnosticCode.malformedImage,
          message: 'Malformed {image} directive.',
          span: directive.span,
        ),
      );
      return;
    }
    _looseSection(directive.span)
        .addImageLine(image: image, span: directive.span);
  }

  void _endSection(Directive directive, _StartKind endKind) {
    final autoClosed = recallAutoClosed;
    if (autoClosed != null && _sameSection(endKind, autoClosed)) {
      recallAutoClosed = null;
      return;
    }
    if (open == null || open!.kind == SectionKind.loose) {
      diagnostics.add(
        Diagnostic(
          severity: DiagnosticSeverity.warning,
          code: DiagnosticCode.strayEnd,
          message: 'Stray ${directive.name} without matching start.',
          span: directive.span,
        ),
      );
      return;
    }
    if (open!.kind != endKind.kind ||
        (endKind.kind == SectionKind.custom &&
            open!.customKind != endKind.customKind)) {
      diagnostics.add(
        Diagnostic(
          severity: DiagnosticSeverity.warning,
          code: DiagnosticCode.mismatchedEnd,
          message: 'Mismatched end: expected end of ${open!.kind.name}, '
              'got ${directive.name}.',
          span: directive.span,
        ),
      );
    }
    _finishOpen(directive.span);
  }
}

/// Whether [name] is the `{new_song}` song boundary or its `{ns}` alias.
bool _isSongBoundary(String name) => name == 'new_song' || name == 'ns';

class _StartKind {
  _StartKind(this.kind, [this.customKind]);
  final SectionKind kind;
  final String? customKind;
}

/// Whether a section of [kind] has a body that is captured verbatim —
/// no inline tokenization, and no directive recognition beyond its own
/// `end_of_X` (Song.pm:622, Song.pm:631).
bool _isVerbatimKind(SectionKind kind) =>
    kind == SectionKind.tab ||
    kind == SectionKind.grid ||
    kind == SectionKind.abc ||
    kind == SectionKind.ly ||
    kind == SectionKind.svg ||
    kind == SectionKind.textblock ||
    kind == SectionKind.grille;

/// Whether [candidate] names the same section as [target], taking the
/// custom-environment name into account.
bool _sameSection(_StartKind? candidate, _StartKind target) =>
    candidate != null &&
    candidate.kind == target.kind &&
    (candidate.kind != SectionKind.custom ||
        candidate.customKind == target.customKind);

/// The validated alternate chord bracket pair (`parser.altbrackets`).
class _AltBrackets {
  const _AltBrackets(this.open, this.close);

  /// Returns `null` when no pair was configured.
  static _AltBrackets? from(String? pair) {
    if (pair == null) return null;
    final runes = pair.runes.toList(growable: false);
    return _AltBrackets(
      String.fromCharCode(runes[0]),
      String.fromCharCode(runes[1]),
    );
  }

  final String open;
  final String close;

  String apply(String text) =>
      text.replaceAll(open, '[').replaceAll(close, ']');
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
  // A selector is only ever recorded together with a positive or negative
  // polarity (see `_parseInner` in directive_parser.dart), so there is no
  // `Polarity.none` case to handle here.
  return d.polarity == Polarity.negative ? !isActive : isActive;
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
    this.altBrackets,
    this.isSelectorSuppressed = false,
  });

  final SectionKind kind;
  final String? customKind;
  final String? label;
  final Map<String, String> attributes;
  final SourceSpan startSpan;
  final bool notesMode;
  final _AltBrackets? altBrackets;
  final bool isSelectorSuppressed;
  final List<Line> _lines = [];

  bool get isVerbatim => _isVerbatimKind(kind);

  void addLine(RawLine line) {
    if (isVerbatim) {
      // Verbatim bodies are handed to a delegate untouched, so the
      // alternate bracket pair is deliberately *not* rewritten here.
      _lines.add(Line.verbatim(verbatim: line.text, span: line.span));
    } else {
      final brackets = altBrackets;
      final source = brackets == null
          ? line
          : RawLine(number: line.number, text: brackets.apply(line.text));
      _lines.add(
        Line(
          tokens: tokenizeInline(source, notesMode: notesMode),
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
      isSelectorSuppressed: isSelectorSuppressed,
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
///
/// Only the metadata reduction sees the expansion: per the reference
/// implementation `{meta}` declares *metadata* items, so
/// `{meta: textfont Times}` is metadata named `textfont`, not a
/// `{textfont}` formatting directive, and [reduceFormatting] is
/// deliberately given the unexpanded stream.
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
          code: DiagnosticCode.emptyMeta,
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
    // `value` is trimmed and non-empty here, so the key is never empty:
    // `_firstWhitespace` can only return -1 (no whitespace at all) or an
    // index past the first character.
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

/// Applies [preprocessors] to each physical line in [source] and rejoins
/// with `\n`. Line endings are normalised to `\n` before splitting so
/// Windows (`\r\n`) and classic Mac (`\r`) inputs are handled uniformly.
/// If [preprocessors] is empty the original [source] is returned unchanged.
String _applyPreprocessors(String source, List<Preprocessor> preprocessors) {
  if (preprocessors.isEmpty) return source;
  final normalised = source.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
  final lines = normalised.split('\n');
  final result = StringBuffer();
  for (var i = 0; i < lines.length; i++) {
    var line = lines[i];
    for (final p in preprocessors) {
      line = p(line);
    }
    if (i > 0) result.write('\n');
    result.write(line);
  }
  return result.toString();
}

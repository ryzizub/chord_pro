/// Parser for the [ChordPro 6 song format](https://www.chordpro.org/).
///
/// Use `ChordPro.parse` to parse a document into songs plus diagnostics,
/// or `ChordPro.parseSong` to get the first song directly. Each `Song`
/// exposes typed metadata, ordered sections of lines, parsed chord
/// definitions, formatting settings and the raw directive stream.
library;

export 'src/ast/diagrams_setting.dart' show DiagramsPosition, DiagramsSetting;
export 'src/ast/formatting.dart' show FormattingProps, FormattingSettings;
export 'src/ast/grid_attributes.dart' show GridAttributes;
export 'src/ast/line.dart' show CommentStyle, LayoutBreak, Line, LineKind;
export 'src/ast/metadata.dart' show Metadata;
export 'src/ast/section.dart' show Section, SectionKind;
export 'src/ast/song.dart' show Song;
export 'src/ast/textblock_attributes.dart' show TextblockAttributes;
export 'src/ast/titles_alignment.dart' show TitlesAlignment;
export 'src/ast/transpose_qualifier.dart' show TransposeQualifier;
export 'src/chord/chord.dart'
    show AccidentalPreference, Chord, ChordSystem, transposeRoot;
export 'src/chord/chord_definition.dart'
    show ChordDefinition, parseChordDefinition;
export 'src/chord_pro.dart' show ChordPro;
export 'src/diagnostic/diagnostic.dart' show Diagnostic, DiagnosticSeverity;
export 'src/diagnostic/parse_result.dart' show ParseResult;
export 'src/directive/directive.dart' show Directive, Polarity;
export 'src/directive/directive_parser.dart'
    show DirectiveMatch, parseDirectiveAt, parseDirectiveLine;
export 'src/directive/image_directive.dart'
    show ImageAnchor, ImageDirective, parseImageDirective;
export 'src/inline/inline_token.dart'
    show
        AnnotationToken,
        ChordToken,
        InlineDirectiveToken,
        InlineToken,
        TextToken;
export 'src/inline/inline_tokenizer.dart' show tokenizeInline;
export 'src/source/raw_line.dart' show RawLine;
export 'src/source/scanner.dart' show scan;
export 'src/source/source_span.dart' show SourceSpan;

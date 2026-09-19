import 'package:chord_pro/src/source/source_span.dart';

/// Severity of a [Diagnostic].
enum DiagnosticSeverity {
  /// Something the parser recovered from.
  warning,

  /// Something the parser could not recover from locally.
  error,
}

/// Stable identifier for what a [Diagnostic] reports.
///
/// Prefer switching on this over matching [Diagnostic.message], which is
/// prose meant for humans and may be reworded in any release.
enum DiagnosticCode {
  /// A `{start_of_X}` section was still open at the end of the song.
  unterminatedSection,

  /// A selector-suppressed `{start_of_X}` section was still open at the
  /// end of the song, so everything after it was suppressed.
  unterminatedSuppressedSection,

  /// A `{start_of_X}` arrived while another section was still open; the
  /// open one was closed automatically.
  nestedSection,

  /// An `{end_of_X}` arrived with no matching start directive.
  strayEnd,

  /// An `{end_of_X}` closed a section of a different kind.
  mismatchedEnd,

  /// A `{chorus}` recall appeared inside an open section; the open
  /// section was closed automatically so source order is preserved.
  chorusRecallInsideSection,

  /// `settings.strict` is on and the song declares no `{key}`.
  missingKey,

  /// A `{define}` / `{chord}` body could not be parsed.
  malformedChordDefinition,

  /// An `{image}` directive carried no body.
  emptyImage,

  /// An `{image}` body carried no usable attributes.
  malformedImage,

  /// A `{meta}` directive carried no body.
  emptyMeta,

  /// A metadata directive that requires a whole number got something
  /// else (for example `{capo: high}`).
  invalidNumericValue,
}

/// A single diagnostic message with positional information.
class Diagnostic {
  /// Creates a new [Diagnostic].
  const Diagnostic({
    required this.severity,
    required this.code,
    required this.message,
    required this.span,
  });

  /// How severe the diagnostic is.
  final DiagnosticSeverity severity;

  /// Stable, machine-readable identifier for this diagnostic.
  final DiagnosticCode code;

  /// Human-readable message. Not stable across releases — switch on
  /// [code] instead.
  final String message;

  /// Location in the source the diagnostic refers to.
  final SourceSpan span;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Diagnostic &&
          other.severity == severity &&
          other.code == code &&
          other.message == message &&
          other.span == span;

  @override
  int get hashCode => Object.hash(severity, code, message, span);

  @override
  String toString() => '[${severity.name}] $span: $message';
}

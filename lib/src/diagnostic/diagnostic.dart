import 'package:chord_pro/src/source/source_span.dart';

/// Severity of a [Diagnostic].
enum DiagnosticSeverity {
  /// Something the parser recovered from.
  warning,

  /// Something the parser could not recover from locally.
  error,
}

/// A single diagnostic message with positional information.
class Diagnostic {
  /// Creates a new [Diagnostic].
  const Diagnostic({
    required this.severity,
    required this.message,
    required this.span,
  });

  /// How severe the diagnostic is.
  final DiagnosticSeverity severity;

  /// Human-readable message.
  final String message;

  /// Location in the source the diagnostic refers to.
  final SourceSpan span;

  @override
  String toString() => '[${severity.name}] $span: $message';
}

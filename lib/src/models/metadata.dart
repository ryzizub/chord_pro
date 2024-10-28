import 'package:chord_pro/src/models/directive.dart';

/// The entry point of the Metada
class Metadata with DirectiveMixin<Metadata> {
  /// Holds info the song like [title] etc.
  Metadata({
    this.title,
  });

  /// Creates instance of [Metadata] from created map of already
  /// parsed content of Chordpro
  factory Metadata.fromMap(Map<String, String?> map) {
    final title = map['title'];

    return Metadata(
      title: title,
    );
  }

  /// The title of the song
  final String? title;

  @override
  bool isEmpty() {
    return [
      title,
    ].nonNulls.isEmpty;
  }
}

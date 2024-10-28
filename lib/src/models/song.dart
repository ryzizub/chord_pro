import 'package:chord_pro/src/models/metadata.dart';

/// The entry point of the Song
class Song {
  /// Song information
  Song({
    this.metadata,
  });

  /// Associated metadata of the song
  final Metadata? metadata;
}

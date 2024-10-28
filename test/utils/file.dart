import 'dart:io';

String getTestSongBody() {
  final file = File('./example_song.chopro');
  final content = file.readAsStringSync();

  return content;
}

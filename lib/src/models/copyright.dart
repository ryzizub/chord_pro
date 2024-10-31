/// The entry point of the Metada
class Copyright {
  /// Holds copyright info the song
  Copyright({
    required this.owner,
    required this.year,
  });

  /// Creates instance of [Copyright] from directive content string
  factory Copyright.fromString(String directiveContent) {
    final contentSplit = directiveContent.split(' ');

    final year = int.parse(contentSplit[0]);
    final owner = contentSplit[1];

    return Copyright(
      owner: owner,
      year: year,
    );
  }

  /// Owner of the copyright
  final String owner;

  /// Year of the copyright
  final int year;
}

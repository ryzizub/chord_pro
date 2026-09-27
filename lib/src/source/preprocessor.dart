/// A function that transforms a single source line before parsing.
///
/// Used with the `ChordPro.parse` `preprocessors` parameter to implement
/// the `parser.preprocess` ChordPro configuration option. Each preprocessor
/// receives one physical line of the source (before continuation-line joining
/// and Unicode-escape resolution) and returns the transformed line.
///
/// Preprocessors are applied in list order; the output of each is the input
/// to the next.
typedef Preprocessor = String Function(String line);

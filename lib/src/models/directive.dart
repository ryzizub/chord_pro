/// General class for all directives in the song
mixin DirectiveMixin<X> {
  /// Returns info if the current directive have any value set
  bool isEmpty();

  /// Returns directive if not empty otherwise its null
  X? get value => isEmpty() ? null : this as X;
}

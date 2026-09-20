/// Element-wise equality for two lists.
///
/// Used by the AST value types, which compare structurally. Kept here so
/// the package stays free of runtime dependencies (`package:collection`
/// would otherwise provide this).
bool listEquals<T>(List<T> a, List<T> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// Entry-wise equality for two maps.
bool mapEquals<K, V>(Map<K, V> a, Map<K, V> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (final entry in a.entries) {
    if (!b.containsKey(entry.key)) return false;
    if (b[entry.key] != entry.value) return false;
  }
  return true;
}

/// Order-independent hash for a map, consistent with [mapEquals].
int mapHash<K, V>(Map<K, V> map) {
  var hash = 0;
  for (final entry in map.entries) {
    // XOR so the result does not depend on iteration order.
    hash ^= Object.hash(entry.key, entry.value);
  }
  return Object.hash(map.length, hash);
}

/// Equality for a map whose values are lists, compared element-wise.
bool mapOfListsEquals<K, V>(Map<K, List<V>> a, Map<K, List<V>> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (final entry in a.entries) {
    final other = b[entry.key];
    if (other == null) return false;
    if (!listEquals(entry.value, other)) return false;
  }
  return true;
}

/// Order-independent hash for a map of lists, consistent with
/// [mapOfListsEquals].
int mapOfListsHash<K, V>(Map<K, List<V>> map) {
  var hash = 0;
  for (final entry in map.entries) {
    hash ^= Object.hash(entry.key, Object.hashAll(entry.value));
  }
  return Object.hash(map.length, hash);
}

/// Maps between the frontend difficulty labels and the backend 1–3 levels.
library;

const List<String> _difficultyLabels = ['easy', 'medium', 'hard'];

/// Convert a frontend difficulty label ('easy' | 'medium' | 'hard') to the
/// backend difficulty level (1–3). Unknown labels map to 1.
int difficultyToInt(String difficulty) {
  final index = _difficultyLabels.indexOf(difficulty.toLowerCase());
  return index == -1 ? 1 : index + 1;
}

/// Convert a backend difficulty level (1–3) to a frontend label.
/// Out-of-range values map to 'easy'.
String difficultyToString(int level) {
  if (level >= 1 && level <= _difficultyLabels.length) {
    return _difficultyLabels[level - 1];
  }
  return 'easy';
}

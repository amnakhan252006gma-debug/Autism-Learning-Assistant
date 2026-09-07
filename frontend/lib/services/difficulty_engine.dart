import '../models/performance_analysis.dart';

class DifficultyDecision {
  final String category;
  final String previousDifficulty;
  final String difficulty;
  final DifficultyAdjustment adjustment;
  final String reason;

  const DifficultyDecision({
    required this.category,
    required this.previousDifficulty,
    required this.difficulty,
    required this.adjustment,
    required this.reason,
  });
}

enum DifficultyAdjustment { increase, keep, decrease }

/// Converts performance into an appropriate next difficulty.
///
/// This is deliberately deterministic and local today, while keeping a small
/// API that can later accept a backend/AI decision.
class DifficultyEngine {
  static const List<String> levels = ['easy', 'medium', 'hard'];

  const DifficultyEngine();

  DifficultyDecision chooseDifficulty({
    required String category,
    required String currentDifficulty,
    required PerformanceAnalysis analysis,
  }) {
    final performance = analysis.categoryPerformance[category];
    final currentIndex = _indexOf(currentDifficulty);

    if (performance == null) {
      return DifficultyDecision(
        category: category,
        previousDifficulty: currentDifficulty,
        difficulty: currentDifficulty,
        adjustment: DifficultyAdjustment.keep,
        reason: 'Not enough performance data yet, so we will keep the current level.',
      );
    }

    final strong = performance.activitiesCompleted >= 2 &&
        performance.recentAccuracy >= 80 &&
        performance.improvement >= 0;
    final weak = performance.recentAccuracy < 60;

    if (strong && currentIndex < levels.length - 1) {
      final next = levels[currentIndex + 1];
      return DifficultyDecision(
        category: category,
        previousDifficulty: currentDifficulty,
        difficulty: next,
        adjustment: DifficultyAdjustment.increase,
        reason: 'Recent performance is consistently strong, so the level can increase.',
      );
    }

    if (weak && currentIndex > 0) {
      final next = levels[currentIndex - 1];
      return DifficultyDecision(
        category: category,
        previousDifficulty: currentDifficulty,
        difficulty: next,
        adjustment: DifficultyAdjustment.decrease,
        reason: 'Recent performance is weak, so extra practice at an easier level is recommended.',
      );
    }

    return DifficultyDecision(
      category: category,
      previousDifficulty: currentDifficulty,
      difficulty: currentDifficulty,
      adjustment: DifficultyAdjustment.keep,
      reason: 'Performance is moderate or already at a suitable level, so the difficulty stays the same.',
    );
  }

  int _indexOf(String difficulty) {
    final index = levels.indexOf(difficulty.toLowerCase());
    return index == -1 ? 0 : index;
  }
}

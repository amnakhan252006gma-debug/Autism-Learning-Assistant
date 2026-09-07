import 'package:flutter/material.dart';

import '../models/activity_question.dart';
import '../services/backend_service.dart';
import '../services/mock_activity_data.dart';
import '../theme/app_theme.dart';
import 'activity_screen.dart';

class LearningScreen extends StatefulWidget {
  final int childId;

  const LearningScreen({super.key, required this.childId});

  @override
  State<LearningScreen> createState() => _LearningScreenState();
}

class _LearningScreenState extends State<LearningScreen> {
  late Future<_LearningData> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadLearningData();
  }

  // ═══════════════════════════════════════════════════════════════
  // LOAD DATA
  // ═══════════════════════════════════════════════════════════════

  Future<_LearningData> _loadLearningData() async {
    final activities = await BackendService.instance.getActivities();

    Map<String, dynamic>? recommendations;

    try {
      recommendations = await BackendService.instance.getRecommendations(
        widget.childId,
      );
    } catch (_) {
      // Activities remain usable even if recommendations
      // temporarily fail.
    }

    return _LearningData(
      activities: activities,
      recommendations: recommendations,
    );
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _loadLearningData();
    });
  }

  // ═══════════════════════════════════════════════════════════════
  // QUESTION SELECTION
  // ═══════════════════════════════════════════════════════════════

  /// IMPORTANT:
  /// The backend sends difficulty 1, 2 or 3.
  ///
  /// We now use that difficulty to select DIFFERENT questions.
  ///
  /// Level 1 → Starter questions
  /// Level 2 → Practice questions
  /// Level 3 → Challenge questions
  List<ActivityQuestion> _questions(String category, int difficulty) {
    return MockActivityData.questionsFor(category, difficulty);
  }

  // ═══════════════════════════════════════════════════════════════
  // CATEGORY HELPERS
  // ═══════════════════════════════════════════════════════════════

  Color _color(String category) {
    switch (category.toLowerCase().trim()) {
      case 'shapes':
      case 'shape':
        return AppTheme.routineColor;

      case 'numbers':
      case 'number':
        return AppTheme.gamesColor;

      case 'words':
      case 'word':
        return AppTheme.communicateColor;

      case 'colors':
      case 'color':
      default:
        return AppTheme.learnColor;
    }
  }

  String _emoji(String category) {
    switch (category.toLowerCase().trim()) {
      case 'shapes':
      case 'shape':
        return '🔷';

      case 'numbers':
      case 'number':
        return '🔢';

      case 'words':
      case 'word':
        return '🔤';

      case 'colors':
      case 'color':
      default:
        return '🎨';
    }
  }

  String _categoryName(String category) {
    final value = category.trim();

    if (value.isEmpty) {
      return 'Activity';
    }

    return value[0].toUpperCase() + value.substring(1);
  }

  // ═══════════════════════════════════════════════════════════════
  // RECOMMENDATION HELPERS
  // ═══════════════════════════════════════════════════════════════

  Map<String, dynamic>? _recommendationFor(
    Map<String, dynamic>? recommendations,
    String category,
  ) {
    final list = recommendations?['recommendations'];

    if (list is! List) {
      return null;
    }

    for (final item in list) {
      if (item is Map<String, dynamic>) {
        final itemCategory = item['category']?.toString().toLowerCase().trim();

        if (itemCategory == category.toLowerCase().trim()) {
          return item;
        }
      }
    }

    return null;
  }

  int _difficultyFor(
    Map<String, dynamic>? recommendations,
    String category,
    int fallback,
  ) {
    // First use the backend difficulty map.
    final difficultyMap = recommendations?['difficulty'];

    if (difficultyMap is Map<String, dynamic>) {
      final raw = difficultyMap[category.toLowerCase().trim()];

      if (raw is Map<String, dynamic>) {
        final nextDifficulty = raw['next_difficulty'];

        if (nextDifficulty is num) {
          return nextDifficulty.toInt().clamp(1, 3);
        }
      }
    }

    // Then check the recommendation itself.
    final recommendation = _recommendationFor(recommendations, category);

    final recommendedDifficulty = recommendation?['difficulty'];

    if (recommendedDifficulty is num) {
      return recommendedDifficulty.toInt().clamp(1, 3);
    }

    // Finally use activity's backend difficulty.
    return fallback.clamp(1, 3);
  }

  String _levelLabel(int difficulty) {
    switch (difficulty) {
      case 3:
        return 'Level 3 • Challenge';

      case 2:
        return 'Level 2 • Practice';

      default:
        return 'Level 1 • Starter';
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // OPEN ACTIVITY
  // ═══════════════════════════════════════════════════════════════

  Future<void> _openActivity({
    required BuildContext context,
    required Map<String, dynamic> activity,
    required Map<String, dynamic>? recommendations,
  }) async {
    final category = activity['category']?.toString() ?? '';

    final activityId = activity['id'];

    if (activityId is! int) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This activity is missing a valid ID.')),
      );
      return;
    }

    // Difficulty determined by backend adaptive learning.
    final backendDifficulty = activity['difficulty'] is num
        ? (activity['difficulty'] as num).toInt()
        : 1;

    final personalizedDifficulty = _difficultyFor(
      recommendations,
      category,
      backendDifficulty,
    );

    // THIS IS THE IMPORTANT PART.
    //
    // The difficulty now determines the actual question bank.
    final questions = _questions(category, personalizedDifficulty);

    if (questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No questions are available for $category at Level $personalizedDifficulty yet.',
          ),
        ),
      );
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ActivityScreen(
          childId: widget.childId,
          activityId: activityId,
          title: activity['name']?.toString() ?? 'Learning Activity',
          color: _color(category),

          // REAL LEVEL-SPECIFIC QUESTIONS
          questions: questions,

          // BACKEND PERSONALIZED DIFFICULTY
          difficulty: personalizedDifficulty,
        ),
      ),
    );

    // Reload backend recommendations after activity completion.
    if (mounted) {
      await _refresh();
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Learn'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, size: 32),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FutureBuilder<_LearningData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _ErrorState(
              message: 'Could not load learning activities.',
              onRetry: _refresh,
            );
          }

          final data = snapshot.data ?? const _LearningData(activities: []);

          final activities = data.activities;

          if (activities.isEmpty) {
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppTheme.spaceLG),
                children: const [
                  SizedBox(height: 120),
                  Icon(Icons.menu_book_rounded, size: 72),
                  SizedBox(height: AppTheme.spaceMD),
                  Center(
                    child: Text(
                      'No learning activities are available yet.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.spaceLG,
                AppTheme.spaceLG,
                AppTheme.spaceLG,
                AppTheme.spaceXL,
              ),
              children: [
                _buildRecommendationBanner(data.recommendations),

                const SizedBox(height: AppTheme.spaceLG),

                Text(
                  'Choose an activity',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),

                const SizedBox(height: AppTheme.spaceSM),

                Text(
                  'Your activities automatically adjust to your learning progress.',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: AppTheme.spaceMD),

                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: AppTheme.spaceMD,
                    crossAxisSpacing: AppTheme.spaceMD,
                    childAspectRatio: .9,
                  ),
                  itemCount: activities.length,
                  itemBuilder: (context, index) {
                    final activity = activities[index];

                    final category = activity['category']?.toString() ?? '';

                    final backendDifficulty = activity['difficulty'] is num
                        ? (activity['difficulty'] as num).toInt()
                        : 1;

                    final personalizedDifficulty = _difficultyFor(
                      data.recommendations,
                      category,
                      backendDifficulty,
                    );

                    final recommendation = _recommendationFor(
                      data.recommendations,
                      category,
                    );

                    // Check that this category actually
                    // has questions for its personalized level.
                    final hasQuestions = _questions(
                      category,
                      personalizedDifficulty,
                    ).isNotEmpty;

                    return _ActivityCard(
                      name:
                          activity['name']?.toString() ??
                          _categoryName(category),
                      emoji: _emoji(category),
                      color: _color(category),
                      difficulty: personalizedDifficulty,
                      recommended: recommendation != null,
                      enabled: hasQuestions,
                      onTap: hasQuestions
                          ? () => _openActivity(
                              context: context,
                              activity: activity,
                              recommendations: data.recommendations,
                            )
                          : null,
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // RECOMMENDATION BANNER
  // ═══════════════════════════════════════════════════════════════

  Widget _buildRecommendationBanner(Map<String, dynamic>? recommendations) {
    final list = recommendations?['recommendations'];

    if (list is! List || list.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppTheme.spaceLG),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusLG),
          boxShadow: [
            BoxShadow(
              color: AppTheme.cardShadow,
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: const Row(
          children: [
            Icon(Icons.auto_awesome_rounded, size: 30),
            SizedBox(width: AppTheme.spaceMD),
            Expanded(
              child: Text(
                'Keep practicing — your next personalized recommendation will appear here after you have some activity results.',
                style: TextStyle(fontSize: 16, height: 1.3),
              ),
            ),
          ],
        ),
      );
    }

    // Find the first valid recommendation.
    // We don't assume list.first is always valid.
    Map<String, dynamic>? firstRecommendation;

    for (final item in list) {
      if (item is Map<String, dynamic>) {
        final category = item['category']?.toString();

        if (category != null && category.trim().isNotEmpty) {
          firstRecommendation = item;
          break;
        }
      }
    }

    if (firstRecommendation == null) {
      return const SizedBox.shrink();
    }

    final category = firstRecommendation['category']?.toString() ?? 'activity';

    final reason =
        firstRecommendation['reason']?.toString() ??
        'Based on your recent performance';

    final difficulty = firstRecommendation['difficulty'] is num
        ? (firstRecommendation['difficulty'] as num).toInt().clamp(1, 3)
        : 1;

    final categoryQuestions = _questions(category, difficulty);

    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceLG),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryLight, AppTheme.surface],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        border: Border.all(color: AppTheme.primary.withValues(alpha: .18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(AppTheme.radiusMD),
            ),
            child: const Icon(Icons.auto_awesome_rounded, size: 30),
          ),

          const SizedBox(width: AppTheme.spaceMD),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Recommended for You',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 6),

                Text(
                  '${_categoryName(category)} • ${_levelLabel(difficulty)}',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  reason,
                  style: TextStyle(fontSize: 15, color: AppTheme.textSecondary),
                ),

                const SizedBox(height: 8),

                Row(
                  children: [
                    Icon(
                      categoryQuestions.isNotEmpty
                          ? Icons.check_circle_rounded
                          : Icons.info_outline_rounded,
                      size: 16,
                      color: AppTheme.primary,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      categoryQuestions.isNotEmpty
                          ? 'Personalized questions ready'
                          : 'Questions coming soon',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// LEARNING DATA
// ═══════════════════════════════════════════════════════════════

class _LearningData {
  final List<Map<String, dynamic>> activities;
  final Map<String, dynamic>? recommendations;

  const _LearningData({required this.activities, this.recommendations});
}

// ═══════════════════════════════════════════════════════════════
// ACTIVITY CARD
// ═══════════════════════════════════════════════════════════════

class _ActivityCard extends StatelessWidget {
  final String name;
  final String emoji;
  final Color color;
  final int difficulty;
  final bool recommended;
  final bool enabled;
  final VoidCallback? onTap;

  const _ActivityCard({
    required this.name,
    required this.emoji,
    required this.color,
    required this.difficulty,
    required this.recommended,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: enabled ? 1 : .55,
        child: Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(AppTheme.radiusLG),
            boxShadow: [
              BoxShadow(
                color: AppTheme.cardShadow,
                blurRadius: 7,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          padding: const EdgeInsets.all(AppTheme.spaceMD),
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(emoji, style: const TextStyle(fontSize: 48)),

                    const SizedBox(height: 8),

                    Text(
                      name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .18),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Level $difficulty',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              if (recommended)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.auto_awesome_rounded, size: 14),
                        SizedBox(width: 3),
                        Text(
                          'For you',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// ERROR STATE
// ═══════════════════════════════════════════════════════════════

class _ErrorState extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceXL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 64),

            const SizedBox(height: AppTheme.spaceMD),

            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18),
            ),

            const SizedBox(height: AppTheme.spaceMD),

            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../models/api/api_analysis.dart';
import '../models/api/api_progress.dart';
import '../models/api/api_recommendation_shared.dart';
import '../services/api/api_client.dart';
import '../services/app_session.dart';
import '../theme/app_theme.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key, required this.childId});

  final int childId;

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  final AppSession _session = AppSession.instance;

  bool _loading = true;
  String? _error;

  List<ApiProgress> _progress = const [];
  ApiAnalysis? _analysis;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final results = await Future.wait([
        _session.progress.getByChild(widget.childId),
        _session.analysis.getByChild(widget.childId),
      ]);

      if (!mounted) return;

      setState(() {
        _progress = results[0] as List<ApiProgress>;
        _analysis = results[1] as ApiAnalysis;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;

      setState(() {
        _error = _friendlyApiError(e);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  String _friendlyApiError(ApiException e) {
    switch (e.statusCode) {
      case 401:
        return 'Your session has expired. Please log in again.';
      case 403:
        return 'You do not have access to this learner\'s progress.';
      case 404:
        return 'Progress data was not found for this learner.';
      default:
        return 'The server returned an error (${e.statusCode}). Please try again.';
    }
  }

  int get _completedActivities {
    return _progress.fold(0, (total, item) => total + item.activitiesCompleted);
  }

  double get _averageDifficulty {
    if (_progress.isEmpty) return 1;

    final total = _progress.fold<int>(
      0,
      (sum, item) => sum + item.currentDifficulty,
    );

    return total / _progress.length;
  }

  String _difficultyLabel(double level) {
    if (level < 1.5) return 'Level 1';
    if (level < 2.5) return 'Level 2';
    return 'Level 3';
  }

  @override
  Widget build(BuildContext context) {
    final analysis = _analysis;
    final performance = analysis?.performance;
    final insight = analysis?.aiInsight;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Progress Report'),
        actions: [
          IconButton(
            tooltip: 'Refresh progress',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _buildBody(context, analysis, performance, insight),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    ApiAnalysis? analysis,
    ApiPerformance? performance,
    ApiAiInsight? insight,
  ) {
    if (_loading) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 260),
          Center(child: CircularProgressIndicator()),
        ],
      );
    }

    if (_error != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppTheme.spaceLG),
        children: [
          const SizedBox(height: 80),
          _MessageCard(
            icon: Icons.cloud_off_rounded,
            title: 'Could not load progress',
            message: _error!,
            action: _load,
          ),
        ],
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spaceLG,
        AppTheme.spaceMD,
        AppTheme.spaceLG,
        AppTheme.spaceXXL,
      ),
      children: [
        // =====================================================
        // OVERALL PROGRESS
        // =====================================================
        _OverallCard(
          accuracy: performance?.overallAccuracy ?? 0,
          status: insight?.overallStatus,
        ),

        const SizedBox(height: AppTheme.spaceLG),

        // =====================================================
        // SUMMARY
        // =====================================================
        _SummaryMetrics(
          completedActivities: _completedActivities,
          difficulty: _difficultyLabel(_averageDifficulty),
          categories: performance?.categoryPerformance.length ?? 0,
        ),

        // =====================================================
        // AI INSIGHT
        // =====================================================
        if (insight?.summary.isNotEmpty == true) ...[
          const SizedBox(height: AppTheme.spaceLG),
          _InsightCard(
            title: 'AI Learning Insight',
            icon: Icons.auto_awesome_rounded,
            message: insight!.summary,
          ),
        ],

        // =====================================================
        // STRENGTHS
        // =====================================================
        if (insight?.strengths.isNotEmpty == true) ...[
          const SizedBox(height: AppTheme.spaceXL),
          _SectionTitle(title: 'Strengths', icon: Icons.star_rounded),
          const SizedBox(height: AppTheme.spaceSM),
          _InsightList(
            items: insight!.strengths,
            icon: Icons.check_circle_rounded,
          ),
        ] else if (performance?.strengths.isNotEmpty == true) ...[
          const SizedBox(height: AppTheme.spaceXL),
          _SectionTitle(title: 'Strengths', icon: Icons.star_rounded),
          const SizedBox(height: AppTheme.spaceSM),
          _CategoryChips(
            items: performance!.strengths,
            emptyText:
                'Strengths will appear as more activities are completed.',
            icon: Icons.star_rounded,
            iconColor: AppTheme.starGold,
          ),
        ],

        // =====================================================
        // AREAS TO IMPROVE
        // =====================================================
        if (insight?.areasToImprove.isNotEmpty == true) ...[
          const SizedBox(height: AppTheme.spaceXL),
          _SectionTitle(
            title: 'Areas Needing Practice',
            icon: Icons.track_changes_rounded,
          ),
          const SizedBox(height: AppTheme.spaceSM),
          _InsightList(
            items: insight!.areasToImprove,
            icon: Icons.arrow_forward_rounded,
          ),
        ] else if (performance?.weakAreas.isNotEmpty == true) ...[
          const SizedBox(height: AppTheme.spaceXL),
          _SectionTitle(
            title: 'Areas Needing Practice',
            icon: Icons.track_changes_rounded,
          ),
          const SizedBox(height: AppTheme.spaceSM),
          _CategoryChips(
            items: performance!.weakAreas,
            emptyText: 'No priority areas detected right now.',
            icon: Icons.track_changes_rounded,
            iconColor: AppTheme.primary,
          ),
        ],

        // =====================================================
        // SUPPORT ADVICE
        // =====================================================
        if (insight?.parentAdvice.isNotEmpty == true) ...[
          const SizedBox(height: AppTheme.spaceXL),
          _SupportCard(message: insight!.parentAdvice),
        ],

        // =====================================================
        // CATEGORY PERFORMANCE
        // =====================================================
        const SizedBox(height: AppTheme.spaceXL),

        _SectionTitle(
          title: 'Category Performance',
          icon: Icons.bar_chart_rounded,
        ),

        const SizedBox(height: AppTheme.spaceSM),

        if (performance?.categoryPerformance.isEmpty ?? true)
          const _EmptyCard(
            icon: Icons.bar_chart_rounded,
            title: 'No performance data yet',
            message:
                'Complete an activity to start building personalized progress data.',
          )
        else
          ...performance!.categoryPerformance.entries.map(
            (entry) => _PerformanceCard(
              category: entry.key,
              performance: entry.value,
              difficulty: analysis?.difficulty[entry.key],
            ),
          ),

        // =====================================================
        // RECOMMENDATIONS
        // =====================================================
        if (analysis?.recommendations.isNotEmpty == true) ...[
          const SizedBox(height: AppTheme.spaceXL),

          _SectionTitle(
            title: 'Recommended Next Steps',
            icon: Icons.recommend_rounded,
          ),

          const SizedBox(height: AppTheme.spaceSM),

          ...analysis!.recommendations.map(
            (item) => _RecommendationCard(item: item),
          ),
        ],

        // =====================================================
        // ADAPTIVE LEARNING
        // =====================================================
        if (insight?.categoryInsights.isNotEmpty == true) ...[
          const SizedBox(height: AppTheme.spaceXL),

          _SectionTitle(
            title: 'Adaptive Learning',
            icon: Icons.auto_awesome_rounded,
          ),

          const SizedBox(height: AppTheme.spaceSM),

          const _AdaptiveIntroCard(),

          const SizedBox(height: AppTheme.spaceSM),

          ...insight!.categoryInsights.map((item) => _AdaptiveCard(item: item)),
        ],

        // =====================================================
        // CURRENT PROGRESS
        // =====================================================
        if (_progress.isNotEmpty) ...[
          const SizedBox(height: AppTheme.spaceXL),

          _SectionTitle(
            title: 'Current Progress',
            icon: Icons.insights_rounded,
          ),

          const SizedBox(height: AppTheme.spaceSM),

          ..._progress.map((item) => _ProgressCard(progress: item)),
        ],
      ],
    );
  }
}

// ============================================================
// OVERALL CARD
// ============================================================

class _OverallCard extends StatelessWidget {
  const _OverallCard({required this.accuracy, this.status});

  final double accuracy;
  final String? status;

  @override
  Widget build(BuildContext context) {
    final safe = accuracy.clamp(0, 100).toDouble();

    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceLG),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primary, AppTheme.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        boxShadow: AppTheme.shadowLifted,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .16),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                ),
                child: const Icon(
                  Icons.insights_rounded,
                  color: Colors.white,
                  size: 29,
                ),
              ),

              const SizedBox(width: AppTheme.spaceSM),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      status?.isNotEmpty == true
                          ? status!
                          : 'Learning Progress',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      'Personalized learning overview',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: AppTheme.spaceLG),

          Text(
            '${safe.round()}%',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 46,
              fontWeight: FontWeight.w900,
            ),
          ),

          const Text(
            'Overall accuracy',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),

          const SizedBox(height: AppTheme.spaceMD),

          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: safe / 100,
              minHeight: 12,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// SUMMARY METRICS
// ============================================================

class _SummaryMetrics extends StatelessWidget {
  const _SummaryMetrics({
    required this.completedActivities,
    required this.difficulty,
    required this.categories,
  });

  final int completedActivities;
  final String difficulty;
  final int categories;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MiniMetric(
            icon: Icons.task_alt_rounded,
            value: '$completedActivities',
            label: 'Completed',
          ),
        ),

        const SizedBox(width: AppTheme.spaceSM),

        Expanded(
          child: _MiniMetric(
            icon: Icons.trending_up_rounded,
            value: difficulty,
            label: 'Learning Level',
          ),
        ),

        const SizedBox(width: AppTheme.spaceSM),

        Expanded(
          child: _MiniMetric(
            icon: Icons.category_rounded,
            value: '$categories',
            label: 'Categories',
          ),
        ),
      ],
    );
  }
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppTheme.primary, size: 25),

          const SizedBox(height: 7),

          Text(
            value,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),

          const SizedBox(height: 2),

          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 10, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// SECTION TITLE
// ============================================================

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primary, size: 24),

        const SizedBox(width: AppTheme.spaceSM),

        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.headlineMedium),
        ),
      ],
    );
  }
}

// ============================================================
// AI INSIGHT
// ============================================================

class _InsightCard extends StatelessWidget {
  const _InsightCard({
    required this.title,
    required this.icon,
    required this.message,
  });

  final String title;
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceMD),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        border: Border.all(color: AppTheme.outline),
        boxShadow: AppTheme.shadowSoft,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppTheme.primaryLight.withValues(alpha: .25),
              borderRadius: BorderRadius.circular(AppTheme.radiusSM),
            ),
            child: Icon(icon, color: AppTheme.primary, size: 25),
          ),

          const SizedBox(width: AppTheme.spaceSM),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  message,
                  style: TextStyle(color: AppTheme.textSecondary, height: 1.45),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// SUPPORT CARD
// ============================================================

class _SupportCard extends StatelessWidget {
  const _SupportCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceMD),
      decoration: BoxDecoration(
        color: AppTheme.surfaceAlt,
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.lightbulb_outline_rounded,
            color: AppTheme.starGold,
            size: 30,
          ),

          const SizedBox(width: AppTheme.spaceSM),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Suggested Support',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                ),

                const SizedBox(height: 5),

                Text(
                  message,
                  style: TextStyle(color: AppTheme.textSecondary, height: 1.45),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// INSIGHT LIST
// ============================================================

class _InsightList extends StatelessWidget {
  const _InsightList({required this.items, required this.icon});

  final List<String> items;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: items.map((item) {
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: AppTheme.spaceSM),
          padding: const EdgeInsets.all(AppTheme.spaceMD),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusMD),
            border: Border.all(color: AppTheme.outline),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: AppTheme.primary, size: 22),

              const SizedBox(width: AppTheme.spaceSM),

              Expanded(
                child: Text(
                  _title(item),
                  style: TextStyle(color: AppTheme.textPrimary, height: 1.4),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ============================================================
// CATEGORY CHIPS
// ============================================================

class _CategoryChips extends StatelessWidget {
  const _CategoryChips({
    required this.items,
    required this.emptyText,
    required this.icon,
    required this.iconColor,
  });

  final List<String> items;
  final String emptyText;
  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return _EmptyCard(
        icon: Icons.info_outline_rounded,
        title: 'No data yet',
        message: emptyText,
      );
    }

    return Wrap(
      spacing: AppTheme.spaceSM,
      runSpacing: AppTheme.spaceSM,
      children: items.map((item) {
        return Chip(
          avatar: Icon(icon, size: 18, color: iconColor),
          label: Text(_title(item)),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
        );
      }).toList(),
    );
  }
}

// ============================================================
// CATEGORY PERFORMANCE
// ============================================================

class _PerformanceCard extends StatelessWidget {
  const _PerformanceCard({
    required this.category,
    required this.performance,
    this.difficulty,
  });

  final String category;
  final ApiCategoryPerformance performance;
  final ApiDifficultyDecision? difficulty;

  @override
  Widget build(BuildContext context) {
    final accuracy = performance.accuracy.clamp(0, 100).toDouble();

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spaceSM),
      padding: const EdgeInsets.all(AppTheme.spaceMD),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        border: Border.all(color: AppTheme.outline),
        boxShadow: AppTheme.shadowSoft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight.withValues(alpha: .22),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                ),
                child: Icon(Icons.category_rounded, color: AppTheme.primary),
              ),

              const SizedBox(width: AppTheme.spaceSM),

              Expanded(
                child: Text(
                  _title(category),
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),

              Text(
                '${accuracy.round()}%',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primary,
                  fontSize: 17,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppTheme.spaceMD),

          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(value: accuracy / 100, minHeight: 9),
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              Icon(
                Icons.task_alt_rounded,
                size: 17,
                color: AppTheme.textSecondary,
              ),

              const SizedBox(width: 5),

              Text(
                '${performance.activitiesCompleted} activities',
                style: TextStyle(color: AppTheme.textSecondary),
              ),

              const Spacer(),

              if (difficulty != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLight.withValues(alpha: .16),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Next: Level ${difficulty!.nextDifficulty}',
                    style: TextStyle(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ),
            ],
          ),

          if (difficulty?.reason.isNotEmpty == true) ...[
            const SizedBox(height: 9),

            Text(
              difficulty!.reason,
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ============================================================
// RECOMMENDATION
// ============================================================

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({required this.item});

  final ApiRecommendationItem item;

  @override
  Widget build(BuildContext context) {
    final high = item.priority.toLowerCase() == 'high';

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spaceSM),
      padding: const EdgeInsets.all(AppTheme.spaceMD),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        border: Border.all(
          color: high ? AppTheme.primaryLight : AppTheme.outline,
        ),
        boxShadow: AppTheme.shadowSoft,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppTheme.primaryLight.withValues(alpha: .16),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              high ? Icons.priority_high_rounded : Icons.recommend_rounded,
              color: AppTheme.primary,
              size: 24,
            ),
          ),

          const SizedBox(width: AppTheme.spaceSM),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _title(item.category),
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceAlt,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        item.priority.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 5),

                Text(
                  'Recommended difficulty: Level ${item.difficulty}',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                ),

                const SizedBox(height: 6),

                Text(
                  item.reason,
                  style: TextStyle(color: AppTheme.textSecondary, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// ADAPTIVE INTRO
// ============================================================

class _AdaptiveIntroCard extends StatelessWidget {
  const _AdaptiveIntroCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceMD),
      decoration: BoxDecoration(
        color: AppTheme.surfaceAlt,
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.primaryLight.withValues(alpha: .18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.auto_awesome_rounded, color: AppTheme.primary),
          ),

          const SizedBox(width: AppTheme.spaceSM),

          Expanded(
            child: Text(
              'Difficulty automatically responds to recent performance so activities stay appropriately challenging.',
              style: TextStyle(color: AppTheme.textSecondary, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// ADAPTIVE CATEGORY CARD
// ============================================================

class _AdaptiveCard extends StatelessWidget {
  const _AdaptiveCard({required this.item});

  final ApiCategoryInsight item;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spaceSM),
      padding: const EdgeInsets.all(AppTheme.spaceMD),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _title(item.category),
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight.withValues(alpha: .16),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Level ${item.recommendedDifficulty}',
                  style: TextStyle(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Text(
            item.status,
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),

          if (item.message.isNotEmpty) ...[
            const SizedBox(height: 6),

            Text(
              item.message,
              style: TextStyle(color: AppTheme.textSecondary, height: 1.4),
            ),
          ],

          const SizedBox(height: 10),

          Row(
            children: [
              Icon(Icons.analytics_rounded, size: 17, color: AppTheme.primary),

              const SizedBox(width: 5),

              Text(
                '${item.accuracy.round()}% accuracy',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              ),

              const SizedBox(width: 15),

              Text(
                '${item.activitiesCompleted} completed',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================
// CURRENT PROGRESS
// ============================================================

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.progress});

  final ApiProgress progress;

  @override
  Widget build(BuildContext context) {
    final accuracy = progress.accuracy.clamp(0, 100).toDouble();

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spaceSM),
      padding: const EdgeInsets.all(AppTheme.spaceMD),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 66,
            height: 66,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: accuracy / 100,
                  strokeWidth: 6,
                ),

                Text(
                  '${accuracy.round()}%',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: AppTheme.spaceMD),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _title(progress.category),
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  '${progress.activitiesCompleted} completed  •  Level ${progress.currentDifficulty}',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),

                const SizedBox(height: 3),

                Text(
                  'Score: ${progress.score.toStringAsFixed(1)}',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// EMPTY STATE
// ============================================================

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spaceLG),
      decoration: BoxDecoration(
        color: AppTheme.surfaceAlt,
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Column(
        children: [
          Icon(icon, size: 40, color: AppTheme.textSecondary),

          const SizedBox(height: AppTheme.spaceSM),

          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),

          const SizedBox(height: 5),

          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textSecondary, height: 1.4),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// ERROR STATE
// ============================================================

class _MessageCard extends StatelessWidget {
  const _MessageCard({
    required this.icon,
    required this.title,
    required this.message,
    required this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final VoidCallback action;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceLG),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Column(
        children: [
          Icon(icon, size: 52, color: AppTheme.textSecondary),

          const SizedBox(height: AppTheme.spaceSM),

          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
          ),

          const SizedBox(height: 6),

          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textSecondary, height: 1.4),
          ),

          const SizedBox(height: AppTheme.spaceMD),

          FilledButton.icon(
            onPressed: action,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try again'),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// TITLE HELPER
// ============================================================

String _title(String value) {
  final trimmed = value.trim();

  if (trimmed.isEmpty) {
    return 'Unknown';
  }

  return trimmed[0].toUpperCase() + trimmed.substring(1);
}

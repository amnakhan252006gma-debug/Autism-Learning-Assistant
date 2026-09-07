import 'package:flutter/material.dart';

import '../services/backend_service.dart';
import '../theme/app_theme.dart';
import 'communication_screen.dart';
import 'games_screen.dart';
import 'learning_screen.dart';
import 'progress_screen.dart';
import 'routine_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.childId, this.childName});

  final int? childId;
  final String? childName;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final BackendService _backend = BackendService.instance;

  bool _loading = true;
  String? _error;

  List<Map<String, dynamic>> _children = [];
  Map<String, dynamic>? _selectedChild;
  Map<String, dynamic>? _analysis;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final children = await _backend.getChildren();

      if (!mounted) return;

      Map<String, dynamic>? selected;

      // If HomeScreen was opened for a specific child, use that child.
      if (widget.childId != null) {
        for (final child in children) {
          final id = _childId(child);
          if (id == widget.childId) {
            selected = child;
            break;
          }
        }
      }

      // Otherwise use the first available child.
      selected ??= children.isNotEmpty ? children.first : null;

      Map<String, dynamic>? analysis;

      if (selected != null) {
        final id = _childId(selected);

        if (id != null) {
          try {
            analysis = await _backend.getAnalysis(id);
          } catch (_) {
            // Dashboard can still work if analysis is unavailable.
          }
        }
      }

      if (!mounted) return;

      setState(() {
        _children = children;
        _selectedChild = selected;
        _analysis = analysis;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = 'Could not load your dashboard';
      });
    }
  }

  int? _childId(Map<String, dynamic> child) {
    final value = child['id'];

    if (value is int) return value;

    if (value is num) return value.toInt();

    return null;
  }

  String _childName() {
    final name = _selectedChild?['name'];

    if (name is String && name.trim().isNotEmpty) {
      return name;
    }

    if (widget.childName != null && widget.childName!.trim().isNotEmpty) {
      return widget.childName!;
    }

    return 'Learner';
  }

  double _accuracy() {
    final performance = _analysis?['performance'];

    if (performance is! Map) return 0.0;

    final value = performance['overall_accuracy'];

    if (value is num) {
      return value.toDouble();
    }

    return 0.0;
  }

  List<dynamic> _recommendations() {
    final value = _analysis?['recommendations'];

    if (value is List) return value;

    return [];
  }

  List<dynamic> _weakAreas() {
    final performance = _analysis?['performance'];

    if (performance is! Map) return [];

    final value = performance['weak_areas'];

    if (value is List) return value;

    return [];
  }

  List<dynamic> _strengths() {
    final performance = _analysis?['performance'];

    if (performance is! Map) return [];

    final value = performance['strengths'];

    if (value is List) return value;

    return [];
  }

  Future<void> _openLearning() async {
    final childId = _childId(_selectedChild ?? {});

    if (childId == null) {
      _showMessage('Please select a learner first');
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => LearningScreen(childId: childId)),
    );

    _loadDashboard();
  }

  Future<void> _openProgress() async {
    final childId = _childId(_selectedChild ?? {});

    if (childId == null) {
      _showMessage('Please select a learner first');
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProgressScreen(childId: childId)),
    );

    _loadDashboard();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          'Learning Assistant',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loadDashboard,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadDashboard,
        child: _children.isEmpty
            ? _buildNoChildState()
            : ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                children: [
                  _buildWelcomeCard(),
                  const SizedBox(height: 20),
                  _buildChildSelector(),
                  const SizedBox(height: 20),
                  _buildProgressCard(),
                  const SizedBox(height: 20),
                  _buildAdaptiveCard(),
                  const SizedBox(height: 24),
                  _buildFeatureGrid(),
                  const SizedBox(height: 24),
                  _buildStrengthsAndWeakAreas(),
                  const SizedBox(height: 24),
                  _buildRecommendations(),
                  const SizedBox(height: 30),
                ],
              ),
      ),
    );
  }

  Widget _buildNoChildState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 80),
        Icon(Icons.child_care_rounded, size: 90, color: AppTheme.primary),
        const SizedBox(height: 24),
        const Text(
          'No learner found',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        const Text(
          'Create or select a learner to start personalized learning.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: _loadDashboard,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Refresh'),
        ),
      ],
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primary, AppTheme.primary.withOpacity(.78)],
        ),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Row(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.18),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Welcome back',
                  style: TextStyle(color: Colors.white70, fontSize: 15),
                ),
                const SizedBox(height: 4),
                Text(
                  _childName(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Let’s continue learning together',
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChildSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.outline),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Map<String, dynamic>>(
          value: _selectedChild,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          items: _children.map((child) {
            return DropdownMenuItem<Map<String, dynamic>>(
              value: child,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppTheme.primaryLight,
                    child: Icon(Icons.person_rounded, color: AppTheme.primary),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    child['name']?.toString() ?? 'Learner',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (child) async {
            if (child == null) return;

            setState(() {
              _selectedChild = child;
              _analysis = null;
            });

            final id = _childId(child);

            if (id != null) {
              try {
                final analysis = await _backend.getAnalysis(id);

                if (!mounted) return;

                setState(() {
                  _analysis = analysis;
                });
              } catch (_) {}
            }
          },
        ),
      ),
    );
  }

  Widget _buildProgressCard() {
    final accuracy = _accuracy().clamp(0.0, 100.0).toDouble();

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Learning progress',
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
                ),
              ),
              Text(
                '${accuracy.toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: accuracy / 100,
              minHeight: 12,
              backgroundColor: AppTheme.surfaceAlt,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _accuracyMessage(accuracy),
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }

  String _accuracyMessage(double accuracy) {
    if (accuracy >= 80) {
      return 'Excellent progress — activities can become more challenging';
    }

    if (accuracy >= 60) {
      return 'Good progress — keep practicing consistently';
    }

    if (accuracy >= 50) {
      return 'More practice will help build confidence';
    }

    if (accuracy > 0) {
      return 'The learning plan will adjust to provide extra support';
    }

    return 'Complete activities to start personalized progress tracking';
  }

  Widget _buildAdaptiveCard() {
    final accuracy = _accuracy();

    String title;
    String description;
    IconData icon;

    if (accuracy >= 80) {
      title = 'Challenge mode ready';
      description =
          'Strong performance detected. The system can gradually increase difficulty.';
      icon = Icons.trending_up_rounded;
    } else if (accuracy >= 50) {
      title = 'Personalized practice';
      description =
          'Activities are being kept at a comfortable level while skills develop.';
      icon = Icons.auto_awesome_rounded;
    } else {
      title = 'Extra support enabled';
      description =
          'The system is identifying areas that need more practice and support.';
      icon = Icons.favorite_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.primaryLight,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.75),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppTheme.primary, size: 29),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  description,
                  style: TextStyle(color: AppTheme.textSecondary, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Explore',
          style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 14),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: 1.15,
          children: [
            _featureCard(
              icon: Icons.school_rounded,
              title: 'Learning',
              subtitle: 'Personalized activities',
              color: AppTheme.primary,
              onTap: _openLearning,
            ),
            _featureCard(
              icon: Icons.games_rounded,
              title: 'Games',
              subtitle: 'Practice through play',
              color: AppTheme.gamesColor,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const GamesScreen()),
                );
              },
            ),
            _featureCard(
              icon: Icons.insights_rounded,
              title: 'Progress',
              subtitle: 'See development',
              color: AppTheme.communicateColor,
              onTap: _openProgress,
            ),
            _featureCard(
              icon: Icons.schedule_rounded,
              title: 'Routine',
              subtitle: 'Daily structure',
              color: AppTheme.primary,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RoutineScreen()),
                );
              },
            ),
            _featureCard(
              icon: Icons.chat_bubble_rounded,
              title: 'Communication',
              subtitle: 'Communication support',
              color: AppTheme.gamesColor,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CommunicationScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _featureCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppTheme.outline),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.04),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(.12),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStrengthsAndWeakAreas() {
    final strengths = _strengths();
    final weakAreas = _weakAreas();

    if (strengths.isEmpty && weakAreas.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Learning insights',
          style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 14),
        if (strengths.isNotEmpty)
          _insightBox(
            title: 'Strengths',
            icon: Icons.star_rounded,
            items: strengths,
          ),
        if (strengths.isNotEmpty && weakAreas.isNotEmpty)
          const SizedBox(height: 12),
        if (weakAreas.isNotEmpty)
          _insightBox(
            title: 'Areas to practice',
            icon: Icons.track_changes_rounded,
            items: weakAreas,
          ),
      ],
    );
  }

  Widget _insightBox({
    required String title,
    required IconData icon,
    required List<dynamic> items,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...items
              .take(4)
              .map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 7),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('•  '),
                      Expanded(child: Text(item.toString())),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildRecommendations() {
    final recommendations = _recommendations();

    if (recommendations.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recommended for you',
          style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 14),
        ...recommendations.take(3).map((item) => _recommendationCard(item)),
      ],
    );
  }

  Widget _recommendationCard(dynamic item) {
    if (item is! Map) {
      return const SizedBox.shrink();
    }

    final category = item['category']?.toString() ?? 'Practice';
    final difficulty = item['difficulty']?.toString() ?? '1';
    final priority = item['priority']?.toString() ?? 'medium';
    final reason = item['reason']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppTheme.primaryLight,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.auto_awesome_rounded, color: AppTheme.primary),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatCategory(category),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  reason,
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 7),
                Text(
                  'Level $difficulty • $priority priority',
                  style: TextStyle(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatCategory(String value) {
    if (value.isEmpty) return 'Practice';

    return value
        .replaceAll('_', ' ')
        .split(' ')
        .map(
          (word) => word.isEmpty
              ? word
              : '${word[0].toUpperCase()}${word.substring(1)}',
        )
        .join(' ');
  }
}

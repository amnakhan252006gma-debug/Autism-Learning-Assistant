import 'package:flutter/material.dart';

import '../models/api/api_child.dart';
import '../services/app_session.dart';
import '../theme/app_theme.dart';
import 'auth_screen.dart';
import 'communication_screen.dart';
import 'games_screen.dart';
import 'home_screen.dart';
import 'learning_screen.dart';
import 'progress_screen.dart';
import 'routine_screen.dart';

class RoleDashboardScreen extends StatefulWidget {
  const RoleDashboardScreen({super.key, required this.role});

  final String role;

  @override
  State<RoleDashboardScreen> createState() => _RoleDashboardScreenState();
}

class _RoleDashboardScreenState extends State<RoleDashboardScreen> {
  final AppSession _session = AppSession.instance;

  bool _loading = true;
  String? _error;

  List<ApiChild> _children = [];
  ApiChild? _selectedChild;
  dynamic _analysis;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    if (!mounted) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await _session.restore();

      final user = _session.user;

      if (user == null) {
        throw Exception('User session not found');
      }

      final assignments = await _session.assignments.getByUser(user.id);

      final children = <ApiChild>[];

      for (final assignment in assignments) {
        if (assignment.role.toLowerCase() != widget.role.toLowerCase()) {
          continue;
        }

        try {
          final child = await _session.children.getById(assignment.childId);

          children.add(child);
        } catch (_) {
          // Ignore an individual child that cannot be loaded.
        }
      }

      ApiChild? selected;

      if (children.isNotEmpty) {
        selected = children.first;
      }

      dynamic analysis;

      if (selected != null) {
        try {
          analysis = await _session.analysis.getByChild(selected.id);
        } catch (_) {
          analysis = null;
        }
      }

      if (!mounted) return;

      setState(() {
        _children = children;
        _selectedChild = selected;
        _analysis = analysis;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = 'Could not load assigned learners';
      });
    }
  }

  Future<void> _selectChild(ApiChild child) async {
    setState(() {
      _selectedChild = child;
      _analysis = null;
    });

    try {
      final analysis = await _session.analysis.getByChild(child.id);

      if (!mounted) return;

      setState(() {
        _analysis = analysis;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _analysis = null;
      });
    }
  }

  Future<void> _logout() async {
    try {
      await _session.signOut();
    } catch (_) {
      // Continue to login even if clearing the session encounters an issue.
    }

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthScreen()),
      (route) => false,
    );
  }

  String get _roleName {
    final role = widget.role.toLowerCase();

    if (role == 'teacher') return 'Teacher';
    if (role == 'therapist') return 'Therapist';

    return 'Professional';
  }

  String get _roleTitle {
    if (widget.role.toLowerCase() == 'teacher') {
      return 'Teacher Dashboard';
    }

    if (widget.role.toLowerCase() == 'therapist') {
      return 'Therapist Dashboard';
    }

    return 'Learning Dashboard';
  }

  String get _roleSubtitle {
    if (widget.role.toLowerCase() == 'teacher') {
      return 'Monitor your assigned learners and their progress';
    }

    if (widget.role.toLowerCase() == 'therapist') {
      return 'Track personalized development and learning';
    }

    return 'Support personalized learning';
  }

  String get _childName {
    return _selectedChild?.name ?? 'Learner';
  }

  double get _accuracy {
    final analysis = _analysis;

    if (analysis == null) return 0;

    try {
      final value = analysis.performance.overallAccuracy;

      if (value <= 1) {
        return (value * 100).clamp(0, 100).toDouble();
      }

      return value.clamp(0, 100).toDouble();
    } catch (_) {
      return 0;
    }
  }

  List<dynamic> get _recommendations {
    final analysis = _analysis;

    if (analysis == null) return const [];

    try {
      return analysis.recommendations;
    } catch (_) {
      return const [];
    }
  }

  List<String> get _strengths {
    final analysis = _analysis;

    if (analysis == null) return const [];

    try {
      return List<String>.from(analysis.performance.strengths);
    } catch (_) {
      return const [];
    }
  }

  List<String> get _weakAreas {
    final analysis = _analysis;

    if (analysis == null) return const [];

    try {
      return List<String>.from(analysis.performance.weakAreas);
    } catch (_) {
      return const [];
    }
  }

  Future<void> _openLearning() async {
    final child = _selectedChild;

    if (child == null) {
      _message('No learner selected');
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => LearningScreen(childId: child.id)),
    );

    _loadDashboard();
  }

  Future<void> _openProgress() async {
    final child = _selectedChild;

    if (child == null) {
      _message('No learner selected');
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProgressScreen(childId: child.id)),
    );

    _loadDashboard();
  }

  void _openChildHome() {
    final child = _selectedChild;

    if (child == null) {
      _message('No learner selected');
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HomeScreen(childId: child.id, childName: child.name),
      ),
    );
  }

  void _message(String message) {
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
        title: Text(
          _roleTitle,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            onPressed: _loadDashboard,
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded),
          ),
          IconButton(
            onPressed: _logout,
            tooltip: 'Logout',
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadDashboard,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          children: [
            _buildHeader(),
            const SizedBox(height: 20),

            if (_children.isEmpty)
              _buildNoLearners()
            else ...[
              _buildChildSelector(),
              const SizedBox(height: 18),
              _buildAccuracyCard(),
              const SizedBox(height: 18),
              _buildAdaptiveStatus(),
              const SizedBox(height: 22),
              _buildStrengthsAndWeakAreas(),
              const SizedBox(height: 24),
              _buildActions(),
              const SizedBox(height: 24),
              _buildRecommendations(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primary, AppTheme.primary.withOpacity(.75)],
        ),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.dashboard_customize_rounded,
            color: Colors.white,
            size: 36,
          ),
          const SizedBox(height: 16),
          Text(
            'Hello, $_roleName',
            style: const TextStyle(color: Colors.white70, fontSize: 15),
          ),
          const SizedBox(height: 4),
          Text(
            _roleSubtitle,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 23,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            '${_children.length} assigned '
            '${_children.length == 1 ? 'learner' : 'learners'}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoLearners() {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Column(
        children: [
          Icon(Icons.child_care_rounded, size: 65, color: AppTheme.primary),
          const SizedBox(height: 15),
          const Text(
            'No assigned learners',
            style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            _error ?? 'You currently do not have any children assigned to you.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            onPressed: _loadDashboard,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Refresh'),
          ),
        ],
      ),
    );
  }

  Widget _buildChildSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.outline),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<ApiChild>(
          value: _selectedChild,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          items: _children.map((child) {
            return DropdownMenuItem<ApiChild>(
              value: child,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 19,
                    backgroundColor: AppTheme.primaryLight,
                    child: Icon(Icons.person_rounded, color: AppTheme.primary),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    child.name,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (child) {
            if (child != null) {
              _selectChild(child);
            }
          },
        ),
      ),
    );
  }

  Widget _buildAccuracyCard() {
    final accuracy = _accuracy;

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
                  'Overall performance',
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
                ),
              ),
              Text(
                '${accuracy.toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 25,
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
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Currently viewing $_childName',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildAdaptiveStatus() {
    final accuracy = _accuracy;

    String title;
    String text;
    IconData icon;

    if (accuracy >= 80) {
      title = 'Ready for more challenge';
      text =
          'Performance is strong. The adaptive system can recommend harder activities.';
      icon = Icons.trending_up_rounded;
    } else if (accuracy >= 50) {
      title = 'Steady learning';
      text =
          'The system is maintaining an appropriate difficulty level based on recent performance.';
      icon = Icons.auto_awesome_rounded;
    } else {
      title = 'Additional support';
      text =
          'The system is identifying weaker areas and recommending supportive practice.';
      icon = Icons.favorite_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.primaryLight,
        borderRadius: BorderRadius.circular(23),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primary, size: 32),
          const SizedBox(width: 14),
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
                const SizedBox(height: 5),
                Text(
                  text,
                  style: TextStyle(color: AppTheme.textSecondary, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStrengthsAndWeakAreas() {
    if (_analysis == null && _strengths.isEmpty && _weakAreas.isEmpty) {
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
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _insightCard(
                icon: Icons.star_rounded,
                title: 'Strengths',
                items: _strengths,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _insightCard(
                icon: Icons.auto_fix_high_rounded,
                title: 'Practice',
                items: _weakAreas,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _insightCard({
    required IconData icon,
    required String title,
    required List<String> items,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.primary, size: 27),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          const SizedBox(height: 8),
          if (items.isEmpty)
            Text(
              'No data yet',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            )
          else
            ...items
                .take(3)
                .map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 5),
                    child: Text(
                      '• ${_formatCategory(item)}',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick access',
          style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 14),

        _actionTile(
          icon: Icons.school_rounded,
          title: 'Learning',
          subtitle: 'View personalized learning activities',
          onTap: _openLearning,
        ),

        _actionTile(
          icon: Icons.insights_rounded,
          title: 'Progress',
          subtitle: 'View performance and development',
          onTap: _openProgress,
        ),

        _actionTile(
          icon: Icons.games_rounded,
          title: 'Games',
          subtitle: 'Interactive learning practice',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const GamesScreen()),
            );
          },
        ),

        _actionTile(
          icon: Icons.schedule_rounded,
          title: 'Routine',
          subtitle: 'Daily routine support',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RoutineScreen()),
            );
          },
        ),

        _actionTile(
          icon: Icons.chat_bubble_rounded,
          title: 'Communication',
          subtitle: 'Communication support',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CommunicationScreen()),
            );
          },
        ),

        _actionTile(
          icon: Icons.home_rounded,
          title: 'Child Home',
          subtitle: 'Open the selected learner dashboard',
          onTap: _openChildHome,
        ),
      ],
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.outline),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 17, vertical: 5),
        onTap: onTap,
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppTheme.primaryLight,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: AppTheme.primary),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 17),
      ),
    );
  }

  Widget _buildRecommendations() {
    final recommendations = _recommendations;

    if (recommendations.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recommended activities',
          style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 14),
        ...recommendations.take(4).map((item) => _recommendation(item)),
      ],
    );
  }

  Widget _recommendation(dynamic item) {
    String category = 'Practice';
    String difficulty = '1';
    String priority = 'medium';
    String reason = '';

    try {
      category = item.category;
      difficulty = item.difficulty.toString();
      priority = item.priority;
      reason = item.reason;
    } catch (_) {
      if (item is Map) {
        category = item['category']?.toString() ?? 'Practice';
        difficulty = item['difficulty']?.toString() ?? '1';
        priority = item['priority']?.toString() ?? 'medium';
        reason = item['reason']?.toString() ?? '';
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 11),
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Row(
        children: [
          Icon(Icons.auto_awesome_rounded, color: AppTheme.primary, size: 28),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatCategory(category),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (reason.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    reason,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                Text(
                  'Level $difficulty • $priority priority',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w700,
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

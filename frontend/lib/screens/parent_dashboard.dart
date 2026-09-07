import 'package:flutter/material.dart';

import '../models/api/api_analysis.dart';
import '../models/api/api_child.dart';
import '../models/api/api_child_assignment.dart';
import '../models/api/api_recommendation_shared.dart';
import '../models/api/api_user.dart';
import '../services/app_session.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_page.dart';
import 'auth_screen.dart';
import 'home_screen.dart';

class ParentDashboard extends StatefulWidget {
  const ParentDashboard({super.key});

  @override
  State<ParentDashboard> createState() => _ParentDashboardState();
}

class _ParentDashboardState extends State<ParentDashboard> {
  final AppSession _session = AppSession.instance;

  ApiAnalysis? _analysis;

  List<ApiChild> _children = [];
  List<ApiUser> _staff = [];
  List<ApiChildAssignment> _assignments = [];

  bool _loading = true;
  bool _staffLoading = false;

  String? _error;

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

      if (!_session.isSignedIn) {
        throw Exception('Please sign in again.');
      }

      final children = await _session.loadChildren();

      if (children.isEmpty) {
        throw Exception('No children are linked to this parent account.');
      }

      _children = children;

      final activeId = _session.activeChild?.id;

      final selectedChild =
          children.where((child) => child.id == activeId).firstOrNull ??
          children.first;

      if (_session.activeChild?.id != selectedChild.id) {
        await _session.setActiveChild(selectedChild);
      }

      final analysis = await _session.analysis.getByChild(selectedChild.id);

      if (!mounted) return;

      setState(() {
        _analysis = analysis;
        _loading = false;
      });

      await _loadAssignments();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _loadAssignments() async {
    final child = _session.activeChild;

    if (child == null) return;

    setState(() {
      _staffLoading = true;
    });

    try {
      final results = await Future.wait([
        _session.assignments.getStaff(),
        _session.assignments.getByChild(child.id),
      ]);

      if (!mounted) return;

      setState(() {
        _staff = results[0] as List<ApiUser>;
        _assignments = results[1] as List<ApiChildAssignment>;
        _staffLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _staffLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not load teachers and therapists.'),
        ),
      );
    }
  }

  Future<void> _selectChild(ApiChild child) async {
    if (_session.activeChild?.id == child.id) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await _session.setActiveChild(child);

      final analysis = await _session.analysis.getByChild(child.id);

      if (!mounted) return;

      setState(() {
        _analysis = analysis;
        _loading = false;
      });

      await _loadAssignments();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _logout() async {
    try {
      await _session.signOut();
    } catch (_) {
      // Continue to login even if session clearing encounters an issue.
    }

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthScreen()),
      (route) => false,
    );
  }

  void _openChildDashboard() {
    final child = _session.activeChild;

    if (child == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HomeScreen(childId: child.id, childName: child.name),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceAlt,
      appBar: AppBar(
        title: const Text(
          'Parent Dashboard',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: AppTheme.surface,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loading ? null : _loadDashboard,
            icon: const Icon(Icons.refresh_rounded),
          ),
          IconButton(
            tooltip: 'Logout',
            onPressed: _logout,
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: AnimatedPage(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return _ErrorView(message: _error!, onRetry: _loadDashboard);
    }

    final analysis = _analysis;

    if (analysis == null) {
      return const _EmptyView();
    }

    final child = _session.activeChild;

    return RefreshIndicator(
      onRefresh: _loadDashboard,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          _WelcomeCard(childName: child?.name ?? 'Child'),

          if (_children.length > 1)
            _ChildSelector(
              children: _children,
              selectedChildId: _session.activeChild?.id,
              onChanged: _selectChild,
            ),

          const SizedBox(height: 16),

          _OpenChildDashboardButton(
            childName: child?.name ?? 'Child',
            onTap: _openChildDashboard,
          ),

          const SizedBox(height: 26),

          _SectionTitle(
            title: 'Professional Support',
            icon: Icons.groups_rounded,
          ),

          const SizedBox(height: 12),

          if (child != null) ...[
            _AssignmentCard(
              title: 'Teacher',
              role: 'teacher',
              icon: Icons.school_rounded,
              staff: _staff,
              assignments: _assignments,
              childId: child.id,
              loading: _staffLoading,
              session: _session,
              onChanged: _loadAssignments,
            ),

            const SizedBox(height: 14),

            _AssignmentCard(
              title: 'Therapist',
              role: 'therapist',
              icon: Icons.health_and_safety_rounded,
              staff: _staff,
              assignments: _assignments,
              childId: child.id,
              loading: _staffLoading,
              session: _session,
              onChanged: _loadAssignments,
            ),
          ],

          const SizedBox(height: 26),

          _OverallProgressCard(
            accuracy: analysis.performance.overallAccuracy,
            activitiesCompleted: _totalActivitiesCompleted(analysis),
          ),

          const SizedBox(height: 24),

          _SectionTitle(
            title: 'AI Learning Insight',
            icon: Icons.auto_awesome_rounded,
          ),

          const SizedBox(height: 12),

          _AiInsightCard(insight: analysis.aiInsight),

          const SizedBox(height: 24),

          _SectionTitle(title: 'Strengths', icon: Icons.star_rounded),

          const SizedBox(height: 12),

          _TagList(
            items: analysis.performance.strengths,
            emptyText:
                'Strengths will appear as more activities are completed.',
          ),

          const SizedBox(height: 24),

          _SectionTitle(
            title: 'Areas to Practice',
            icon: Icons.psychology_rounded,
          ),

          const SizedBox(height: 12),

          _TagList(
            items: analysis.performance.weakAreas,
            emptyText: 'No specific areas to practice yet.',
          ),

          const SizedBox(height: 24),

          _SectionTitle(
            title: 'Learning Progress',
            icon: Icons.trending_up_rounded,
          ),

          const SizedBox(height: 12),

          if (analysis.performance.categoryPerformance.isEmpty)
            const _MessageCard(
              message:
                  'Learning progress will appear here after activities are completed.',
            )
          else
            ...analysis.performance.categoryPerformance.entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _CategoryProgressCard(
                  category: entry.key,
                  performance: entry.value,
                ),
              ),
            ),

          const SizedBox(height: 12),

          _SectionTitle(
            title: 'Recommended for You',
            icon: Icons.recommend_rounded,
          ),

          const SizedBox(height: 12),

          if (analysis.recommendations.isEmpty)
            const _MessageCard(
              message:
                  'Recommendations will appear after more learning data is collected.',
            )
          else
            ...analysis.recommendations.map(
              (recommendation) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _RecommendationCard(recommendation: recommendation),
              ),
            ),

          const SizedBox(height: 12),

          _SectionTitle(
            title: 'Adaptive Learning',
            icon: Icons.auto_graph_rounded,
          ),

          const SizedBox(height: 12),

          if (analysis.difficulty.isEmpty)
            const _MessageCard(
              message:
                  'Adaptive difficulty will appear as the child completes activities.',
            )
          else
            ...analysis.difficulty.entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _DifficultyCard(
                  category: entry.key,
                  decision: entry.value,
                ),
              ),
            ),

          if (analysis.performance.message != null &&
              analysis.performance.message!.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            _MessageCard(message: analysis.performance.message!),
          ],

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  int _totalActivitiesCompleted(ApiAnalysis analysis) {
    return analysis.performance.categoryPerformance.values.fold(
      0,
      (total, item) => total + item.activitiesCompleted,
    );
  }
}

class _AssignmentCard extends StatefulWidget {
  final String title;
  final String role;
  final IconData icon;

  final List<ApiUser> staff;
  final List<ApiChildAssignment> assignments;

  final int childId;
  final bool loading;

  final AppSession session;
  final Future<void> Function() onChanged;

  const _AssignmentCard({
    required this.title,
    required this.role,
    required this.icon,
    required this.staff,
    required this.assignments,
    required this.childId,
    required this.loading,
    required this.session,
    required this.onChanged,
  });

  @override
  State<_AssignmentCard> createState() => _AssignmentCardState();
}

class _AssignmentCardState extends State<_AssignmentCard> {
  int? _selectedUserId;
  bool _saving = false;

  List<ApiUser> get _availableStaff {
    return widget.staff
        .where((user) => user.role.toLowerCase() == widget.role)
        .toList();
  }

  ApiChildAssignment? get _currentAssignment {
    for (final assignment in widget.assignments) {
      if (assignment.role.toLowerCase() == widget.role) {
        return assignment;
      }
    }

    return null;
  }

  ApiUser? get _currentUser {
    final assignment = _currentAssignment;

    if (assignment == null) return null;

    for (final user in widget.staff) {
      if (user.id == assignment.userId) {
        return user;
      }
    }

    return null;
  }

  Future<void> _assign() async {
    if (_selectedUserId == null) return;

    setState(() {
      _saving = true;
    });

    try {
      await widget.session.assignments.create(
        childId: widget.childId,
        userId: _selectedUserId!,
        role: widget.role,
      );

      if (!mounted) return;

      setState(() {
        _selectedUserId = null;
        _saving = false;
      });

      await widget.onChanged();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${widget.title} assigned successfully.')),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _saving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not assign ${widget.title.toLowerCase()}.'),
        ),
      );
    }
  }

  Future<void> _remove() async {
    final assignment = _currentAssignment;

    if (assignment == null) return;

    setState(() {
      _saving = true;
    });

    try {
      await widget.session.assignments.delete(assignment.id);

      if (!mounted) return;

      await widget.onChanged();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${widget.title} removed successfully.')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not remove ${widget.title.toLowerCase()}.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _currentUser;
    final availableStaff = _availableStaff;

    return Container(
      padding: const EdgeInsets.all(18),
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
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceAlt,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(widget.icon, color: AppTheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          if (widget.loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: CircularProgressIndicator(),
              ),
            )
          else if (currentUser != null)
            _AssignedUserView(
              user: currentUser,
              saving: _saving,
              onRemove: _remove,
            )
          else if (availableStaff.isEmpty)
            _MessageCard(
              message: 'No ${widget.role} accounts are available yet.',
            )
          else ...[
            DropdownButtonFormField<int>(
              value: _selectedUserId,
              decoration: InputDecoration(
                labelText: 'Select ${widget.title}',
                prefixIcon: Icon(widget.icon),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              items: availableStaff.map((user) {
                return DropdownMenuItem<int>(
                  value: user.id,
                  child: Text(user.name),
                );
              }).toList(),
              onChanged: _saving
                  ? null
                  : (value) {
                      setState(() {
                        _selectedUserId = value;
                      });
                    },
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _saving || _selectedUserId == null ? null : _assign,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.person_add_rounded),
                label: Text(
                  _saving ? 'Assigning...' : 'Assign ${widget.title}',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AssignedUserView extends StatelessWidget {
  final ApiUser user;
  final bool saving;
  final VoidCallback onRemove;

  const _AssignedUserView({
    required this.user,
    required this.saving,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceAlt,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppTheme.primary,
            child: Text(
              user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 3),
                Text(
                  user.email,
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Remove',
            onPressed: saving ? null : onRemove,
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }
}

class _WelcomeCard extends StatelessWidget {
  final String childName;

  const _WelcomeCard({required this.childName});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppTheme.primary,
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        boxShadow: AppTheme.shadowSoft,
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              Icons.child_care_rounded,
              size: 32,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Welcome back!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$childName\'s Learning Journey',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OpenChildDashboardButton extends StatelessWidget {
  final String childName;
  final VoidCallback onTap;

  const _OpenChildDashboardButton({
    required this.childName,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.primary,
      borderRadius: BorderRadius.circular(AppTheme.radiusMD),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.child_friendly_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Open Child Dashboard',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'View $childName\'s activities and games',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChildSelector extends StatelessWidget {
  final List<ApiChild> children;
  final int? selectedChildId;
  final ValueChanged<ApiChild> onChanged;

  const _ChildSelector({
    required this.children,
    required this.selectedChildId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        boxShadow: AppTheme.shadowSoft,
      ),
      child: Row(
        children: [
          Icon(Icons.people_alt_rounded, color: AppTheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: selectedChildId,
                isExpanded: true,
                hint: const Text('Select child'),
                items: children.map((child) {
                  return DropdownMenuItem<int>(
                    value: child.id,
                    child: Text(
                      child.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  );
                }).toList(),
                onChanged: (id) {
                  if (id == null) return;

                  final child = children.firstWhere((child) => child.id == id);

                  onChanged(child);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OverallProgressCard extends StatelessWidget {
  final double accuracy;
  final int activitiesCompleted;

  const _OverallProgressCard({
    required this.accuracy,
    required this.activitiesCompleted,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (accuracy / 100).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        boxShadow: AppTheme.shadowSoft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Overall Progress',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              SizedBox(
                width: 82,
                height: 82,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 8,
                      backgroundColor: AppTheme.surfaceAlt,
                    ),
                    Text(
                      '${accuracy.round()}%',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Text(
                  '$activitiesCompleted activities completed',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 15),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AiInsightCard extends StatelessWidget {
  final ApiAiInsight? insight;

  const _AiInsightCard({required this.insight});

  @override
  Widget build(BuildContext context) {
    if (insight == null) {
      return const _MessageCard(
        message: 'AI insights will appear after learning data is available.',
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        border: Border.all(color: AppTheme.outline),
        boxShadow: AppTheme.shadowSoft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (insight!.overallStatus.isNotEmpty)
            Text(
              insight!.overallStatus,
              style: TextStyle(
                color: AppTheme.primary,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
          if (insight!.summary.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              insight!.summary,
              style: const TextStyle(fontSize: 15, height: 1.45),
            ),
          ],
          if (insight!.parentAdvice.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.surfaceAlt,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lightbulb_rounded, color: AppTheme.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      insight!.parentAdvice,
                      style: const TextStyle(fontSize: 14, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionTitle({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 22, color: AppTheme.primary),
        const SizedBox(width: 9),
        Text(
          title,
          style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}

class _TagList extends StatelessWidget {
  final List<String> items;
  final String emptyText;

  const _TagList({required this.items, required this.emptyText});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return _MessageCard(message: emptyText);
    }

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: items.map((item) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: AppTheme.outline),
          ),
          child: Text(
            _pretty(item),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        );
      }).toList(),
    );
  }
}

class _CategoryProgressCard extends StatelessWidget {
  final String category;
  final ApiCategoryPerformance performance;

  const _CategoryProgressCard({
    required this.category,
    required this.performance,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (performance.accuracy / 100).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        boxShadow: AppTheme.shadowSoft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _pretty(category),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '${performance.accuracy.round()}%',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            borderRadius: BorderRadius.circular(20),
            backgroundColor: AppTheme.surfaceAlt,
          ),
          const SizedBox(height: 10),
          Text(
            '${performance.activitiesCompleted} activities completed',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  final ApiRecommendationItem recommendation;

  const _RecommendationCard({required this.recommendation});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.play_circle_fill_rounded,
            color: AppTheme.primary,
            size: 28,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _pretty(recommendation.category),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  recommendation.reason,
                  style: TextStyle(color: AppTheme.textSecondary, height: 1.35),
                ),
                const SizedBox(height: 9),
                Text(
                  'Difficulty ${recommendation.difficulty} • '
                  '${_pretty(recommendation.priority)} priority',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DifficultyCard extends StatelessWidget {
  final String category;
  final ApiDifficultyDecision decision;

  const _DifficultyCard({required this.category, required this.decision});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        boxShadow: AppTheme.shadowSoft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _pretty(category),
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _DifficultyValue(
                  label: 'Current',
                  value: decision.currentDifficulty,
                ),
              ),
              Icon(Icons.arrow_forward_rounded, color: AppTheme.primary),
              Expanded(
                child: _DifficultyValue(
                  label: 'Next',
                  value: decision.nextDifficulty,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            decision.reason,
            style: TextStyle(color: AppTheme.textSecondary, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _DifficultyValue extends StatelessWidget {
  final String label;
  final int value;

  const _DifficultyValue({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          '$value',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: AppTheme.primary,
          ),
        ),
      ],
    );
  }
}

class _MessageCard extends StatelessWidget {
  final String message;

  const _MessageCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        boxShadow: AppTheme.shadowSoft,
      ),
      child: Text(
        message,
        style: TextStyle(color: AppTheme.textSecondary, height: 1.4),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, size: 48, color: AppTheme.error),
            const SizedBox(height: 14),
            const Text(
              'Unable to load dashboard',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'No learning data is available yet.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 17, color: AppTheme.textSecondary),
        ),
      ),
    );
  }
}

String _pretty(String value) {
  if (value.trim().isEmpty) return value;

  return value
      .replaceAll('_', ' ')
      .split(' ')
      .where((word) => word.isNotEmpty)
      .map((word) => word[0].toUpperCase() + word.substring(1))
      .join(' ');
}

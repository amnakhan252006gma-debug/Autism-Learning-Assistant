import 'package:flutter/material.dart';

import '../models/routine_item.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_page.dart';

/// Visual daily schedule for the child.
///
/// Loads mock data from [RoutineItem.defaultSchedule].  A future backend
/// integration will replace the data source – the screen only depends on
/// `List<RoutineItem>`, so swapping in a repository call is trivial.
class RoutineScreen extends StatefulWidget {
  const RoutineScreen({super.key});

  @override
  State<RoutineScreen> createState() => _RoutineScreenState();
}

class _RoutineScreenState extends State<RoutineScreen> {
  late List<RoutineItem> _items;

  @override
  void initState() {
    super.initState();
    _items = List<RoutineItem>.from(RoutineItem.defaultSchedule())
      ..sort((a, b) => a.order.compareTo(b.order));
  }

  void _toggleItem(int index) {
    setState(() {
      _items[index] = _items[index].toggled();
    });
  }

  int get _completedCount => _items.where((i) => i.isCompleted).length;

  @override
  Widget build(BuildContext context) {
    return AnimatedPage(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Day'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, size: 32),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            // Progress badge
            Padding(
              padding: const EdgeInsets.only(right: AppTheme.spaceMD),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spaceSM,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.success.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                  ),
                  child: Text(
                    '$_completedCount / ${_items.length}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.success,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        body: ListView.builder(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.spaceLG,
            AppTheme.spaceSM,
            AppTheme.spaceLG,
            AppTheme.spaceXXL,
          ),
          itemCount: _items.length,
          itemBuilder: (context, index) {
            final item = _items[index];
            final isLast = index == _items.length - 1;
            return StaggeredEntrance(
              index: index,
              child: _RoutineTile(
                item: item,
                showConnector: !isLast,
                onTap: () => _toggleItem(index),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// Private widgets
// ═══════════════════════════════════════════════════════════════════════

/// Single routine step with optional vertical connector line.
class _RoutineTile extends StatelessWidget {
  final RoutineItem item;
  final bool showConnector;
  final VoidCallback onTap;

  const _RoutineTile({
    required this.item,
    required this.showConnector,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Timeline column ───────────────────────────────────────
          SizedBox(
            width: 54,
            child: Column(
              children: [
                // Circle indicator
                GestureDetector(
                  onTap: onTap,
                  child: AnimatedContainer(
                    duration: AppTheme.animationFast,
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: item.isCompleted
                          ? item.color
                          : item.color.withValues(alpha: .18),
                      shape: BoxShape.circle,
                      border: Border.all(color: item.color, width: 2.5),
                      boxShadow: item.isCompleted
                          ? [
                              BoxShadow(
                                color: item.color.withValues(alpha: .35),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: AnimatedSwitcher(
                      duration: AppTheme.animationFast,
                      child: item.isCompleted
                          ? const Icon(
                              Icons.check_rounded,
                              key: ValueKey('done'),
                              color: Colors.white,
                              size: 24,
                            )
                          : Text(
                              item.icon,
                              key: ValueKey(item.id),
                              style: const TextStyle(fontSize: 20),
                            ),
                    ),
                  ),
                ),
                // Connector line
                if (showConnector)
                  Expanded(
                    child: Container(
                      width: 3,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: item.isCompleted
                            ? item.color.withValues(alpha: .60)
                            : item.color.withValues(alpha: .18),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ── Card ──────────────────────────────────────────────────
          Expanded(
            child: GestureDetector(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.only(bottom: AppTheme.spaceSM),
                child: AnimatedContainer(
                  duration: AppTheme.animationNormal,
                  curve: Curves.easeOutCubic,
                  decoration: BoxDecoration(
                    color: item.isCompleted
                        ? AppTheme.surfaceAlt
                        : AppTheme.surface,
                    borderRadius: BorderRadius.circular(AppTheme.radiusLG),
                    border: Border.all(
                      color: item.isCompleted
                          ? item.color.withValues(alpha: .40)
                          : AppTheme.outline,
                      width: item.isCompleted ? 2 : 1,
                    ),
                    boxShadow: AppTheme.shadowSoft,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spaceMD,
                      vertical: AppTheme.spaceSM,
                    ),
                    child: Row(
                      children: [
                        // Icon bubble
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: item.color.withValues(alpha: .14),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            item.icon,
                            style: const TextStyle(fontSize: 26),
                          ),
                        ),
                        const SizedBox(width: AppTheme.spaceSM),
                        // Title + time
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: item.isCompleted
                                      ? AppTheme.textSecondary
                                      : AppTheme.textPrimary,
                                  decoration: item.isCompleted
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Icon(
                                    Icons.access_time_rounded,
                                    size: 14,
                                    color: AppTheme.textSecondary.withValues(
                                      alpha: .7,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    item.time,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Step number badge
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: item.color.withValues(alpha: .15),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${item.order + 1}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.deepOf(item.color),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

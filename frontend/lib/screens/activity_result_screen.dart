import 'package:flutter/material.dart';

import '../models/activity_question.dart';
import '../models/activity_result.dart';
import '../theme/app_theme.dart';
import '../widgets/child_button.dart';
import 'activity_screen.dart';

/// Final result screen shown when a learning activity is completed.
///
/// Displays score, accuracy, correct/wrong counts, total attempts
/// and encouraging feedback in a child-friendly layout.
class ActivityResultScreen extends StatelessWidget {
  const ActivityResultScreen({
    super.key,
    required this.activityTitle,
    required this.color,
    required this.questions,
    required this.result,
  });

  final String activityTitle;
  final Color color;
  final List<ActivityQuestion> questions;
  final ActivityResult result;

  bool get _isPerfect => result.score == result.totalQuestions;

  bool get _isGood => result.score >= result.totalQuestions * 0.6;

  String get _emoji => _isPerfect ? '🎉' : (_isGood ? '🌟' : '🤗');

  String get _message =>
      _isPerfect ? 'Perfect!' : (_isGood ? 'Great job!' : 'Good try!');

  String get _accuracyText {
    if (result.totalAttempts == 0) return '0%';
    return '${result.accuracy.round()}%';
  }

  void _playAgain(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ActivityScreen(
          title: activityTitle,
          color: color,
          questions: questions,
          difficulty: result.difficulty,
          childId: result.childId,
          activityId: result.activityId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(activityTitle),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.spaceLG),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(_emoji, style: const TextStyle(fontSize: 96)),
                const SizedBox(height: AppTheme.spaceMD),
                Text(
                  _message,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: AppTheme.spaceLG),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (int i = 0; i < result.totalQuestions; i++)
                      Icon(
                        Icons.star_rounded,
                        size: 44,
                        color: i < result.score
                            ? const Color(0xFFFFC107)
                            : Colors.grey.shade300,
                      ),
                  ],
                ),
                const SizedBox(height: AppTheme.spaceSM),
                Text(
                  '${result.score} / ${result.totalQuestions}',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: AppTheme.spaceMD),
                Text(
                  'Accuracy: $_accuracyText',
                  style: TextStyle(fontSize: 18, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: AppTheme.spaceSM),
                _buildStatsRow(
                  Icons.check_circle_outline_rounded,
                  'Correct',
                  '${result.correctAnswers}',
                  AppTheme.gamesColor,
                ),
                const SizedBox(height: AppTheme.spaceSM),
                _buildStatsRow(
                  Icons.refresh_rounded,
                  'Tries',
                  '${result.totalAttempts}',
                  AppTheme.communicateColor,
                ),
                const SizedBox(height: AppTheme.spaceXL),
                ChildButton(
                  label: 'Play Again',
                  icon: Icons.replay_rounded,
                  onTap: () => _playAgain(context),
                ),
                const SizedBox(height: AppTheme.spaceMD),
                ChildButton(
                  label: 'All Done',
                  icon: Icons.home_rounded,
                  color: AppTheme.primaryLight,
                  onTap: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsRow(
    IconData icon,
    String label,
    String value,
    Color iconColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spaceLG,
        vertical: AppTheme.spaceSM,
      ),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        boxShadow: [
          BoxShadow(
            color: AppTheme.cardShadow,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: iconColor, size: 28),
          const SizedBox(width: AppTheme.spaceSM),
          Text(
            label,
            style: TextStyle(fontSize: 18, color: AppTheme.textSecondary),
          ),
          const SizedBox(width: AppTheme.spaceMD),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

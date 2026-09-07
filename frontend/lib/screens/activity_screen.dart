import 'dart:async';

import 'package:flutter/material.dart';

import '../models/activity_attempt.dart';
import '../models/activity_question.dart';
import '../models/activity_result.dart';
import '../services/backend_service.dart';
import '../theme/app_theme.dart';
import '../widgets/answer_choice_button.dart';
import 'activity_result_screen.dart';

/// Generic reusable learning-activity runner.
///
/// Difficulty is supplied by the adaptive backend recommendation.
/// The activity records attempts and the completed result so the backend
/// can calculate the learner's next personalized difficulty.
class ActivityScreen extends StatefulWidget {
  const ActivityScreen({
    super.key,
    required this.title,
    required this.color,
    required this.questions,
    this.difficulty = 1,
    required this.childId,
    required this.activityId,
    this.clock,
  });

  final String title;
  final Color color;
  final List<ActivityQuestion> questions;
  final int difficulty;
  final int childId;
  final int activityId;

  final DateTime Function()? clock;

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  static const Duration _advanceDelay = Duration(milliseconds: 1500);

  int _currentQuestionIndex = 0;
  int _score = 0;
  int _attemptsThisQuestion = 0;

  int? _wrongChoiceIndex;

  bool _answeredCorrect = false;
  bool _savingAttempt = false;
  bool _savingResult = false;

  Timer? _advanceTimer;

  final List<ActivityAttempt> _attempts = [];

  DateTime _questionStartTime = DateTime.now();

  ActivityQuestion get _question => widget.questions[_currentQuestionIndex];

  bool get _isLastQuestion =>
      _currentQuestionIndex == widget.questions.length - 1;

  String get _difficultyTitle {
    switch (widget.difficulty) {
      case 3:
        return 'Challenge';

      case 2:
        return 'Practice';

      default:
        return 'Starter';
    }
  }

  @override
  void initState() {
    super.initState();

    _questionStartTime = (widget.clock ?? DateTime.now)();
  }

  @override
  void didUpdateWidget(covariant ActivityScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.childId != widget.childId ||
        oldWidget.activityId != widget.activityId ||
        oldWidget.difficulty != widget.difficulty ||
        oldWidget.questions != widget.questions) {
      _advanceTimer?.cancel();

      _currentQuestionIndex = 0;
      _score = 0;
      _attemptsThisQuestion = 0;
      _wrongChoiceIndex = null;
      _answeredCorrect = false;
      _savingAttempt = false;
      _savingResult = false;

      _attempts.clear();

      _questionStartTime = (widget.clock ?? DateTime.now)();
    }
  }

  @override
  void dispose() {
    _advanceTimer?.cancel();
    super.dispose();
  }

  Future<void> _onChoiceTapped(int index) async {
    if (_answeredCorrect || _savingAttempt || _savingResult) {
      return;
    }

    final now = (widget.clock ?? DateTime.now)();

    final responseTime = now.difference(_questionStartTime);

    final isCorrect = index == _question.correctIndex;

    final attempt = ActivityAttempt(
      childId: widget.childId,
      activityId: widget.activityId,
      questionIndex: _currentQuestionIndex,
      isCorrect: isCorrect,
      responseTime: responseTime,
      timestamp: now,
    );

    setState(() {
      _attemptsThisQuestion++;

      _attempts.add(attempt);

      if (isCorrect) {
        _answeredCorrect = true;
        _wrongChoiceIndex = null;

        if (_attemptsThisQuestion == 1) {
          _score++;
        }

        _advanceTimer?.cancel();
      } else {
        _wrongChoiceIndex = index;
      }
    });

    // Save the attempt outside setState.
    // The activity remains responsive while the backend receives the
    // performance signal used by the adaptive system.
    await _saveAttempt(attempt);

    if (!mounted) return;

    if (isCorrect) {
      _advanceTimer = Timer(_advanceDelay, _onAdvance);
    }
  }

  Future<void> _saveAttempt(ActivityAttempt attempt) async {
    if (!mounted) return;

    setState(() {
      _savingAttempt = true;
    });

    try {
      await BackendService.instance.sendAttempt(
        childId: attempt.childId,
        activityId: attempt.activityId,
        difficulty: widget.difficulty,
        correct: attempt.isCorrect,
        responseTime: attempt.responseTime.inMilliseconds / 1000,
        attemptNumber: attempt.attemptNumber,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Attempt could not be synced. The final result will still be saved.',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _savingAttempt = false;
        });
      }
    }
  }

  Future<void> _saveToBackend(ActivityResult result) async {
    setState(() {
      _savingResult = true;
    });

    try {
      await BackendService.instance.sendResult(
        childId: result.childId,
        activityId: result.activityId,
        difficulty: result.difficulty,
        score: result.score.toDouble(),
        correctAnswers: result.correctAnswers,
        incorrectAnswers: result.wrongAnswers,
        attempts: result.totalAttempts,
        timeTaken: result.averageResponseTime * result.totalAttempts,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not save the final result: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _savingResult = false;
        });
      }
    }
  }

  Future<void> _onAdvance() async {
    _advanceTimer = null;

    if (!mounted || _savingResult) {
      return;
    }

    if (_isLastQuestion) {
      final result = ActivityResult.fromAttempts(
        childId: widget.childId,
        activityId: widget.activityId,
        category: widget.title.toLowerCase(),
        difficulty: widget.difficulty,
        attempts: List.unmodifiable(_attempts),
        score: _score,
        totalQuestions: widget.questions.length,
      );

      // The completed result must reach the backend before leaving.
      // This is what allows the next Learning screen refresh to use
      // the newly calculated adaptive recommendation.
      await _saveToBackend(result);

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ActivityResultScreen(
            activityTitle: widget.title,
            color: widget.color,
            questions: widget.questions,
            result: result,
          ),
        ),
      );
    } else {
      setState(() {
        _currentQuestionIndex++;
        _attemptsThisQuestion = 0;
        _wrongChoiceIndex = null;
        _answeredCorrect = false;
        _savingAttempt = false;

        _questionStartTime = (widget.clock ?? DateTime.now)();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: const Center(child: Text('No questions yet')),
      );
    }

    final question = _question;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, size: 32),
          onPressed: _savingResult ? null : () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: AppTheme.spaceSM),

            _ProgressDots(
              total: widget.questions.length,
              current: _currentQuestionIndex,
              activeColor: widget.color,
            ),

            const SizedBox(height: AppTheme.spaceSM),

            _DifficultyBadge(
              difficulty: widget.difficulty,
              title: _difficultyTitle,
            ),

            const SizedBox(height: AppTheme.spaceMD),

            if (question.promptAsset != null) ...[
              Image.asset(
                question.promptAsset!,
                height: 90,
                width: 90,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: AppTheme.spaceSM),
            ],

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceLG),
              child: Text(
                question.prompt,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),

            const SizedBox(height: AppTheme.spaceLG),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spaceLG,
                ),
                child: _buildChoices(),
              ),
            ),

            _buildFeedbackBanner(),
          ],
        ),
      ),
    );
  }

  Widget _buildChoices() {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = AppTheme.spaceMD;

        final tileWidth = (constraints.maxWidth - gap) / 2;

        return Wrap(
          alignment: WrapAlignment.center,
          spacing: gap,
          runSpacing: gap,
          children: [
            for (int i = 0; i < _question.choices.length; i++)
              SizedBox(
                width: tileWidth,
                child: AnswerChoiceButton(
                  key: ValueKey('choice_$i'),
                  choice: _question.choices[i],
                  enabled:
                      !_answeredCorrect && !_savingAttempt && !_savingResult,
                  feedback: _answeredCorrect && i == _question.correctIndex
                      ? AnswerFeedback.correct
                      : _wrongChoiceIndex == i
                      ? AnswerFeedback.incorrect
                      : AnswerFeedback.idle,
                  onTap: () => _onChoiceTapped(i),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildFeedbackBanner() {
    final bool isIdle = !_answeredCorrect && _wrongChoiceIndex == null;

    final String message;
    final IconData icon;
    final Color backgroundColor;

    if (_savingResult) {
      message = 'Saving your progress...';
      icon = Icons.cloud_upload_rounded;
      backgroundColor = AppTheme.primary;
    } else if (_answeredCorrect) {
      message = 'Great job! Your progress is being personalized.';
      icon = Icons.auto_awesome_rounded;
      backgroundColor = AppTheme.gamesColor;
    } else if (_wrongChoiceIndex != null) {
      message = 'Try again! You can do it!';
      icon = Icons.favorite_rounded;
      backgroundColor = AppTheme.communicateColor;
    } else {
      message = 'Tap your answer';
      icon = Icons.touch_app_rounded;
      backgroundColor = AppTheme.primaryLight;
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: Container(
        key: ValueKey<String>(message),
        margin: const EdgeInsets.all(AppTheme.spaceMD),
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spaceLG,
          vertical: AppTheme.spaceMD,
        ),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_savingAttempt && !_answeredCorrect)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Icon(
                icon,
                color: isIdle ? AppTheme.textPrimary : Colors.white,
                size: AppTheme.iconSM,
              ),

            const SizedBox(width: AppTheme.spaceSM),

            Flexible(
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: isIdle ? AppTheme.textPrimary : Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DifficultyBadge extends StatelessWidget {
  const _DifficultyBadge({required this.difficulty, required this.title});

  final int difficulty;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: AppTheme.surfaceAlt,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome_rounded, size: 17, color: AppTheme.primary),
          const SizedBox(width: 6),
          Text(
            'Personalized • Level $difficulty • $title',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _ProgressDots extends StatelessWidget {
  const _ProgressDots({
    required this.total,
    required this.current,
    required this.activeColor,
  });

  final int total;
  final int current;
  final Color activeColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (index) {
        final Color dotColor;

        if (index < current) {
          dotColor = AppTheme.gamesColor;
        } else if (index == current) {
          dotColor = activeColor;
        } else {
          dotColor = Colors.grey.shade300;
        }

        return Container(
          width: 18,
          height: 18,
          margin: const EdgeInsets.symmetric(horizontal: 5),
          decoration: BoxDecoration(shape: BoxShape.circle, color: dotColor),
        );
      }),
    );
  }
}

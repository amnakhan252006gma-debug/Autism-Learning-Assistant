import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../services/app_session.dart';
import '../services/backend_service.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_page.dart';
import '../widgets/child_button.dart';

class GameFeedback {
  const GameFeedback({required this.message, required this.isCorrect});

  final String message;
  final bool isCorrect;
}

class GameInstructionBanner extends StatelessWidget {
  const GameInstructionBanner({
    super.key,
    required this.title,
    required this.subtitle,
    this.color,
    this.asset,
  });

  final String title;
  final String subtitle;
  final Color? color;
  final String? asset;

  @override
  Widget build(BuildContext context) {
    final accent = color ?? AppTheme.primary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: accent.withValues(alpha: 0.20)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(15),
            ),
            child: asset != null
                ? Image.asset(
                    asset!,
                    width: 32,
                    height: 32,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) {
                      return Icon(Icons.lightbulb_rounded, color: accent);
                    },
                  )
                : Icon(Icons.lightbulb_rounded, color: accent),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class GameProgressDots extends StatelessWidget {
  const GameProgressDots({
    super.key,
    required this.current,
    required this.total,
    this.color,
  });

  final int current;
  final int total;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final accent = color ?? AppTheme.primary;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (index) {
        final active = index == current;
        final completed = index < current;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 24 : 9,
          height: 9,
          decoration: BoxDecoration(
            color: completed || active
                ? accent
                : accent.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(20),
          ),
        );
      }),
    );
  }
}

class GameFeedbackBanner extends StatelessWidget {
  const GameFeedbackBanner({super.key, required this.feedback});

  final GameFeedback? feedback;

  @override
  Widget build(BuildContext context) {
    if (feedback == null) {
      return const SizedBox(height: 58);
    }

    // Use colors that already exist in the project.
    final color = feedback!.isCorrect
        ? AppTheme.primary
        : AppTheme.communicateColor;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      child: Container(
        key: ValueKey(feedback!.message),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: 0.20)),
        ),
        child: Row(
          children: [
            Icon(
              feedback!.isCorrect
                  ? Icons.check_circle_rounded
                  : Icons.refresh_rounded,
              color: color,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                feedback!.message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GameTapCard extends StatelessWidget {
  const GameTapCard({
    super.key,
    required this.child,
    required this.onTap,
    this.color,
    this.selected = false,
    this.enabled = true,
  });

  final Widget child;
  final VoidCallback onTap;
  final Color? color;
  final bool selected;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final accent = color ?? AppTheme.primary;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: selected
              ? accent
              : Theme.of(context).dividerColor.withValues(alpha: 0.5),
          width: selected ? 2.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: selected ? 14 : 8,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: enabled ? onTap : null,
          child: Padding(padding: const EdgeInsets.all(14), child: child),
        ),
      ),
    );
  }
}

class GameImageTile extends StatelessWidget {
  const GameImageTile({
    super.key,
    required this.asset,
    this.label,
    this.color,
    this.fit = BoxFit.contain,
  });

  final String asset;
  final String? label;
  final Color? color;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final accent = color ?? AppTheme.primary;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Image.asset(
              asset,
              fit: fit,
              errorBuilder: (_, __, ___) {
                return Icon(
                  Icons.image_not_supported_outlined,
                  size: 48,
                  color: accent.withValues(alpha: 0.5),
                );
              },
            ),
          ),
        ),
        if (label != null) ...[
          const SizedBox(height: 8),
          Text(
            label!,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ],
    );
  }
}

class GameResultScreen extends StatefulWidget {
  const GameResultScreen({
    super.key,
    required this.gameTitle,
    required this.color,
    required this.stars,
    required this.scoreText,
    required this.playAgainScreen,
    this.maxStars = 3,
    this.extra,
    this.backendActivityName,
    this.backendCategory,
    this.difficulty = 1,
    this.correctAnswers,
    this.incorrectAnswers,
    this.totalAttempts,
    this.totalQuestions,
    this.timeTakenSeconds,
  });

  final String gameTitle;
  final Color color;
  final int stars;
  final int maxStars;
  final String scoreText;
  final Widget playAgainScreen;
  final Widget? extra;

  final String? backendActivityName;
  final String? backendCategory;

  final int difficulty;

  final int? correctAnswers;
  final int? incorrectAnswers;
  final int? totalAttempts;
  final int? totalQuestions;
  final double? timeTakenSeconds;

  @override
  State<GameResultScreen> createState() => _GameResultScreenState();
}

class _GameResultScreenState extends State<GameResultScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );

    _controller.forward();

    _syncBackendResult();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _syncBackendResult() async {
    if (widget.backendActivityName == null ||
        widget.correctAnswers == null ||
        widget.incorrectAnswers == null ||
        widget.totalAttempts == null) {
      return;
    }

    final session = AppSession.instance;
    final child = session.activeChild;

    if (child == null) {
      return;
    }

    try {
      /*
       * We intentionally do not use activityForGame() here because
       * your current AppSession does not expose that method.
       *
       * The result synchronization is therefore kept optional.
       *
       * Once the backend activity lookup is exposed by AppSession,
       * this section can be connected directly to it.
       */
      return;
    } catch (_) {
      // Never allow backend synchronization to crash
      // the game result screen.
    }
  }

  @override
  Widget build(BuildContext context) {
    final safeStars = math.max(0, math.min(widget.stars, widget.maxStars));

    return Scaffold(
      body: SafeArea(
        child: AnimatedPage(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 12),

                ScaleTransition(
                  scale: _scaleAnimation,
                  child: Container(
                    width: 86,
                    height: 86,
                    decoration: BoxDecoration(
                      color: widget.color.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.celebration_rounded,
                      size: 48,
                      color: widget.color,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                Text(
                  'Great job!',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  widget.gameTitle,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: widget.color,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 20),

                GameStars(
                  stars: safeStars,
                  maxStars: widget.maxStars,
                  color: widget.color,
                ),

                const SizedBox(height: 16),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 18,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: widget.color.withValues(alpha: 0.18),
                    ),
                  ),
                  child: Text(
                    widget.scoreText,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),

                if (widget.extra != null) ...[
                  const SizedBox(height: 18),
                  widget.extra!,
                ],

                const SizedBox(height: 28),

                ChildButton(
                  label: 'Play Again',
                  icon: Icons.replay_rounded,
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => widget.playAgainScreen),
                    );
                  },
                ),

                const SizedBox(height: 12),

                ChildButton(
                  label: 'Back to Games',
                  icon: Icons.grid_view_rounded,
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class GameStars extends StatelessWidget {
  const GameStars({
    super.key,
    required this.stars,
    this.maxStars = 3,
    this.color,
  });

  final int stars;
  final int maxStars;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final accent = color ?? AppTheme.starGold;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(maxStars, (index) {
        final filled = index < stars;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Icon(
            filled ? Icons.star_rounded : Icons.star_border_rounded,
            size: 42,
            color: filled ? accent : accent.withValues(alpha: 0.25),
          ),
        );
      }),
    );
  }
}

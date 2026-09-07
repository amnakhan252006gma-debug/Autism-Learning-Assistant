import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/activity_question.dart';
import '../theme/app_theme.dart';

enum AnswerFeedback { idle, correct, incorrect }

class AnswerChoiceButton extends StatefulWidget {
  const AnswerChoiceButton({
    super.key,
    required this.choice,
    required this.onTap,
    this.feedback = AnswerFeedback.idle,
    this.enabled = true,
  });

  final ActivityChoice choice;
  final VoidCallback onTap;
  final AnswerFeedback feedback;
  final bool enabled;

  @override
  State<AnswerChoiceButton> createState() => _AnswerChoiceButtonState();
}

class _AnswerChoiceButtonState extends State<AnswerChoiceButton>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;
  late final AnimationController _feedbackController;

  @override
  void initState() {
    super.initState();
    _feedbackController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void didUpdateWidget(covariant AnswerChoiceButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.feedback != widget.feedback &&
        widget.feedback != AnswerFeedback.idle) {
      _feedbackController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSwatch = widget.choice.type == ChoiceVisualType.color;
    final isCorrect = widget.feedback == AnswerFeedback.correct;
    final isIncorrect = widget.feedback == AnswerFeedback.incorrect;

    return Semantics(
      excludeSemantics: true,
      label: widget.choice.label,
      button: true,
      child: GestureDetector(
        onTapDown: widget.enabled
            ? (_) => setState(() => _pressed = true)
            : null,
        onTapCancel: widget.enabled
            ? () => setState(() => _pressed = false)
            : null,
        onTapUp: widget.enabled
            ? (_) => setState(() => _pressed = false)
            : null,
        onTap: widget.enabled ? widget.onTap : null,
        child: AnimatedScale(
          scale: _pressed ? .94 : 1,
          duration: AppTheme.animationFast,
          curve: Curves.easeOut,
          child: Opacity(
            opacity: !widget.enabled && !isCorrect ? .45 : 1,
            child: AnimatedBuilder(
              animation: _feedbackController,
              builder: (context, child) {
                final t = _feedbackController.value;
                if (isCorrect) {
                  // Gentle positive "pop": grows a touch, then settles.
                  return Transform.scale(
                    scale: 1 + math.sin(t * math.pi) * .03,
                    child: child,
                  );
                }
                if (isIncorrect) {
                  // Subtle damped side-to-side shake that fades out.
                  final dx = math.sin(t * math.pi * 3) * 5 * (1 - t);
                  return Transform.translate(
                    offset: Offset(dx, 0),
                    child: child,
                  );
                }
                return child!;
              },
              child: AnimatedContainer(
                duration: AppTheme.animationNormal,
                curve: Curves.easeOutCubic,
                height: 140,
                decoration: BoxDecoration(
                  color: isSwatch
                      ? widget.choice.color
                      : isCorrect
                      ? AppTheme.success.withValues(alpha: .08)
                      : isIncorrect
                      ? AppTheme.error.withValues(alpha: .07)
                      : AppTheme.surface,
                  borderRadius: BorderRadius.circular(AppTheme.radiusLG),
                  border: Border.all(
                    color: isCorrect
                        ? AppTheme.success
                        : isIncorrect
                        ? AppTheme.error
                        : isSwatch
                        ? Colors.transparent
                        : AppTheme.outline,
                    width: isCorrect || isIncorrect ? 3.5 : 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isCorrect
                          ? AppTheme.success.withValues(alpha: .18)
                          : isIncorrect
                          ? AppTheme.error.withValues(alpha: .15)
                          : AppTheme.cardShadow,
                      blurRadius: isCorrect || isIncorrect ? 16 : 10,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Center(child: _buildContent()),
                    if (isCorrect || isIncorrect)
                      Positioned(
                        top: 9,
                        right: 9,
                        child: AnimatedScale(
                          scale: _feedbackController.value,
                          duration: AppTheme.animationFast,
                          child: Icon(
                            isCorrect
                                ? Icons.check_circle_rounded
                                : Icons.close_rounded,
                            size: 36,
                            color: isCorrect
                                ? (isSwatch ? Colors.white : AppTheme.success)
                                : AppTheme.error,
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
    );
  }

  Widget _buildContent() {
    switch (widget.choice.type) {
      case ChoiceVisualType.color:
        return const SizedBox.shrink();
      case ChoiceVisualType.shape:
        return Icon(
          widget.choice.icon,
          size: AppTheme.iconLG,
          color: AppTheme.textPrimary,
        );
      case ChoiceVisualType.text:
        return Text(
          widget.choice.label,
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
          ),
        );
    }
  }
}

import 'package:flutter/material.dart';

/// How an answer choice is visually rendered inside an activity.
enum ChoiceVisualType { color, shape, text }

/// A single answer choice of a learning activity question.
class ActivityChoice {
  final String label;
  final ChoiceVisualType type;
  final Color? color;
  final IconData? icon;

  const ActivityChoice({
    required this.label,
    required this.type,
    this.color,
    this.icon,
  });

  /// A colour swatch choice, e.g. the answer "Red".
  const ActivityChoice.color(String label, Color color)
    : this(label: label, type: ChoiceVisualType.color, color: color);

  /// A shape choice, e.g. the answer "Circle".
  const ActivityChoice.shape(String label, IconData icon)
    : this(label: label, type: ChoiceVisualType.shape, icon: icon);

  /// A plain text choice, e.g. the answer "Cat".
  const ActivityChoice.text(String label)
    : this(label: label, type: ChoiceVisualType.text);
}

/// One question of a learning activity.
class ActivityQuestion {
  final String prompt;
  final List<ActivityChoice> choices;
  final int correctIndex;

  /// Optional picture shown above the prompt (e.g. assets/images/cat.png
  /// for word matching).
  final String? promptAsset;

  const ActivityQuestion({
    required this.prompt,
    required this.choices,
    required this.correctIndex,
    this.promptAsset,
  });

  ActivityChoice get correctChoice => choices[correctIndex];
}

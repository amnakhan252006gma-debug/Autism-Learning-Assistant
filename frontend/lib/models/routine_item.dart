import 'package:flutter/material.dart';

/// A single step in the child's visual daily schedule.
///
/// Designed to stay backend-ready: every field maps cleanly to a JSON
/// document that a parent dashboard can later create, edit, or reorder.
class RoutineItem {
  /// Unique identifier for backend sync.
  final String id;

  /// Short display title (e.g. "Brush Teeth").
  final String title;

  /// Emoji or icon asset used as the visual cue.
  final String icon;

  /// Human-readable time label shown on the tile (e.g. "7:30 AM").
  final String time;

  /// Position in the schedule (0-based). Lower numbers happen first.
  final int order;

  /// Accent colour for the tile.
  final Color color;

  /// Whether the child (or parent) has marked this step as done today.
  final bool isCompleted;

  const RoutineItem({
    required this.id,
    required this.title,
    required this.icon,
    required this.time,
    required this.order,
    required this.color,
    this.isCompleted = false,
  });

  /// Returns a copy with [isCompleted] toggled.
  RoutineItem toggled() => copyWith(isCompleted: !isCompleted);

  RoutineItem copyWith({
    String? id,
    String? title,
    String? icon,
    String? time,
    int? order,
    Color? color,
    bool? isCompleted,
  }) {
    return RoutineItem(
      id: id ?? this.id,
      title: title ?? this.title,
      icon: icon ?? this.icon,
      time: time ?? this.time,
      order: order ?? this.order,
      color: color ?? this.color,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  /// Default mock schedule for Day 4.
  ///
  /// Matches the required sequence:
  /// Wake Up -> Brush Teeth -> Breakfast -> School -> Learning -> Play
  /// -> Dinner -> Sleep
  static List<RoutineItem> defaultSchedule() => const [
    RoutineItem(
      id: 'wake_up',
      title: 'Wake Up',
      icon: '\u{2600}\u{FE0F}', // ☀️
      time: '7:00 AM',
      order: 0,
      color: Color(0xFFDDA85C),
    ),
    RoutineItem(
      id: 'brush_teeth',
      title: 'Brush Teeth',
      icon: '\u{1FAA5}', // 🪥
      time: '7:15 AM',
      order: 1,
      color: Color(0xFF8FC1DC),
    ),
    RoutineItem(
      id: 'breakfast',
      title: 'Breakfast',
      icon: '\u{1F963}', // 🥣
      time: '7:30 AM',
      order: 2,
      color: Color(0xFF8FBE8F),
    ),
    RoutineItem(
      id: 'school',
      title: 'School',
      icon: '\u{1F3EB}', // 🏫
      time: '8:30 AM',
      order: 3,
      color: Color(0xFF7FA8D9),
    ),
    RoutineItem(
      id: 'learning',
      title: 'Learning',
      icon: '\u{1F4DA}', // 📚
      time: '10:00 AM',
      order: 4,
      color: Color(0xFFB48FC0),
    ),
    RoutineItem(
      id: 'play',
      title: 'Play',
      icon: '\u{1F3AE}', // 🎮
      time: '12:00 PM',
      order: 5,
      color: Color(0xFFE09B7E),
    ),
    RoutineItem(
      id: 'dinner',
      title: 'Dinner',
      icon: '\u{1F35D}', // 🍝
      time: '6:00 PM',
      order: 6,
      color: Color(0xFF7FB5A8),
    ),
    RoutineItem(
      id: 'sleep',
      title: 'Sleep',
      icon: '\u{1F319}', // 🌙
      time: '8:30 PM',
      order: 7,
      color: Color(0xFF8B92C6),
    ),
  ];
}

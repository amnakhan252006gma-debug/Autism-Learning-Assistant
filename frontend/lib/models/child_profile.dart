import 'package:flutter/material.dart';

/// Simple child profile model using local/mock data.
/// Will be replaced with real backend data later.
class ChildProfile {
  final String name;
  final int age;
  final String avatarAsset; // icon name or asset path
  final Color favoriteColor;
  final List<String> interests;

  const ChildProfile({
    required this.name,
    required this.age,
    required this.avatarAsset,
    required this.favoriteColor,
    this.interests = const [],
  });

  /// Mock profile used as a placeholder before real data is available.
  static const ChildProfile mock = ChildProfile(
    name: 'Alex',
    age: 7,
    avatarAsset: '😊',
    favoriteColor: Color(0xFF8B80F9),
    interests: ['Animals', 'Music', 'Drawing'],
  );

  ChildProfile copyWith({
    String? name,
    int? age,
    String? avatarAsset,
    Color? favoriteColor,
    List<String>? interests,
  }) {
    return ChildProfile(
      name: name ?? this.name,
      age: age ?? this.age,
      avatarAsset: avatarAsset ?? this.avatarAsset,
      favoriteColor: favoriteColor ?? this.favoriteColor,
      interests: interests ?? this.interests,
    );
  }
}

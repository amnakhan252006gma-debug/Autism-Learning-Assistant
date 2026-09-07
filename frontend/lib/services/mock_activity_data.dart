import 'package:flutter/material.dart';

import '../models/activity_question.dart';

/// Local question banks for the learning activities.
///
/// The backend decides the child's personalized difficulty (1, 2, or 3).
/// The frontend then uses the matching question bank so that the actual
/// questions become easier or harder — not just the Level label.
class MockActivityData {
  MockActivityData._();

  // ═══════════════════════════════════════════════════════════════
  // COLORS
  // ═══════════════════════════════════════════════════════════════

  /// Level 1 — Basic color recognition
  static const List<ActivityQuestion> colorsLevel1Questions = [
    ActivityQuestion(
      prompt: 'Which one is RED?',
      choices: [
        ActivityChoice.color('Red', Color(0xFFE53935)),
        ActivityChoice.color('Blue', Color(0xFF1E88E5)),
        ActivityChoice.color('Green', Color(0xFF43A047)),
        ActivityChoice.color('Yellow', Color(0xFFFDD835)),
      ],
      correctIndex: 0,
    ),
    ActivityQuestion(
      prompt: 'Which one is BLUE?',
      choices: [
        ActivityChoice.color('Yellow', Color(0xFFFDD835)),
        ActivityChoice.color('Blue', Color(0xFF1E88E5)),
        ActivityChoice.color('Red', Color(0xFFE53935)),
        ActivityChoice.color('Green', Color(0xFF43A047)),
      ],
      correctIndex: 1,
    ),
    ActivityQuestion(
      prompt: 'Which one is GREEN?',
      choices: [
        ActivityChoice.color('Green', Color(0xFF43A047)),
        ActivityChoice.color('Yellow', Color(0xFFFDD835)),
        ActivityChoice.color('Red', Color(0xFFE53935)),
        ActivityChoice.color('Blue', Color(0xFF1E88E5)),
      ],
      correctIndex: 0,
    ),
    ActivityQuestion(
      prompt: 'Which one is YELLOW?',
      choices: [
        ActivityChoice.color('Red', Color(0xFFE53935)),
        ActivityChoice.color('Green', Color(0xFF43A047)),
        ActivityChoice.color('Yellow', Color(0xFFFDD835)),
        ActivityChoice.color('Blue', Color(0xFF1E88E5)),
      ],
      correctIndex: 2,
    ),
    ActivityQuestion(
      prompt: 'Which one is ORANGE?',
      choices: [
        ActivityChoice.color('Blue', Color(0xFF1E88E5)),
        ActivityChoice.color('Orange', Color(0xFFFB8C00)),
        ActivityChoice.color('Green', Color(0xFF43A047)),
        ActivityChoice.color('Red', Color(0xFFE53935)),
      ],
      correctIndex: 1,
    ),
  ];

  /// Level 2 — More colors and less predictable answer positions
  static const List<ActivityQuestion> colorsLevel2Questions = [
    ActivityQuestion(
      prompt: 'Which one is PURPLE?',
      choices: [
        ActivityChoice.color('Pink', Color(0xFFE91E63)),
        ActivityChoice.color('Purple', Color(0xFF8E24AA)),
        ActivityChoice.color('Orange', Color(0xFFFB8C00)),
        ActivityChoice.color('Blue', Color(0xFF1E88E5)),
      ],
      correctIndex: 1,
    ),
    ActivityQuestion(
      prompt: 'Which one is PINK?',
      choices: [
        ActivityChoice.color('Pink', Color(0xFFE91E63)),
        ActivityChoice.color('Purple', Color(0xFF8E24AA)),
        ActivityChoice.color('Brown', Color(0xFF795548)),
        ActivityChoice.color('Orange', Color(0xFFFB8C00)),
      ],
      correctIndex: 0,
    ),
    ActivityQuestion(
      prompt: 'Which one is ORANGE?',
      choices: [
        ActivityChoice.color('Purple', Color(0xFF8E24AA)),
        ActivityChoice.color('Pink', Color(0xFFE91E63)),
        ActivityChoice.color('Orange', Color(0xFFFB8C00)),
        ActivityChoice.color('Brown', Color(0xFF795548)),
      ],
      correctIndex: 2,
    ),
    ActivityQuestion(
      prompt: 'Which one is BROWN?',
      choices: [
        ActivityChoice.color('Black', Color(0xFF212121)),
        ActivityChoice.color('Brown', Color(0xFF795548)),
        ActivityChoice.color('Gray', Color(0xFF757575)),
        ActivityChoice.color('Purple', Color(0xFF8E24AA)),
      ],
      correctIndex: 1,
    ),
    ActivityQuestion(
      prompt: 'Which one is BLACK?',
      choices: [
        ActivityChoice.color('Gray', Color(0xFF757575)),
        ActivityChoice.color('Brown', Color(0xFF795548)),
        ActivityChoice.color('Black', Color(0xFF212121)),
        ActivityChoice.color('Purple', Color(0xFF8E24AA)),
      ],
      correctIndex: 2,
    ),
  ];

  /// Level 3 — Similar/difficult color discrimination
  static const List<ActivityQuestion> colorsLevel3Questions = [
    ActivityQuestion(
      prompt: 'Which one is LIGHT BLUE?',
      choices: [
        ActivityChoice.color('Blue', Color(0xFF1565C0)),
        ActivityChoice.color('Light Blue', Color(0xFF64B5F6)),
        ActivityChoice.color('Purple', Color(0xFF8E24AA)),
        ActivityChoice.color('Teal', Color(0xFF00897B)),
      ],
      correctIndex: 1,
    ),
    ActivityQuestion(
      prompt: 'Which one is DARK GREEN?',
      choices: [
        ActivityChoice.color('Light Green', Color(0xFF81C784)),
        ActivityChoice.color('Teal', Color(0xFF00897B)),
        ActivityChoice.color('Dark Green', Color(0xFF1B5E20)),
        ActivityChoice.color('Blue', Color(0xFF1565C0)),
      ],
      correctIndex: 2,
    ),
    ActivityQuestion(
      prompt: 'Which one is LIGHT PINK?',
      choices: [
        ActivityChoice.color('Pink', Color(0xFFE91E63)),
        ActivityChoice.color('Red', Color(0xFFE53935)),
        ActivityChoice.color('Light Pink', Color(0xFFF48FB1)),
        ActivityChoice.color('Purple', Color(0xFF8E24AA)),
      ],
      correctIndex: 2,
    ),
    ActivityQuestion(
      prompt: 'Which one is DARK BLUE?',
      choices: [
        ActivityChoice.color('Light Blue', Color(0xFF64B5F6)),
        ActivityChoice.color('Dark Blue', Color(0xFF0D47A1)),
        ActivityChoice.color('Purple', Color(0xFF8E24AA)),
        ActivityChoice.color('Teal', Color(0xFF00897B)),
      ],
      correctIndex: 1,
    ),
    ActivityQuestion(
      prompt: 'Which one is LIGHT GREEN?',
      choices: [
        ActivityChoice.color('Dark Green', Color(0xFF1B5E20)),
        ActivityChoice.color('Teal', Color(0xFF00897B)),
        ActivityChoice.color('Green', Color(0xFF43A047)),
        ActivityChoice.color('Light Green', Color(0xFF81C784)),
      ],
      correctIndex: 3,
    ),
  ];

  // ═══════════════════════════════════════════════════════════════
  // SHAPES
  // ═══════════════════════════════════════════════════════════════

  /// Level 1 — Basic shape recognition
  static const List<ActivityQuestion> shapesLevel1Questions = [
    ActivityQuestion(
      prompt: 'Which one is a CIRCLE?',
      choices: [
        ActivityChoice.shape('Circle', Icons.circle),
        ActivityChoice.shape('Square', Icons.square),
        ActivityChoice.shape('Triangle', Icons.change_history),
      ],
      correctIndex: 0,
    ),
    ActivityQuestion(
      prompt: 'Which one is a SQUARE?',
      choices: [
        ActivityChoice.shape('Star', Icons.star_rounded),
        ActivityChoice.shape('Square', Icons.square),
        ActivityChoice.shape('Heart', Icons.favorite_rounded),
      ],
      correctIndex: 1,
    ),
    ActivityQuestion(
      prompt: 'Which one is a TRIANGLE?',
      choices: [
        ActivityChoice.shape('Heart', Icons.favorite_rounded),
        ActivityChoice.shape('Square', Icons.square),
        ActivityChoice.shape('Triangle', Icons.change_history),
      ],
      correctIndex: 2,
    ),
    ActivityQuestion(
      prompt: 'Which one is a STAR?',
      choices: [
        ActivityChoice.shape('Circle', Icons.circle),
        ActivityChoice.shape('Triangle', Icons.change_history),
        ActivityChoice.shape('Star', Icons.star_rounded),
      ],
      correctIndex: 2,
    ),
    ActivityQuestion(
      prompt: 'Which one is a HEART?',
      choices: [
        ActivityChoice.shape('Heart', Icons.favorite_rounded),
        ActivityChoice.shape('Circle', Icons.circle),
        ActivityChoice.shape('Star', Icons.star_rounded),
      ],
      correctIndex: 0,
    ),
  ];

  /// Level 2 — More shapes and more distractors
  static const List<ActivityQuestion> shapesLevel2Questions = [
    ActivityQuestion(
      prompt: 'Which one is a DIAMOND?',
      choices: [
        ActivityChoice.shape('Circle', Icons.circle),
        ActivityChoice.shape('Diamond', Icons.diamond_rounded),
        ActivityChoice.shape('Star', Icons.star_rounded),
        ActivityChoice.shape('Heart', Icons.favorite_rounded),
      ],
      correctIndex: 1,
    ),
    ActivityQuestion(
      prompt: 'Which one is a HEXAGON?',
      choices: [
        ActivityChoice.shape('Pentagon', Icons.pentagon),
        ActivityChoice.shape('Hexagon', Icons.hexagon_rounded),
        ActivityChoice.shape('Circle', Icons.circle),
        ActivityChoice.shape('Square', Icons.square),
      ],
      correctIndex: 1,
    ),
    ActivityQuestion(
      prompt: 'Which one is a PENTAGON?',
      choices: [
        ActivityChoice.shape('Triangle', Icons.change_history),
        ActivityChoice.shape('Hexagon', Icons.hexagon_rounded),
        ActivityChoice.shape('Pentagon', Icons.pentagon),
        ActivityChoice.shape('Diamond', Icons.diamond_rounded),
      ],
      correctIndex: 2,
    ),
    ActivityQuestion(
      prompt: 'Which one is a DIAMOND?',
      choices: [
        ActivityChoice.shape('Square', Icons.square),
        ActivityChoice.shape('Triangle', Icons.change_history),
        ActivityChoice.shape('Diamond', Icons.diamond_rounded),
        ActivityChoice.shape('Pentagon', Icons.pentagon),
      ],
      correctIndex: 2,
    ),
    ActivityQuestion(
      prompt: 'Which one is a HEXAGON?',
      choices: [
        ActivityChoice.shape('Circle', Icons.circle),
        ActivityChoice.shape('Star', Icons.star_rounded),
        ActivityChoice.shape('Hexagon', Icons.hexagon_rounded),
        ActivityChoice.shape('Heart', Icons.favorite_rounded),
      ],
      correctIndex: 2,
    ),
  ];

  /// Level 3 — More difficult shape discrimination
  static const List<ActivityQuestion> shapesLevel3Questions = [
    ActivityQuestion(
      prompt: 'Which shape has 3 sides?',
      choices: [
        ActivityChoice.shape('Square', Icons.square),
        ActivityChoice.shape('Triangle', Icons.change_history),
        ActivityChoice.shape('Circle', Icons.circle),
        ActivityChoice.shape('Pentagon', Icons.pentagon),
      ],
      correctIndex: 1,
    ),
    ActivityQuestion(
      prompt: 'Which shape has 4 sides?',
      choices: [
        ActivityChoice.shape('Circle', Icons.circle),
        ActivityChoice.shape('Triangle', Icons.change_history),
        ActivityChoice.shape('Square', Icons.square),
        ActivityChoice.shape('Star', Icons.star_rounded),
      ],
      correctIndex: 2,
    ),
    ActivityQuestion(
      prompt: 'Which shape has 6 sides?',
      choices: [
        ActivityChoice.shape('Pentagon', Icons.pentagon),
        ActivityChoice.shape('Hexagon', Icons.hexagon_rounded),
        ActivityChoice.shape('Diamond', Icons.diamond_rounded),
        ActivityChoice.shape('Triangle', Icons.change_history),
      ],
      correctIndex: 1,
    ),
    ActivityQuestion(
      prompt: 'Which shape has 5 sides?',
      choices: [
        ActivityChoice.shape('Hexagon', Icons.hexagon_rounded),
        ActivityChoice.shape('Pentagon', Icons.pentagon),
        ActivityChoice.shape('Square', Icons.square),
        ActivityChoice.shape('Circle', Icons.circle),
      ],
      correctIndex: 1,
    ),
    ActivityQuestion(
      prompt: 'Which shape has NO straight sides?',
      choices: [
        ActivityChoice.shape('Triangle', Icons.change_history),
        ActivityChoice.shape('Square', Icons.square),
        ActivityChoice.shape('Circle', Icons.circle),
        ActivityChoice.shape('Pentagon', Icons.pentagon),
      ],
      correctIndex: 2,
    ),
  ];

  // ═══════════════════════════════════════════════════════════════
  // NUMBERS
  // ═══════════════════════════════════════════════════════════════

  /// Level 1 — Basic number recognition
  static const List<ActivityQuestion> numbersLevel1Questions = [
    ActivityQuestion(
      prompt: 'Which number is 3?',
      choices: [
        ActivityChoice.text('2'),
        ActivityChoice.text('3'),
        ActivityChoice.text('5'),
      ],
      correctIndex: 1,
    ),
    ActivityQuestion(
      prompt: 'Which number is 1?',
      choices: [
        ActivityChoice.text('1'),
        ActivityChoice.text('4'),
        ActivityChoice.text('6'),
      ],
      correctIndex: 0,
    ),
    ActivityQuestion(
      prompt: 'Which number is 7?',
      choices: [
        ActivityChoice.text('5'),
        ActivityChoice.text('2'),
        ActivityChoice.text('7'),
      ],
      correctIndex: 2,
    ),
    ActivityQuestion(
      prompt: 'Which number is 4?',
      choices: [
        ActivityChoice.text('8'),
        ActivityChoice.text('4'),
        ActivityChoice.text('9'),
      ],
      correctIndex: 1,
    ),
    ActivityQuestion(
      prompt: 'Which number is 9?',
      choices: [
        ActivityChoice.text('9'),
        ActivityChoice.text('3'),
        ActivityChoice.text('6'),
      ],
      correctIndex: 0,
    ),
  ];

  /// Level 2 — Number comparison and simple operations
  static const List<ActivityQuestion> numbersLevel2Questions = [
    ActivityQuestion(
      prompt: 'Which number is GREATER?',
      choices: [
        ActivityChoice.text('3'),
        ActivityChoice.text('7'),
        ActivityChoice.text('5'),
        ActivityChoice.text('2'),
      ],
      correctIndex: 1,
    ),
    ActivityQuestion(
      prompt: 'Which number is SMALLER?',
      choices: [
        ActivityChoice.text('8'),
        ActivityChoice.text('6'),
        ActivityChoice.text('2'),
        ActivityChoice.text('9'),
      ],
      correctIndex: 2,
    ),
    ActivityQuestion(
      prompt: 'What comes after 5?',
      choices: [
        ActivityChoice.text('4'),
        ActivityChoice.text('6'),
        ActivityChoice.text('7'),
        ActivityChoice.text('3'),
      ],
      correctIndex: 1,
    ),
    ActivityQuestion(
      prompt: 'What comes before 8?',
      choices: [
        ActivityChoice.text('7'),
        ActivityChoice.text('6'),
        ActivityChoice.text('9'),
        ActivityChoice.text('5'),
      ],
      correctIndex: 0,
    ),
    ActivityQuestion(
      prompt: 'What is 2 + 3?',
      choices: [
        ActivityChoice.text('4'),
        ActivityChoice.text('5'),
        ActivityChoice.text('6'),
        ActivityChoice.text('7'),
      ],
      correctIndex: 1,
    ),
  ];

  /// Level 3 — Sequences and simple arithmetic
  static const List<ActivityQuestion> numbersLevel3Questions = [
    ActivityQuestion(
      prompt: 'What comes next? 2, 4, 6, __',
      choices: [
        ActivityChoice.text('7'),
        ActivityChoice.text('8'),
        ActivityChoice.text('9'),
        ActivityChoice.text('10'),
      ],
      correctIndex: 1,
    ),
    ActivityQuestion(
      prompt: 'What comes next? 5, 10, 15, __',
      choices: [
        ActivityChoice.text('18'),
        ActivityChoice.text('19'),
        ActivityChoice.text('20'),
        ActivityChoice.text('25'),
      ],
      correctIndex: 2,
    ),
    ActivityQuestion(
      prompt: 'What is 7 + 2?',
      choices: [
        ActivityChoice.text('8'),
        ActivityChoice.text('9'),
        ActivityChoice.text('10'),
        ActivityChoice.text('11'),
      ],
      correctIndex: 1,
    ),
    ActivityQuestion(
      prompt: 'What is 10 - 3?',
      choices: [
        ActivityChoice.text('6'),
        ActivityChoice.text('7'),
        ActivityChoice.text('8'),
        ActivityChoice.text('9'),
      ],
      correctIndex: 1,
    ),
    ActivityQuestion(
      prompt: 'Which number is the LARGEST?',
      choices: [
        ActivityChoice.text('12'),
        ActivityChoice.text('18'),
        ActivityChoice.text('15'),
        ActivityChoice.text('9'),
      ],
      correctIndex: 1,
    ),
  ];

  // ═══════════════════════════════════════════════════════════════
  // WORDS
  // ═══════════════════════════════════════════════════════════════

  /// Level 1 — Basic picture-to-word matching
  static const List<ActivityQuestion> wordsLevel1Questions = [
    ActivityQuestion(
      prompt: 'Which word matches the picture?',
      promptAsset: 'assets/images/cat.png',
      choices: [
        ActivityChoice.text('Cat'),
        ActivityChoice.text('Ball'),
        ActivityChoice.text('Sun'),
      ],
      correctIndex: 0,
    ),
    ActivityQuestion(
      prompt: 'Which word matches the picture?',
      promptAsset: 'assets/images/dog.png',
      choices: [
        ActivityChoice.text('Sun'),
        ActivityChoice.text('Dog'),
        ActivityChoice.text('Cat'),
      ],
      correctIndex: 1,
    ),
    ActivityQuestion(
      prompt: 'Which word matches the picture?',
      promptAsset: 'assets/images/red_ball.png',
      choices: [
        ActivityChoice.text('Ball'),
        ActivityChoice.text('Dog'),
        ActivityChoice.text('Apple'),
      ],
      correctIndex: 0,
    ),
    ActivityQuestion(
      prompt: 'Which word matches the picture?',
      promptAsset: 'assets/images/sun.png',
      choices: [
        ActivityChoice.text('Apple'),
        ActivityChoice.text('Ball'),
        ActivityChoice.text('Sun'),
      ],
      correctIndex: 2,
    ),
    ActivityQuestion(
      prompt: 'Which word matches the picture?',
      promptAsset: 'assets/images/apple.png',
      choices: [
        ActivityChoice.text('Apple'),
        ActivityChoice.text('Cat'),
        ActivityChoice.text('Sun'),
      ],
      correctIndex: 0,
    ),
  ];

  /// Level 2 — Picture matching with more choices
  static const List<ActivityQuestion> wordsLevel2Questions = [
    ActivityQuestion(
      prompt: 'Which word matches the picture?',
      promptAsset: 'assets/images/cat.png',
      choices: [
        ActivityChoice.text('Dog'),
        ActivityChoice.text('Apple'),
        ActivityChoice.text('Cat'),
        ActivityChoice.text('Sun'),
      ],
      correctIndex: 2,
    ),
    ActivityQuestion(
      prompt: 'Which word matches the picture?',
      promptAsset: 'assets/images/dog.png',
      choices: [
        ActivityChoice.text('Dog'),
        ActivityChoice.text('Ball'),
        ActivityChoice.text('Cat'),
        ActivityChoice.text('Apple'),
      ],
      correctIndex: 0,
    ),
    ActivityQuestion(
      prompt: 'Which word matches the picture?',
      promptAsset: 'assets/images/red_ball.png',
      choices: [
        ActivityChoice.text('Sun'),
        ActivityChoice.text('Ball'),
        ActivityChoice.text('Dog'),
        ActivityChoice.text('Cat'),
      ],
      correctIndex: 1,
    ),
    ActivityQuestion(
      prompt: 'Which word matches the picture?',
      promptAsset: 'assets/images/sun.png',
      choices: [
        ActivityChoice.text('Cat'),
        ActivityChoice.text('Sun'),
        ActivityChoice.text('Ball'),
        ActivityChoice.text('Dog'),
      ],
      correctIndex: 1,
    ),
    ActivityQuestion(
      prompt: 'Which word matches the picture?',
      promptAsset: 'assets/images/apple.png',
      choices: [
        ActivityChoice.text('Ball'),
        ActivityChoice.text('Sun'),
        ActivityChoice.text('Apple'),
        ActivityChoice.text('Cat'),
      ],
      correctIndex: 2,
    ),
  ];

  /// Level 3 — More challenging picture-word discrimination
  static const List<ActivityQuestion> wordsLevel3Questions = [
    ActivityQuestion(
      prompt: 'Which word names the animal in the picture?',
      promptAsset: 'assets/images/cat.png',
      choices: [
        ActivityChoice.text('Apple'),
        ActivityChoice.text('Cat'),
        ActivityChoice.text('Ball'),
        ActivityChoice.text('Sun'),
      ],
      correctIndex: 1,
    ),
    ActivityQuestion(
      prompt: 'Which word names the animal in the picture?',
      promptAsset: 'assets/images/dog.png',
      choices: [
        ActivityChoice.text('Ball'),
        ActivityChoice.text('Apple'),
        ActivityChoice.text('Sun'),
        ActivityChoice.text('Dog'),
      ],
      correctIndex: 3,
    ),
    ActivityQuestion(
      prompt: 'Which word names the object in the picture?',
      promptAsset: 'assets/images/red_ball.png',
      choices: [
        ActivityChoice.text('Apple'),
        ActivityChoice.text('Dog'),
        ActivityChoice.text('Ball'),
        ActivityChoice.text('Cat'),
      ],
      correctIndex: 2,
    ),
    ActivityQuestion(
      prompt: 'Which word names the object in the picture?',
      promptAsset: 'assets/images/apple.png',
      choices: [
        ActivityChoice.text('Sun'),
        ActivityChoice.text('Cat'),
        ActivityChoice.text('Apple'),
        ActivityChoice.text('Ball'),
      ],
      correctIndex: 2,
    ),
    ActivityQuestion(
      prompt: 'Which word names the object in the picture?',
      promptAsset: 'assets/images/sun.png',
      choices: [
        ActivityChoice.text('Sun'),
        ActivityChoice.text('Apple'),
        ActivityChoice.text('Dog'),
        ActivityChoice.text('Ball'),
      ],
      correctIndex: 0,
    ),
  ];

  // ═══════════════════════════════════════════════════════════════
  // BACKWARD-COMPATIBLE DEFAULT LISTS
  // ═══════════════════════════════════════════════════════════════

  /// Kept so any existing code that uses colorsQuestions still works.
  static const List<ActivityQuestion> colorsQuestions = colorsLevel1Questions;

  /// Kept so any existing code that uses shapesQuestions still works.
  static const List<ActivityQuestion> shapesQuestions = shapesLevel1Questions;

  /// Kept so any existing code that uses numbersQuestions still works.
  static const List<ActivityQuestion> numbersQuestions = numbersLevel1Questions;

  /// Kept so any existing code that uses wordsQuestions still works.
  static const List<ActivityQuestion> wordsQuestions = wordsLevel1Questions;

  // ═══════════════════════════════════════════════════════════════
  // HELPER
  // ═══════════════════════════════════════════════════════════════

  /// Returns the question bank that matches the personalized difficulty.
  ///
  /// 1 = Starter
  /// 2 = Practice
  /// 3 = Challenge
  static List<ActivityQuestion> questionsFor(String category, int difficulty) {
    final level = difficulty.clamp(1, 3);

    switch (category.toLowerCase().trim()) {
      case 'colors':
      case 'color':
        switch (level) {
          case 2:
            return colorsLevel2Questions;
          case 3:
            return colorsLevel3Questions;
          default:
            return colorsLevel1Questions;
        }

      case 'shapes':
      case 'shape':
        switch (level) {
          case 2:
            return shapesLevel2Questions;
          case 3:
            return shapesLevel3Questions;
          default:
            return shapesLevel1Questions;
        }

      case 'numbers':
      case 'number':
        switch (level) {
          case 2:
            return numbersLevel2Questions;
          case 3:
            return numbersLevel3Questions;
          default:
            return numbersLevel1Questions;
        }

      case 'words':
      case 'word':
        switch (level) {
          case 2:
            return wordsLevel2Questions;
          case 3:
            return wordsLevel3Questions;
          default:
            return wordsLevel1Questions;
        }

      default:
        return const [];
    }
  }
}

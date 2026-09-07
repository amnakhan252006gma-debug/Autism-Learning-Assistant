import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:autism_learning_assistant/models/activity_question.dart';
import 'package:autism_learning_assistant/services/mock_activity_data.dart';

void main() {
  group('MockActivityData', () {
    test('has 5 questions per activity', () {
      expect(MockActivityData.colorsQuestions.length, 5);
      expect(MockActivityData.shapesQuestions.length, 5);
      expect(MockActivityData.numbersQuestions.length, 5);
      expect(MockActivityData.wordsQuestions.length, 5);
    });

    test('every question has 3-4 valid choices', () {
      final allQuestions = [
        ...MockActivityData.colorsQuestions,
        ...MockActivityData.shapesQuestions,
        ...MockActivityData.numbersQuestions,
        ...MockActivityData.wordsQuestions,
      ];

      for (final question in allQuestions) {
        expect(
          question.choices.length,
          inInclusiveRange(3, 4),
          reason: '"${question.prompt}" should have 3-4 choices',
        );
        expect(
          question.correctIndex,
          inInclusiveRange(0, question.choices.length - 1),
          reason: '"${question.prompt}" correctIndex out of range',
        );
        expect(question.prompt.isNotEmpty, true);
      }
    });

    test('colors questions ask for the correct colour', () {
      for (final question in MockActivityData.colorsQuestions) {
        expect(
          question.prompt.toUpperCase().contains(
            question.correctChoice.label.toUpperCase(),
          ),
          true,
          reason:
              '"${question.prompt}" should ask for "${question.correctChoice.label}"',
        );
      }
    });

    test('shapes questions ask for the correct shape', () {
      for (final question in MockActivityData.shapesQuestions) {
        expect(
          question.prompt.toUpperCase().contains(
            question.correctChoice.label.toUpperCase(),
          ),
          true,
          reason:
              '"${question.prompt}" should ask for "${question.correctChoice.label}"',
        );
      }
    });

    test('numbers questions ask for the correct number', () {
      for (final question in MockActivityData.numbersQuestions) {
        expect(
          question.prompt.contains(question.correctChoice.label),
          true,
          reason:
              '"${question.prompt}" should ask for "${question.correctChoice.label}"',
        );
      }
    });

    test('words questions carry a prompt picture asset', () {
      for (final question in MockActivityData.wordsQuestions) {
        expect(
          question.promptAsset,
          isNotNull,
          reason: 'Word question needs a picture to match',
        );
        expect(
          question.promptAsset,
          startsWith('assets/images/'),
          reason: 'Word question picture must be a bundled image asset',
        );
      }
    });
  });

  group('ActivityQuestion', () {
    test('correctChoice returns the choice at correctIndex', () {
      const question = ActivityQuestion(
        prompt: 'Which number is 3?',
        choices: [
          ActivityChoice.text('2'),
          ActivityChoice.text('3'),
          ActivityChoice.text('5'),
        ],
        correctIndex: 1,
      );

      expect(question.correctChoice.label, '3');
    });

    test('choice factories set the right visual type', () {
      const colorChoice = ActivityChoice.color('Red', Color(0xFFE53935));
      const shapeChoice = ActivityChoice.shape('Circle', Icons.circle);
      const textChoice = ActivityChoice.text('Cat');

      expect(colorChoice.type, ChoiceVisualType.color);
      expect(shapeChoice.type, ChoiceVisualType.shape);
      expect(textChoice.type, ChoiceVisualType.text);
    });
  });
}

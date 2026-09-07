import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/animated_page.dart';
import 'game_shell.dart';

class StoryTimeGame extends StatefulWidget {
  const StoryTimeGame({super.key, this.difficulty = 1});

  final int difficulty;

  @override
  State<StoryTimeGame> createState() => _StoryTimeGameState();
}

class _StoryTimeGameState extends State<StoryTimeGame> {
  late final List<_StoryPage> _pages;

  int _currentPage = 0;
  int _score = 0;
  int _wrongAttempts = 0;
  int _attemptsThisPage = 0;

  int? _wrongChoiceIndex;
  bool _answeredCorrect = false;
  bool _checking = false;

  GameFeedback? _feedback;
  Timer? _timer;
  int _seconds = 0;

  int get _pageCount {
    switch (widget.difficulty.clamp(1, 3)) {
      case 3:
        return 6;
      case 2:
        return 5;
      default:
        return 4;
    }
  }

  @override
  void initState() {
    super.initState();

    _pages = _createPages();
    _startTimer();
  }

  List<_StoryPage> _createPages() {
    const pages = <_StoryPage>[
      _StoryPage(
        emoji: '☀️',
        sentence: 'The sun is in the ____.',
        choices: ['sky', 'water', 'box'],
        correctChoice: 0,
      ),
      _StoryPage(
        emoji: '🐶',
        sentence: 'The dog likes to ____.',
        choices: ['run', 'fly', 'swim'],
        correctChoice: 0,
      ),
      _StoryPage(
        emoji: '🍎',
        sentence: 'I eat a red ____.',
        choices: ['apple', 'ball', 'shoe'],
        correctChoice: 0,
      ),
      _StoryPage(
        emoji: '🌧️',
        sentence: 'When it rains, I use an ____.',
        choices: ['umbrella', 'apple', 'chair'],
        correctChoice: 0,
      ),
      _StoryPage(
        emoji: '🐱',
        sentence: 'The cat says ____.',
        choices: ['meow', 'woof', 'moo'],
        correctChoice: 0,
      ),
      _StoryPage(
        emoji: '🌙',
        sentence: 'The moon comes out at ____.',
        choices: ['night', 'noon', 'morning'],
        correctChoice: 0,
      ),
    ];

    return pages.take(_pageCount).toList();
  }

  void _startTimer() {
    _timer?.cancel();

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;

      setState(() {
        _seconds++;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _selectChoice(int index) {
    if (_checking || _answeredCorrect) return;

    final page = _pages[_currentPage];

    if (index == page.correctChoice) {
      _checkCorrect();
    } else {
      _checkWrong(index);
    }
  }

  Future<void> _checkCorrect() async {
    _checking = true;

    if (_attemptsThisPage == 0) {
      _score++;
    }

    _attemptsThisPage++;

    setState(() {
      _answeredCorrect = true;
      _wrongChoiceIndex = null;
      _feedback = const GameFeedback(
        message: 'Great choice! The story continues!',
        isCorrect: true,
      );
    });

    await Future<void>.delayed(const Duration(milliseconds: 700));

    if (!mounted) return;

    if (_currentPage >= _pages.length - 1) {
      _showResult();
      return;
    }

    setState(() {
      _currentPage++;
      _attemptsThisPage = 0;
      _answeredCorrect = false;
      _checking = false;
      _wrongChoiceIndex = null;
      _feedback = null;
    });
  }

  Future<void> _checkWrong(int index) async {
    _checking = true;
    _attemptsThisPage++;
    _wrongAttempts++;

    setState(() {
      _wrongChoiceIndex = index;
      _feedback = const GameFeedback(
        message: 'Almost! Try another word.',
        isCorrect: false,
      );
    });

    await Future<void>.delayed(const Duration(milliseconds: 650));

    if (!mounted) return;

    setState(() {
      _wrongChoiceIndex = null;
      _checking = false;
    });
  }

  void _showResult() {
    _timer?.cancel();

    final stars = _score == _pages.length
        ? 3
        : (_score >= _pages.length * .6 ? 2 : 1);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => GameResultScreen(
          gameTitle: 'Story Time',
          color: AppTheme.starGold,
          stars: stars,
          scoreText: '$_score / ${_pages.length}',
          backendActivityName: 'Story Time',
          backendCategory: 'words',
          difficulty: widget.difficulty,
          correctAnswers: _pages.length,
          incorrectAnswers: _wrongAttempts,
          totalAttempts: _pages.length + _wrongAttempts,
          totalQuestions: _pages.length,
          timeTakenSeconds: _seconds.toDouble(),
          extra: _storyRecap(),
          playAgainScreen: StoryTimeGame(difficulty: widget.difficulty),
        ),
      ),
    );
  }

  Widget _storyRecap() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.starGold.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.starGold.withValues(alpha: 0.18)),
      ),
      child: Column(
        children: [
          Icon(Icons.menu_book_rounded, size: 38, color: AppTheme.starGold),
          const SizedBox(height: 8),
          Text(
            'Story completed!',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            'You completed ${_pages.length} story pages',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final page = _pages[_currentPage];

    return Scaffold(
      appBar: AppBar(title: const Text('Story Time')),
      body: AnimatedPage(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                GameInstructionBanner(
                  title: 'Complete the story',
                  subtitle: 'Choose the word that makes sense',
                  color: AppTheme.starGold,
                ),

                const SizedBox(height: 16),

                GameProgressDots(
                  current: _currentPage,
                  total: _pages.length,
                  color: AppTheme.starGold,
                ),

                const SizedBox(height: 22),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.starGold.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(26),
                  ),
                  child: Column(
                    children: [
                      Text(page.emoji, style: const TextStyle(fontSize: 72)),
                      const SizedBox(height: 18),
                      Text(
                        page.sentence,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.w800,
                              height: 1.3,
                            ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                Expanded(
                  child: ListView.separated(
                    itemCount: page.choices.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, index) {
                      final wrong = _wrongChoiceIndex == index;

                      return SizedBox(
                        height: 62,
                        child: GameTapCard(
                          color: AppTheme.starGold,
                          enabled: !_checking && !_answeredCorrect,
                          selected: wrong,
                          onTap: () => _selectChoice(index),
                          child: Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: AppTheme.starGold.withValues(
                                    alpha: 0.10,
                                  ),
                                  borderRadius: BorderRadius.circular(13),
                                ),
                                child: Center(
                                  child: Text(
                                    String.fromCharCode(65 + index),
                                    style: TextStyle(
                                      color: AppTheme.starGold,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  page.choices[index],
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w800),
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 18,
                                color: AppTheme.starGold,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 12),

                GameFeedbackBanner(feedback: _feedback),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StoryPage {
  const _StoryPage({
    required this.emoji,
    required this.sentence,
    required this.choices,
    required this.correctChoice,
  });

  final String emoji;
  final String sentence;
  final List<String> choices;
  final int correctChoice;
}

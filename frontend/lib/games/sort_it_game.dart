import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/animated_page.dart';
import 'game_shell.dart';

class SortItGame extends StatefulWidget {
  const SortItGame({super.key, this.difficulty = 1});

  final int difficulty;

  @override
  State<SortItGame> createState() => _SortItGameState();
}

class _SortItGameState extends State<SortItGame> {
  late final List<_SortRound> _rounds;

  int _currentRound = 0;
  int _score = 0;
  int _wrongAttempts = 0;
  int _attemptsThisRound = 0;

  int? _wrongBinIndex;
  bool _answeredCorrect = false;
  bool _checking = false;

  GameFeedback? _feedback;
  Timer? _timer;
  int _seconds = 0;

  int get _roundCount {
    switch (widget.difficulty.clamp(1, 3)) {
      case 3:
        return 10;
      case 2:
        return 8;
      default:
        return 6;
    }
  }

  @override
  void initState() {
    super.initState();

    _rounds = _createRounds();
    _startTimer();
  }

  List<_SortRound> _createRounds() {
    final baseRounds = <_SortRound>[
      const _SortRound(
        item: '🍎',
        itemLabel: 'Apple',
        bins: ['Red', 'Blue'],
        correctBin: 0,
        colorBins: [Color(0xFFC25E5E), Color(0xFF5E8FBF)],
      ),
      const _SortRound(
        item: '🍌',
        itemLabel: 'Banana',
        bins: ['Yellow', 'Green'],
        correctBin: 0,
        colorBins: [Color(0xFFD9A648), Color(0xFF679A70)],
      ),
      const _SortRound(
        item: '🐶',
        itemLabel: 'Dog',
        bins: ['Animal', 'Not Animal'],
        correctBin: 0,
        colorBins: [Color(0xFF679A70), Color(0xFF9B8BC4)],
      ),
      const _SortRound(
        item: '☀️',
        itemLabel: 'Sun',
        bins: ['Nature', 'Food'],
        correctBin: 0,
        colorBins: [Color(0xFFD9A648), Color(0xFFC4814A)],
      ),
      const _SortRound(
        item: '🍓',
        itemLabel: 'Strawberry',
        bins: ['Fruit', 'Animal'],
        correctBin: 0,
        colorBins: [Color(0xFFC25E5E), Color(0xFF679A70)],
      ),
      const _SortRound(
        item: '🐱',
        itemLabel: 'Cat',
        bins: ['Animal', 'Fruit'],
        correctBin: 0,
        colorBins: [Color(0xFF679A70), Color(0xFFC25E5E)],
      ),
      const _SortRound(
        item: '🌳',
        itemLabel: 'Tree',
        bins: ['Nature', 'Food'],
        correctBin: 0,
        colorBins: [Color(0xFF679A70), Color(0xFFD9A648)],
      ),
      const _SortRound(
        item: '🍊',
        itemLabel: 'Orange',
        bins: ['Fruit', 'Animal'],
        correctBin: 0,
        colorBins: [Color(0xFFC4814A), Color(0xFF679A70)],
      ),
      const _SortRound(
        item: '🐟',
        itemLabel: 'Fish',
        bins: ['Animal', 'Fruit'],
        correctBin: 0,
        colorBins: [Color(0xFF5E8FBF), Color(0xFFC25E5E)],
      ),
      const _SortRound(
        item: '⭐',
        itemLabel: 'Star',
        bins: ['Sky', 'Food'],
        correctBin: 0,
        colorBins: [Color(0xFFD9A648), Color(0xFFC4814A)],
      ),
    ];

    return baseRounds.take(_roundCount).toList();
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

  void _selectBin(int index) {
    if (_checking || _answeredCorrect) return;

    final round = _rounds[_currentRound];

    if (index == round.correctBin) {
      _checkCorrect();
    } else {
      _checkWrong(index);
    }
  }

  Future<void> _checkCorrect() async {
    _checking = true;

    if (_attemptsThisRound == 0) {
      _score++;
    }

    _attemptsThisRound++;

    setState(() {
      _answeredCorrect = true;
      _feedback = const GameFeedback(
        message: 'Great sorting!',
        isCorrect: true,
      );
      _wrongBinIndex = null;
    });

    await Future<void>.delayed(const Duration(milliseconds: 650));

    if (!mounted) return;

    if (_currentRound >= _rounds.length - 1) {
      _showResult();
      return;
    }

    setState(() {
      _currentRound++;
      _attemptsThisRound = 0;
      _answeredCorrect = false;
      _checking = false;
      _wrongBinIndex = null;
      _feedback = null;
    });
  }

  Future<void> _checkWrong(int index) async {
    _checking = true;
    _attemptsThisRound++;
    _wrongAttempts++;

    setState(() {
      _wrongBinIndex = index;
      _feedback = const GameFeedback(
        message: 'Try the other group',
        isCorrect: false,
      );
    });

    await Future<void>.delayed(const Duration(milliseconds: 650));

    if (!mounted) return;

    setState(() {
      _wrongBinIndex = null;
      _checking = false;
    });
  }

  void _showResult() {
    _timer?.cancel();

    final stars = _score == _rounds.length
        ? 3
        : (_score >= _rounds.length * .6 ? 2 : 1);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => GameResultScreen(
          gameTitle: 'Sort It',
          color: AppTheme.learnColor,
          stars: stars,
          scoreText: '$_score / ${_rounds.length}',
          backendActivityName: 'Sort It',
          backendCategory: 'colors',
          difficulty: widget.difficulty,
          correctAnswers: _rounds.length,
          incorrectAnswers: _wrongAttempts,
          totalAttempts: _rounds.length + _wrongAttempts,
          totalQuestions: _rounds.length,
          timeTakenSeconds: _seconds.toDouble(),
          playAgainScreen: SortItGame(difficulty: widget.difficulty),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final round = _rounds[_currentRound];

    return Scaffold(
      appBar: AppBar(title: const Text('Sort It')),
      body: AnimatedPage(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                GameInstructionBanner(
                  title: 'Sort it!',
                  subtitle: 'Put the item in the correct group',
                  color: AppTheme.learnColor,
                ),

                const SizedBox(height: 16),

                GameProgressDots(
                  current: _currentRound,
                  total: _rounds.length,
                  color: AppTheme.learnColor,
                ),

                const SizedBox(height: 20),

                Text(round.item, style: const TextStyle(fontSize: 82)),

                const SizedBox(height: 8),

                Text(
                  round.itemLabel,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),

                const SizedBox(height: 24),

                Expanded(
                  child: Row(
                    children: List.generate(round.bins.length, (index) {
                      final selectedWrong = _wrongBinIndex == index;

                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            right: index == round.bins.length - 1 ? 0 : 10,
                          ),
                          child: GameTapCard(
                            color: round.colorBins[index],
                            enabled: !_checking && !_answeredCorrect,
                            selected: selectedWrong,
                            onTap: () => _selectBin(index),
                            child: Container(
                              height: double.infinity,
                              decoration: BoxDecoration(
                                color: round.colorBins[index].withValues(
                                  alpha: 0.08,
                                ),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.inventory_2_rounded,
                                      size: 48,
                                      color: round.colorBins[index],
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      round.bins[index],
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w800,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
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

class _SortRound {
  const _SortRound({
    required this.item,
    required this.itemLabel,
    required this.bins,
    required this.correctBin,
    required this.colorBins,
  });

  final String item;
  final String itemLabel;
  final List<String> bins;
  final int correctBin;
  final List<Color> colorBins;
}

import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/animated_page.dart';
import 'game_shell.dart';

class MatchPairsGame extends StatefulWidget {
  const MatchPairsGame({super.key, this.difficulty = 1});

  final int difficulty;

  @override
  State<MatchPairsGame> createState() => _MatchPairsGameState();
}

class _MatchPairsGameState extends State<MatchPairsGame> {
  static const List<String> _allPairAssets = [
    'assets/images/cat.png',
    'assets/images/dog.png',
    'assets/images/sun.png',
    'assets/images/apple.png',
  ];

  late List<String> _cards;

  final Set<int> _matchedCards = {};
  final List<int> _faceUpCards = [];

  int _turns = 0;
  int _wrongTurns = 0;
  int _nextId = 0;

  bool _checking = false;
  GameFeedback? _feedback;

  int get _pairCount {
    switch (widget.difficulty.clamp(1, 3)) {
      case 3:
        return 4;
      case 2:
        return 3;
      default:
        return 2;
    }
  }

  @override
  void initState() {
    super.initState();
    _deal();
  }

  void _deal() {
    final selected = _allPairAssets.take(_pairCount).toList();

    _cards = [...selected, ...selected]..shuffle();

    _matchedCards.clear();
    _faceUpCards.clear();
    _turns = 0;
    _wrongTurns = 0;
    _checking = false;
    _feedback = null;
    _nextId++;
  }

  void _tapCard(int index) {
    if (_checking ||
        _matchedCards.contains(index) ||
        _faceUpCards.contains(index) ||
        _faceUpCards.length >= 2) {
      return;
    }

    setState(() {
      _faceUpCards.add(index);
      _feedback = null;
    });

    if (_faceUpCards.length == 2) {
      _checkPair();
    }
  }

  Future<void> _checkPair() async {
    _checking = true;
    _turns++;

    final first = _faceUpCards[0];
    final second = _faceUpCards[1];

    final isMatch = _cards[first] == _cards[second];

    if (!isMatch) {
      _wrongTurns++;
    }

    setState(() {
      _feedback = GameFeedback(
        message: isMatch ? 'Great match!' : 'Try another pair',
        isCorrect: isMatch,
      );
    });

    await Future<void>.delayed(Duration(milliseconds: isMatch ? 550 : 900));

    if (!mounted) return;

    if (isMatch) {
      setState(() {
        _matchedCards.add(first);
        _matchedCards.add(second);
        _faceUpCards.clear();
        _checking = false;
      });

      if (_matchedCards.length == _cards.length) {
        await Future<void>.delayed(const Duration(milliseconds: 500));

        if (mounted) {
          _showResult();
        }
      }
    } else {
      setState(() {
        _faceUpCards.clear();
        _checking = false;
      });
    }
  }

  void _showResult() {
    final stars = _turns <= _pairCount + 2
        ? 3
        : (_turns <= _pairCount * 2 + 2 ? 2 : 1);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => GameResultScreen(
          gameTitle: 'Match Pairs',
          color: AppTheme.primary,
          stars: stars,
          scoreText: '$_pairCount / $_pairCount pairs',
          backendActivityName: 'Match Pairs',
          backendCategory: 'shapes',
          difficulty: widget.difficulty,
          correctAnswers: _pairCount,
          incorrectAnswers: _wrongTurns,
          totalAttempts: _turns,
          totalQuestions: _pairCount,
          playAgainScreen: MatchPairsGame(difficulty: widget.difficulty),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Match Pairs')),
      body: AnimatedPage(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                GameInstructionBanner(
                  title: 'Find the matching pairs',
                  subtitle: 'Tap two pictures to see if they match',
                  color: AppTheme.primary,
                ),
                const SizedBox(height: 18),
                GameProgressDots(
                  current: _matchedCards.length ~/ 2,
                  total: _pairCount,
                  color: AppTheme.primary,
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: GridView.builder(
                    itemCount: _cards.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: _pairCount >= 4 ? 4 : 3,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemBuilder: (context, index) {
                      final isFaceUp =
                          _faceUpCards.contains(index) ||
                          _matchedCards.contains(index);

                      return GameTapCard(
                        color: AppTheme.primary,
                        enabled: !_checking && !_matchedCards.contains(index),
                        selected: _matchedCards.contains(index),
                        onTap: () => _tapCard(index),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 180),
                          child: isFaceUp
                              ? Image.asset(
                                  _cards[index],
                                  key: ValueKey('${_nextId}_$index'),
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) => const Icon(
                                    Icons.image_outlined,
                                    size: 42,
                                  ),
                                )
                              : Icon(
                                  Icons.help_outline_rounded,
                                  key: ValueKey('${_nextId}_${index}_hidden'),
                                  size: 42,
                                  color: AppTheme.primary,
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

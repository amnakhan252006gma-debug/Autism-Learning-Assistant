import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/animated_page.dart';
import 'game_shell.dart';

class SoundMatchGame extends StatefulWidget {
  const SoundMatchGame({super.key, this.difficulty = 1});

  final int difficulty;

  @override
  State<SoundMatchGame> createState() => _SoundMatchGameState();
}

class _SoundMatchGameState extends State<SoundMatchGame> {
  late final List<_SoundRound> _rounds;

  int _currentRound = 0;
  int _score = 0;
  int _wrongAttempts = 0;
  int _attemptsThisRound = 0;

  int? _wrongChoiceIndex;
  bool _answeredCorrect = false;
  bool _checking = false;

  GameFeedback? _feedback;
  Timer? _timer;
  int _seconds = 0;

  int get _roundCount {
    switch (widget.difficulty.clamp(1, 3)) {
      case 3:
        return 8;
      case 2:
        return 6;
      default:
        return 4;
    }
  }

  @override
  void initState() {
    super.initState();

    _rounds = _createRounds();
    _startTimer();
  }

  List<_SoundRound> _createRounds() {
    const rounds = <_SoundRound>[
      _SoundRound(
        sound: '🐶',
        soundName: 'Dog',
        choices: ['Dog', 'Cat', 'Cow'],
        correctChoice: 0,
      ),
      _SoundRound(
        sound: '🐱',
        soundName: 'Cat',
        choices: ['Dog', 'Cat', 'Bird'],
        correctChoice: 1,
      ),
      _SoundRound(
        sound: '🐮',
        soundName: 'Cow',
        choices: ['Cow', 'Dog', 'Cat'],
        correctChoice: 0,
      ),
      _SoundRound(
        sound: '🐦',
        soundName: 'Bird',
        choices: ['Cat', 'Bird', 'Dog'],
        correctChoice: 1,
      ),
      _SoundRound(
        sound: '🚗',
        soundName: 'Car',
        choices: ['Train', 'Car', 'Plane'],
        correctChoice: 1,
      ),
      _SoundRound(
        sound: '🚂',
        soundName: 'Train',
        choices: ['Train', 'Car', 'Bus'],
        correctChoice: 0,
      ),
      _SoundRound(
        sound: '✈️',
        soundName: 'Plane',
        choices: ['Bus', 'Plane', 'Train'],
        correctChoice: 1,
      ),
      _SoundRound(
        sound: '🔔',
        soundName: 'Bell',
        choices: ['Bell', 'Clock', 'Drum'],
        correctChoice: 0,
      ),
    ];

    return rounds.take(_roundCount).toList();
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

  void _playSound() {
    // The game currently uses visual sound cues.
    // This keeps the interaction available without requiring
    // an external audio package.
    setState(() {
      _feedback = GameFeedback(
        message: 'This sound is a ${_rounds[_currentRound].soundName}',
        isCorrect: true,
      );
    });
  }

  void _selectChoice(int index) {
    if (_checking || _answeredCorrect) return;

    final round = _rounds[_currentRound];

    if (index == round.correctChoice) {
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
      _wrongChoiceIndex = null;
      _feedback = const GameFeedback(
        message: 'Great listening!',
        isCorrect: true,
      );
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
      _wrongChoiceIndex = null;
      _feedback = null;
    });
  }

  Future<void> _checkWrong(int index) async {
    _checking = true;
    _attemptsThisRound++;
    _wrongAttempts++;

    setState(() {
      _wrongChoiceIndex = index;
      _feedback = const GameFeedback(
        message: 'Listen carefully and try again',
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

    final stars = _score == _rounds.length
        ? 3
        : (_score >= _rounds.length * .6 ? 2 : 1);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => GameResultScreen(
          gameTitle: 'Sound Match',
          color: AppTheme.routineColor,
          stars: stars,
          scoreText: '$_score / ${_rounds.length}',
          backendActivityName: 'Sound Match',
          backendCategory: 'words',
          difficulty: widget.difficulty,
          correctAnswers: _rounds.length,
          incorrectAnswers: _wrongAttempts,
          totalAttempts: _rounds.length + _wrongAttempts,
          totalQuestions: _rounds.length,
          timeTakenSeconds: _seconds.toDouble(),
          playAgainScreen: SoundMatchGame(difficulty: widget.difficulty),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final round = _rounds[_currentRound];

    return Scaffold(
      appBar: AppBar(title: const Text('Sound Match')),
      body: AnimatedPage(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                GameInstructionBanner(
                  title: 'Match the sound',
                  subtitle: 'Listen and choose the correct picture',
                  color: AppTheme.routineColor,
                ),

                const SizedBox(height: 16),

                GameProgressDots(
                  current: _currentRound,
                  total: _rounds.length,
                  color: AppTheme.routineColor,
                ),

                const SizedBox(height: 20),

                GestureDetector(
                  onTap: _playSound,
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      color: AppTheme.routineColor.withValues(alpha: 0.10),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.routineColor.withValues(alpha: 0.25),
                        width: 2,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(round.sound, style: const TextStyle(fontSize: 58)),
                        const SizedBox(height: 4),
                        Icon(
                          Icons.volume_up_rounded,
                          color: AppTheme.routineColor,
                          size: 28,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  'Tap to listen',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.routineColor,
                  ),
                ),

                const SizedBox(height: 20),

                Expanded(
                  child: GridView.builder(
                    itemCount: round.choices.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 1,
                          mainAxisSpacing: 12,
                          childAspectRatio: 4.2,
                        ),
                    itemBuilder: (_, index) {
                      final wrong = _wrongChoiceIndex == index;

                      return GameTapCard(
                        color: AppTheme.routineColor,
                        enabled: !_checking && !_answeredCorrect,
                        selected: wrong,
                        onTap: () => _selectChoice(index),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: AppTheme.routineColor.withValues(
                                  alpha: 0.10,
                                ),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Icon(
                                Icons.volume_up_rounded,
                                color: AppTheme.routineColor,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                round.choices[index],
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 18,
                              color: AppTheme.routineColor,
                            ),
                          ],
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

class _SoundRound {
  const _SoundRound({
    required this.sound,
    required this.soundName,
    required this.choices,
    required this.correctChoice,
  });

  final String sound;
  final String soundName;
  final List<String> choices;
  final int correctChoice;
}

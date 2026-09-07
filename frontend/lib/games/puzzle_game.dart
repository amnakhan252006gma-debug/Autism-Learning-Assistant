import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/animated_page.dart';
import 'game_shell.dart';

class PuzzleGame extends StatefulWidget {
  const PuzzleGame({super.key, this.difficulty = 1});

  final int difficulty;

  @override
  State<PuzzleGame> createState() => _PuzzleGameState();
}

class _PuzzleGameState extends State<PuzzleGame> {
  static const String _imageAsset = 'assets/images/star.png';

  final List<int> _tray = [];
  final Set<int> _completedPieces = {};

  int _pieceCount = 4;
  int? _selectedPiece;
  int _wrongAttempts = 0;
  int _firstTryPieces = 0;

  bool _checking = false;
  GameFeedback? _feedback;

  int get _gridSize {
    if (_pieceCount >= 9) return 3;
    if (_pieceCount >= 6) return 3;
    return 2;
  }

  @override
  void initState() {
    super.initState();
    _setDifficulty();
    _shuffleTray();
  }

  void _setDifficulty() {
    switch (widget.difficulty.clamp(1, 3)) {
      case 3:
        _pieceCount = 9;
        break;
      case 2:
        _pieceCount = 6;
        break;
      default:
        _pieceCount = 4;
    }
  }

  void _shuffleTray() {
    _tray
      ..clear()
      ..addAll(List<int>.generate(_pieceCount, (index) => index))
      ..shuffle();

    _completedPieces.clear();
    _selectedPiece = null;
    _wrongAttempts = 0;
    _firstTryPieces = 0;
    _checking = false;
    _feedback = null;
  }

  void _tapPiece(int piece) {
    if (_checking || _completedPieces.contains(piece)) {
      return;
    }

    setState(() {
      _selectedPiece = piece;
      _feedback = null;
    });

    _checkPiece(piece);
  }

  Future<void> _checkPiece(int piece) async {
    _checking = true;

    final expectedPiece = _completedPieces.length;

    if (piece == expectedPiece) {
      if (_selectedPiece == piece) {
        _firstTryPieces++;
      }

      setState(() {
        _completedPieces.add(piece);
        _feedback = const GameFeedback(
          message: 'Perfect! Keep going!',
          isCorrect: true,
        );
      });

      await Future<void>.delayed(const Duration(milliseconds: 450));

      if (!mounted) return;

      setState(() {
        _selectedPiece = null;
        _checking = false;
      });

      if (_completedPieces.length == _pieceCount) {
        await Future<void>.delayed(const Duration(milliseconds: 500));

        if (mounted) {
          _showResult();
        }
      }
    } else {
      _wrongAttempts++;

      setState(() {
        _feedback = const GameFeedback(
          message: 'Not this piece. Try again!',
          isCorrect: false,
        );
      });

      await Future<void>.delayed(const Duration(milliseconds: 650));

      if (!mounted) return;

      setState(() {
        _selectedPiece = null;
        _checking = false;
      });
    }
  }

  void _showResult() {
    final stars = _firstTryPieces == _pieceCount
        ? 3
        : (_firstTryPieces >= _pieceCount - 1 ? 2 : 1);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => GameResultScreen(
          gameTitle: 'Puzzle',
          color: AppTheme.gamesColor,
          stars: stars,
          scoreText: '$_firstTryPieces / $_pieceCount pieces',
          backendActivityName: 'Puzzle',
          backendCategory: 'shapes',
          difficulty: widget.difficulty,
          correctAnswers: _pieceCount,
          incorrectAnswers: _wrongAttempts,
          totalAttempts: _pieceCount + _wrongAttempts,
          totalQuestions: _pieceCount,
          playAgainScreen: PuzzleGame(difficulty: widget.difficulty),
        ),
      ),
    );
  }

  Widget _buildPuzzlePiece(int piece) {
    final completed = _completedPieces.contains(piece);
    final selected = _selectedPiece == piece;

    return GameTapCard(
      color: AppTheme.gamesColor,
      enabled: !_checking && !completed,
      selected: selected || completed,
      onTap: () => _tapPiece(piece),
      child: completed
          ? ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                _imageAsset,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.star_rounded, size: 48),
              ),
            )
          : Container(
              decoration: BoxDecoration(
                color: AppTheme.gamesColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  '${piece + 1}',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: AppTheme.gamesColor,
                  ),
                ),
              ),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Puzzle')),
      body: AnimatedPage(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                GameInstructionBanner(
                  title: 'Build the puzzle',
                  subtitle: 'Tap the pieces in the right order',
                  color: AppTheme.gamesColor,
                ),
                const SizedBox(height: 18),
                GameProgressDots(
                  current: _completedPieces.length,
                  total: _pieceCount,
                  color: AppTheme.gamesColor,
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: GridView.builder(
                    itemCount: _tray.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: _gridSize,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemBuilder: (_, index) {
                      return _buildPuzzlePiece(_tray[index]);
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

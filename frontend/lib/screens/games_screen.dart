import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../games/match_pairs_game.dart';
import '../games/puzzle_game.dart';
import '../games/draw_game.dart';
import '../games/sound_match_game.dart';
import '../games/sort_it_game.dart';
import '../games/story_time_game.dart';

/// Games and activity screen with mock game cards.
class GamesScreen extends StatelessWidget {
  const GamesScreen({super.key});

  static const List<_Game> _games = [
    _Game(
      title: 'Match Pairs',
      emoji: '🧩',
      description: 'Find matching pictures',
      color: Color(0xFF7986CB),
    ),
    _Game(
      title: 'Puzzle',
      emoji: '🧠',
      description: 'Put the pieces together',
      color: Color(0xFF4DB6AC),
    ),
    _Game(
      title: 'Draw',
      emoji: '✏️',
      description: 'Create something fun',
      color: Color(0xFFFF8A65),
    ),
    _Game(
      title: 'Sound Match',
      emoji: '🔊',
      description: 'Listen and match sounds',
      color: Color(0xFFBA68C8),
    ),
    _Game(
      title: 'Sort It',
      emoji: '📦',
      description: 'Sort by color or shape',
      color: Color(0xFF4FC3F7),
    ),
    _Game(
      title: 'Story Time',
      emoji: '📖',
      description: 'Read along with me',
      color: Color(0xFFAED581),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Games'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, size: 32),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(AppTheme.spaceLG),
        itemCount: _games.length,
        itemBuilder: (context, index) {
          final game = _games[index];
          return _GameCard(game: game);
        },
      ),
    );
  }
}

class _Game {
  final String title;
  final String emoji;
  final String description;
  final Color color;

  const _Game({
    required this.title,
    required this.emoji,
    required this.description,
    required this.color,
  });
}

class _GameCard extends StatelessWidget {
  final _Game game;

  const _GameCard({required this.game});

  Widget _screen() {
    switch (game.title) {
      case 'Match Pairs':
        return const MatchPairsGame();
      case 'Puzzle':
        return const PuzzleGame();
      case 'Draw':
        return const DrawGame();
      case 'Sound Match':
        return const SoundMatchGame();
      case 'Sort It':
        return const SortItGame();
      case 'Story Time':
        return const StoryTimeGame();
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spaceMD),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => _screen()),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusMD),
            boxShadow: [
              BoxShadow(
                color: AppTheme.cardShadow,
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spaceLG,
              vertical: AppTheme.spaceSM,
            ),
            leading: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: game.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppTheme.radiusSM),
              ),
              alignment: Alignment.center,
              child: Text(game.emoji, style: const TextStyle(fontSize: 32)),
            ),
            title: Text(
              game.title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                game.description,
                style: TextStyle(fontSize: 16, color: AppTheme.textSecondary),
              ),
            ),
            trailing: Icon(
              Icons.play_circle_fill_rounded,
              color: AppTheme.primary,
              size: 36,
            ),
          ),
        ),
      ),
    );
  }
}

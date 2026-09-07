import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:autism_learning_assistant/games/draw_game.dart';
import 'package:autism_learning_assistant/games/match_pairs_game.dart';
import 'package:autism_learning_assistant/games/puzzle_game.dart';
import 'package:autism_learning_assistant/games/sort_it_game.dart';
import 'package:autism_learning_assistant/games/sound_match_game.dart';
import 'package:autism_learning_assistant/games/story_time_game.dart';
import 'package:autism_learning_assistant/screens/games_screen.dart';
import 'package:autism_learning_assistant/theme/app_theme.dart';

/// Widget tests for the six playable games behind the Games section.
///
/// Each game is driven through real taps: instructions render, wrong
/// choices give gentle retry feedback, correct choices advance, the
/// result screen shows the score, and Play Again restarts fresh.
void main() {
  setUpAll(() {
    // Keep widget tests hermetic: never fetch Google Fonts over HTTP.
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Future<void> pumpGame(WidgetTester tester, Widget screen) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.themeData, home: screen),
    );
    await tester.pumpAndSettle();
  }

  group('games screen navigation', () {
    testWidgets('all six cards open their playable game', (tester) async {
      await pumpGame(tester, const GamesScreen());

      const games = <String, String>{
        'Match Pairs': 'Find the matching pairs!',
        'Puzzle': 'Tap the pieces in order',
        'Draw': 'Draw anything you like!',
        'Sound Match': 'Who makes this sound?',
        'Sort It': 'Sort by color!',
        'Story Time': 'Finish the story!',
      };

      for (final entry in games.entries) {
        final card = find.text(entry.key);
        await tester.ensureVisible(card);
        await tester.pumpAndSettle();
        await tester.tap(card);
        await tester.pumpAndSettle();

        // The game opened and shows its instruction banner.
        expect(
          find.textContaining(entry.value),
          findsOneWidget,
          reason: '${entry.key} should open its game screen',
        );

        // The back button returns to the games list. Games show a custom
        // back icon; the last match belongs to the topmost route (the
        // games list below stays in the tree offstage).
        await tester.tap(find.byIcon(Icons.arrow_back_rounded).last);
        await tester.pumpAndSettle();
        expect(card, findsOneWidget);
      }
    });
  });

  group('match pairs', () {
    Finder card(int i) => find.byKey(ValueKey('pair_card_$i'));

    /// Images inside card [i] that are not the sparkles card back.
    Finder faceImages(int i) => find.descendant(
      of: card(i),
      matching: find.byWidgetPredicate(
        (w) =>
            w is Image &&
            w.image is AssetImage &&
            (w.image as AssetImage).assetName != 'assets/images/sparkles.png',
      ),
    );

    String faceAsset(WidgetTester tester, int i) {
      final images = tester.widgetList<Image>(faceImages(i));
      expect(images, isNotEmpty, reason: 'card $i should be face up');
      return (images.first.image as AssetImage).assetName;
    }

    bool isFaceUp(WidgetTester tester, int i) =>
        tester.widgetList<Image>(faceImages(i)).isNotEmpty;

    testWidgets('flipping cards, finding every pair, result and play again', (
      tester,
    ) async {
      await pumpGame(tester, const MatchPairsGame());

      expect(find.text('Pairs found: 0 / 3'), findsOneWidget);
      expect(find.byKey(const ValueKey('pair_card_5')), findsOneWidget);

      // Discover the faces of all six cards, two at a time. Both cards
      // stay visible until the flip-back (or match) timer fires.
      final faces = List<String?>.filled(6, null);
      for (var i = 0; i < 6; i += 2) {
        await tester.tap(card(i));
        await tester.pumpAndSettle();
        faces[i] = faceAsset(tester, i);

        await tester.tap(card(i + 1));
        await tester.pumpAndSettle();
        faces[i + 1] = faceAsset(tester, i + 1);

        // Wait out the flip-back / match delay.
        await tester.pump(const Duration(milliseconds: 1100));
        await tester.pumpAndSettle();
      }

      // Group cards by picture — every picture must have exactly two.
      final pairs = <String, List<int>>{};
      for (var i = 0; i < 6; i++) {
        pairs.putIfAbsent(faces[i]!, () => []).add(i);
      }
      expect(pairs.length, 3, reason: 'deck must contain three pairs');
      expect(pairs.values.every((v) => v.length == 2), isTrue);

      // Play every pair that was not already matched during discovery.
      for (final indices in pairs.values) {
        if (isFaceUp(tester, indices.first)) continue; // already matched
        await tester.tap(card(indices.first));
        await tester.pumpAndSettle();
        await tester.tap(card(indices.last));
        await tester.pump(const Duration(milliseconds: 700));
        await tester.pumpAndSettle();
      }
      expect(find.text('Pairs found: 3 / 3'), findsOneWidget);

      // Finish delay → result screen with score and Play Again.
      await tester.pump(const Duration(milliseconds: 1300));
      await tester.pumpAndSettle();
      expect(find.text('3 / 3 pairs'), findsOneWidget);
      expect(find.text('Play Again'), findsOneWidget);

      // Play Again deals a fresh shuffled deck.
      await tester.tap(find.byKey(const ValueKey('game_play_again')));
      await tester.pumpAndSettle();
      expect(find.text('Pairs found: 0 / 3'), findsOneWidget);
    });

    testWidgets('tapping a face-up card again does nothing', (tester) async {
      await pumpGame(tester, const MatchPairsGame());

      await tester.tap(card(0));
      await tester.pumpAndSettle();
      expect(isFaceUp(tester, 0), isTrue);

      // A second tap on the same card must not break the game.
      await tester.tap(card(0));
      await tester.pumpAndSettle();
      expect(isFaceUp(tester, 0), isTrue);
      expect(find.text('Pairs found: 0 / 3'), findsOneWidget);
    });
  });

  group('puzzle', () {
    Future<void> tapPiece(WidgetTester tester, int piece) async {
      final finder = find.byKey(ValueKey('puzzle_piece_$piece'));
      await tester.ensureVisible(finder);
      await tester.pumpAndSettle();
      await tester.tap(finder);
      await tester.pumpAndSettle();
    }

    testWidgets('wrong piece shakes, pieces assemble, result and play again', (
      tester,
    ) async {
      await pumpGame(tester, const PuzzleGame());

      // Nothing is placed yet.
      expect(find.byKey(const ValueKey('puzzle_slot_0')), findsNothing);

      // Slot 0 waits for piece 0 — tapping piece 1 is wrong.
      await tapPiece(tester, 1);
      expect(find.text('Try the piece for the bright slot!'), findsOneWidget);
      expect(find.byKey(const ValueKey('puzzle_slot_0')), findsNothing);

      // The correct piece snaps into place.
      await tapPiece(tester, 0);
      expect(find.byKey(const ValueKey('puzzle_slot_0')), findsOneWidget);
      expect(find.text('Piece placed!'), findsOneWidget);

      // Finish the remaining pieces in order.
      for (final piece in const [1, 2, 3]) {
        await tapPiece(tester, piece);
      }

      // Finish delay → result screen. Piece 0 needed a retry, so only
      // three of four pieces were placed on the first try.
      await tester.pump(const Duration(milliseconds: 1400));
      await tester.pumpAndSettle();
      expect(find.text('3 / 4 pieces'), findsOneWidget);
      expect(find.text('Play Again'), findsOneWidget);

      // Play Again shuffles a fresh tray and clears the board.
      await tester.tap(find.byKey(const ValueKey('game_play_again')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('puzzle_slot_0')), findsNothing);
      expect(find.byKey(const ValueKey('puzzle_piece_0')), findsOneWidget);
    });
  });

  group('draw', () {
    testWidgets('painting, stamping, result recap and play again', (
      tester,
    ) async {
      await pumpGame(tester, const DrawGame());

      final canvas = find.byKey(const ValueKey('draw_canvas'));
      expect(canvas, findsOneWidget);

      // Crayon mode is on by default: a finger drag paints a stroke.
      final stroke1 = await tester.startGesture(
        tester.getCenter(canvas) + const Offset(-60, -40),
      );
      await stroke1.moveBy(const Offset(40, 20));
      await stroke1.moveBy(const Offset(40, 30));
      await stroke1.up();
      await tester.pumpAndSettle();

      // Clear is only enabled once the page has something on it.
      expect(
        tester
            .widget<TextButton>(find.byKey(const ValueKey('draw_clear')))
            .onPressed,
        isNotNull,
      );

      // Pick a second color and paint another stroke.
      await tester.tap(find.byKey(const ValueKey('draw_color_1')));
      await tester.pumpAndSettle();
      final stroke2 = await tester.startGesture(
        tester.getCenter(canvas) + const Offset(50, 60),
      );
      await stroke2.moveBy(const Offset(-30, 10));
      await stroke2.up();
      await tester.pumpAndSettle();

      // Stamp mode: pick the apple stamp, then tap the canvas.
      await tester.tap(
        find.byKey(
          ValueKey('draw_stamp_${'assets/images/apple.png'.hashCode}'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(canvas);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('stamp_0')), findsOneWidget);

      // Done! → result screen celebrates two colors plus one stamp.
      await tester.tap(find.byKey(const ValueKey('draw_done')));
      await tester.pumpAndSettle();
      expect(find.text('Play Again'), findsOneWidget);
      expect(find.text('Your picture used:'), findsOneWidget);
      expect(find.text('3 things used'), findsOneWidget);

      // Play Again returns to a fresh blank canvas.
      await tester.tap(find.byKey(const ValueKey('game_play_again')));
      await tester.pumpAndSettle();
      expect(find.text('Crayon'), findsOneWidget);
      expect(find.byKey(const ValueKey('stamp_0')), findsNothing);
    });
  });

  group('sound match', () {
    testWidgets('wrong choice retries, correct choice advances', (
      tester,
    ) async {
      await pumpGame(tester, const SoundMatchGame());

      expect(find.text('Meow! Meow!'), findsOneWidget);

      // The dog does not meow — gentle retry feedback, round stays.
      await tester.tap(find.byKey(const ValueKey('sound_choice_0')));
      await tester.pumpAndSettle();
      expect(find.text('Try again! You can do it!'), findsOneWidget);
      expect(find.text('Meow! Meow!'), findsOneWidget);

      // The cat is right — praise, then auto-advance to the next sound.
      await tester.tap(find.byKey(const ValueKey('sound_choice_1')));
      await tester.pumpAndSettle();
      expect(find.text('Great job!'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 1600));
      await tester.pumpAndSettle();
      expect(find.text('Woof! Woof!'), findsOneWidget);
    });

    testWidgets('full game reaches a perfect result and restarts', (
      tester,
    ) async {
      await pumpGame(tester, const SoundMatchGame());

      // Correct choice index per round.
      for (final correct in const [1, 0, 2, 1, 2, 0]) {
        await tester.tap(find.byKey(ValueKey('sound_choice_$correct')));
        await tester.pumpAndSettle();
        await tester.pump(const Duration(milliseconds: 1600));
        await tester.pumpAndSettle();
      }

      expect(find.text('6 / 6'), findsOneWidget);
      expect(find.text('Perfect!'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('game_play_again')));
      await tester.pumpAndSettle();
      expect(find.text('Meow! Meow!'), findsOneWidget);
    });
  });

  group('sort it', () {
    testWidgets('wrong basket retries, correct basket advances', (
      tester,
    ) async {
      await pumpGame(tester, const SortItGame());

      // Round 0 sorts the red apple — the yellow basket is wrong.
      await tester.tap(find.byKey(const ValueKey('sort_bin_1')));
      await tester.pumpAndSettle();
      expect(find.text('Try again! You can do it!'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('sort_bin_0')));
      await tester.pumpAndSettle();
      expect(find.text('Great job!'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 1600));
      await tester.pumpAndSettle();

      // Round 1 sorts the yellow sun.
      expect(find.textContaining('Where does this go?'), findsOneWidget);
    });
  });

  group('sort it full game', () {
    testWidgets('both levels finish, result shows and play again restarts', (
      tester,
    ) async {
      await pumpGame(tester, const SortItGame());

      // Correct basket per round: color level then animal level.
      const bins = [0, 1, 0, 1, 0, 1, 0, 1];
      for (var round = 0; round < bins.length; round++) {
        if (round == 4) {
          // The second level switches to sorting animals.
          expect(find.textContaining('Animals or not animals'), findsOneWidget);
        }
        await tester.tap(find.byKey(ValueKey('sort_bin_${bins[round]}')));
        await tester.pumpAndSettle();
        await tester.pump(const Duration(milliseconds: 1600));
        await tester.pumpAndSettle();
      }

      expect(find.text('8 / 8'), findsOneWidget);
      expect(find.text('Perfect!'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('game_play_again')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Sort by color'), findsOneWidget);
    });
  });

  group('story time', () {
    testWidgets('wrong word retries, correct word fills the blank', (
      tester,
    ) async {
      await pumpGame(tester, const StoryTimeGame());

      expect(find.text('Page 1'), findsOneWidget);
      expect(find.text('?'), findsOneWidget);

      // The dog does not finish "The ___ says meow."
      await tester.tap(find.byKey(const ValueKey('story_choice_1')));
      await tester.pumpAndSettle();
      expect(find.text('Try again! You can do it!'), findsOneWidget);
      expect(find.text('?'), findsOneWidget);

      // The cat does — the blank fills in with the word.
      await tester.tap(find.byKey(const ValueKey('story_choice_0')));
      await tester.pumpAndSettle();
      expect(find.text('?'), findsNothing);
      expect(find.text('Great job!'), findsOneWidget);

      // Auto-advance to the next page with a fresh blank.
      await tester.pump(const Duration(milliseconds: 1800));
      await tester.pumpAndSettle();
      expect(find.text('Page 2'), findsOneWidget);
      expect(find.text('?'), findsOneWidget);
    });

    testWidgets('full story reaches the recap result and restarts', (
      tester,
    ) async {
      await pumpGame(tester, const StoryTimeGame());

      // Correct choice index per story page.
      for (final correct in const [0, 1, 0, 2]) {
        await tester.tap(find.byKey(ValueKey('story_choice_$correct')));
        await tester.pumpAndSettle();
        await tester.pump(const Duration(milliseconds: 1800));
        await tester.pumpAndSettle();
      }

      expect(find.text('4 / 4'), findsOneWidget);
      expect(find.text('Perfect!'), findsOneWidget);
      expect(find.text('Our story'), findsOneWidget);
      expect(find.text('The cat says meow.'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('game_play_again')));
      await tester.pumpAndSettle();
      expect(find.text('Page 1'), findsOneWidget);
    });
  });
}

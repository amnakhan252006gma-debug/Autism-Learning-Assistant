import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/animated_page.dart';
import '../widgets/child_button.dart';
import 'game_shell.dart';

/// Draw — a calm creative canvas.
///
/// The child paints with a finger (crayon mode) and can stamp the
/// existing picture assets onto the page. Colors and stamps pop when
/// selected; the result screen celebrates what was used.
class DrawGame extends StatefulWidget {
  const DrawGame({super.key, this.difficulty = 1});

  /// Difficulty provided by the adaptive learning system.
  ///
  /// Draw currently keeps the same creative experience at every level,
  /// but the difficulty is recorded with the backend result.
  final int difficulty;

  @override
  State<DrawGame> createState() => _DrawGameState();
}

class _DrawGameState extends State<DrawGame> {
  /// Soft palette drawn from the app's muted feature colors.
  static const List<Color> _palette = [
    Color(0xFFC25E5E), // muted red
    Color(0xFFC4814A), // soft amber
    Color(0xFFD9A648), // gentle gold
    Color(0xFF679A70), // sage green
    Color(0xFF5E8FBF), // dusty blue
    Color(0xFF666DC2), // calm indigo
  ];

  /// Stamps the child can place on the canvas.
  static const List<String> _stampAssets = [
    'assets/images/apple.png',
    'assets/images/cat.png',
    'assets/images/dog.png',
    'assets/images/star.png',
    'assets/images/sun.png',
    'assets/images/red_ball.png',
  ];

  static const double _stampSize = 56;

  final List<_Stroke> _strokes = [];
  final List<_Stamp> _stamps = [];
  final Set<Color> _colorsUsed = {};
  final Set<String> _stampsUsed = {};

  Color _selectedColor = _palette.first;

  /// The currently selected stamp, or `null` for crayon mode.
  String? _selectedStamp;

  int _nextId = 0;

  bool get _isBlank => _strokes.isEmpty && _stamps.isEmpty;

  int get _elementsUsed => _colorsUsed.length + _stampsUsed.length;

  @override
  Widget build(BuildContext context) {
    return AnimatedPage(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Draw'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, size: 32),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              GameInstructionBanner(
                title: 'Draw',
                subtitle: 'Draw anything you like! Pick colors and fun stamps.',
                color: AppTheme.communicateColor,
                asset: 'assets/images/happy_face.png',
              ),
              Expanded(child: _buildCanvas()),
              _buildTools(),
            ],
          ),
        ),
      ),
    );
  }

  // ── Canvas ───────────────────────────────────────────────────────

  Widget _buildCanvas() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceLG),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(AppTheme.radiusLG),
              border: Border.all(color: AppTheme.outline),
              boxShadow: AppTheme.shadowCard,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusLG),
              child: GestureDetector(
                key: const ValueKey('draw_canvas'),
                behavior: HitTestBehavior.opaque,
                onPanStart: _selectedStamp == null
                    ? (details) => _startStroke(details.localPosition)
                    : null,
                onPanUpdate: _selectedStamp == null
                    ? (details) => _extendStroke(details.localPosition)
                    : null,
                onTapDown: _selectedStamp != null
                    ? (details) => _placeStamp(
                        details.localPosition,
                        Size(constraints.maxWidth, constraints.maxHeight),
                      )
                    : null,
                child: Stack(
                  children: [
                    CustomPaint(
                      size: Size.infinite,
                      painter: _CanvasPainter(strokes: _strokes),
                    ),
                    for (final stamp in _stamps)
                      Positioned(
                        left: stamp.offset.dx,
                        top: stamp.offset.dy,
                        child: TweenAnimationBuilder<double>(
                          key: ValueKey('stamp_${stamp.id}'),
                          tween: Tween(begin: 0, end: 1),
                          duration: const Duration(milliseconds: 340),
                          curve: Curves.easeOutBack,
                          builder: (context, value, child) => Transform.scale(
                            scale: .5 + value * .5,
                            child: child,
                          ),
                          child: Image.asset(
                            stamp.asset,
                            width: _stampSize,
                            height: _stampSize,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _startStroke(Offset position) {
    setState(() {
      _strokes.add(_Stroke(color: _selectedColor, points: [position]));
      _colorsUsed.add(_selectedColor);
    });
  }

  void _extendStroke(Offset position) {
    if (_strokes.isEmpty) return;

    setState(() {
      _strokes.last.points.add(position);
    });
  }

  void _placeStamp(Offset position, Size canvasSize) {
    final stamp = _selectedStamp!;

    setState(() {
      _stamps.add(
        _Stamp(
          id: _nextId++,
          asset: stamp,
          offset: Offset(
            position.dx.clamp(0, canvasSize.width - _stampSize),
            position.dy.clamp(0, canvasSize.height - _stampSize),
          ),
        ),
      );

      _stampsUsed.add(stamp);
    });
  }

  // ── Tools ────────────────────────────────────────────────────────

  Widget _buildTools() {
    return Container(
      margin: const EdgeInsets.all(AppTheme.spaceMD),
      padding: const EdgeInsets.all(AppTheme.spaceMD),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        border: Border.all(color: AppTheme.outline),
        boxShadow: AppTheme.shadowSoft,
      ),
      child: Column(
        children: [
          _buildStampRow(),
          const SizedBox(height: AppTheme.spaceMD),
          _buildColorRow(),
          const SizedBox(height: AppTheme.spaceMD),
          _buildActionRow(),
        ],
      ),
    );
  }

  Widget _buildStampRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _CrayonChip(
            selected: _selectedStamp == null,
            color: _selectedColor,
            onTap: () {
              setState(() {
                _selectedStamp = null;
              });
            },
          ),
          const SizedBox(width: AppTheme.spaceSM),
          for (final stamp in _stampAssets)
            _StampChip(
              key: ValueKey('draw_stamp_${stamp.hashCode}'),
              asset: stamp,
              selected: _selectedStamp == stamp,
              onTap: () {
                setState(() {
                  _selectedStamp = stamp;
                });
              },
            ),
        ],
      ),
    );
  }

  Widget _buildColorRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        for (int i = 0; i < _palette.length; i++)
          _ColorDot(
            key: ValueKey('draw_color_$i'),
            color: _palette[i],
            selected: _selectedColor == _palette[i],
            onTap: () {
              setState(() {
                _selectedColor = _palette[i];
              });
            },
          ),
      ],
    );
  }

  Widget _buildActionRow() {
    return Row(
      children: [
        Expanded(
          child: TextButton.icon(
            key: const ValueKey('draw_clear'),
            onPressed: _isBlank
                ? null
                : () {
                    setState(() {
                      _strokes.clear();
                      _stamps.clear();
                      _colorsUsed.clear();
                      _stampsUsed.clear();
                    });
                  },
            icon: const Icon(Icons.refresh_rounded, size: 22),
            label: const Text(
              'Clear',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
        ),
        const SizedBox(width: AppTheme.spaceMD),
        Expanded(
          flex: 2,
          child: ChildButton(
            key: const ValueKey('draw_done'),
            label: 'Done!',
            icon: Icons.check_rounded,
            color: AppTheme.communicateColor,
            onTap: _showResult,
          ),
        ),
      ],
    );
  }

  // ── Result ───────────────────────────────────────────────────────

  void _showResult() {
    final stampsUsed = List<String>.from(_stampsUsed);

    final colorsUsed = List<Color>.from(_colorsUsed);

    // Exploring more colors and stamps earns more stars.
    final stars = _elementsUsed >= 5 ? 3 : (_elementsUsed >= 3 ? 2 : 1);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => GameResultScreen(
          gameTitle: 'Draw',
          color: AppTheme.communicateColor,
          stars: stars,
          scoreText: '$_elementsUsed things used',

          // Backend activity information.
          backendActivityName: 'Draw',
          backendCategory: 'colors',

          // Adaptive difficulty selected for this child.
          difficulty: widget.difficulty.clamp(1, 3).toInt(),

          // Draw is a creative activity, so one completed
          // drawing is recorded as one question/attempt.
          correctAnswers: _isBlank ? 0 : 1,
          incorrectAnswers: 0,
          totalAttempts: 1,
          totalQuestions: 1,

          extra: _DrawingRecap(stamps: stampsUsed, colors: colorsUsed),

          // Keep the same adaptive difficulty on replay.
          playAgainScreen: DrawGame(difficulty: widget.difficulty),
        ),
      ),
    );
  }
}

/// Recap card listing the stamps and colors used in the drawing.
class _DrawingRecap extends StatelessWidget {
  const _DrawingRecap({required this.stamps, required this.colors});

  final List<String> stamps;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceLG),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        border: Border.all(color: AppTheme.outline),
        boxShadow: AppTheme.shadowSoft,
      ),
      child: Column(
        children: [
          Text(
            'Your picture used:',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: AppTheme.spaceMD),
          if (stamps.isEmpty && colors.isEmpty)
            Text(
              'A blank page — try again!',
              style: TextStyle(fontSize: 15.5, color: AppTheme.textSecondary),
            )
          else ...[
            if (stamps.isNotEmpty)
              Wrap(
                alignment: WrapAlignment.center,
                spacing: AppTheme.spaceSM,
                runSpacing: AppTheme.spaceSM,
                children: [
                  for (final stamp in stamps)
                    Container(
                      padding: const EdgeInsets.all(AppTheme.spaceSM),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceAlt,
                        borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                      ),
                      child: Image.asset(
                        stamp,
                        width: 40,
                        height: 40,
                        fit: BoxFit.contain,
                      ),
                    ),
                ],
              ),
            if (stamps.isNotEmpty && colors.isNotEmpty)
              const SizedBox(height: AppTheme.spaceMD),
            if (colors.isNotEmpty)
              Wrap(
                alignment: WrapAlignment.center,
                spacing: AppTheme.spaceSM,
                runSpacing: AppTheme.spaceSM,
                children: [
                  for (final color in colors)
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.outline),
                      ),
                    ),
                ],
              ),
          ],
        ],
      ),
    );
  }
}

/// The crayon-mode toggle chip.
class _CrayonChip extends StatelessWidget {
  const _CrayonChip({
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppTheme.animationFast,
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spaceMD,
          vertical: AppTheme.spaceSM,
        ),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.communicateColor.withValues(alpha: .12)
              : AppTheme.surfaceAlt,
          borderRadius: BorderRadius.circular(AppTheme.radiusLG),
          border: Border.all(
            color: selected ? AppTheme.communicateColor : AppTheme.outline,
            width: selected ? 2.5 : 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.edit_rounded,
              size: 20,
              color: selected ? AppTheme.communicateDeep : color,
            ),
            const SizedBox(width: AppTheme.spaceXS),
            Text(
              'Crayon',
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w800,
                color: selected
                    ? AppTheme.communicateDeep
                    : AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A selectable stamp button.
class _StampChip extends StatelessWidget {
  const _StampChip({
    super.key,
    required this.asset,
    required this.selected,
    required this.onTap,
  });

  final String asset;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        scale: selected ? 1.12 : 1,
        duration: AppTheme.animationFast,
        curve: Curves.easeOutBack,
        child: AnimatedContainer(
          duration: AppTheme.animationFast,
          margin: const EdgeInsets.only(right: AppTheme.spaceSM),
          padding: const EdgeInsets.all(AppTheme.spaceXS),
          decoration: BoxDecoration(
            color: selected
                ? AppTheme.communicateColor.withValues(alpha: .10)
                : AppTheme.surface,
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? AppTheme.communicateColor : AppTheme.outline,
              width: selected ? 2.5 : 1.5,
            ),
          ),
          child: Image.asset(asset, width: 40, height: 40, fit: BoxFit.contain),
        ),
      ),
    );
  }
}

/// A selectable paint color.
class _ColorDot extends StatelessWidget {
  const _ColorDot({
    super.key,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        scale: selected ? 1.2 : 1,
        duration: AppTheme.animationFast,
        curve: Curves.easeOutBack,
        child: AnimatedContainer(
          duration: AppTheme.animationFast,
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? AppTheme.textPrimary : AppTheme.outline,
              width: selected ? 3 : 1.5,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: .35),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
        ),
      ),
    );
  }
}

/// One continuous finger stroke.
class _Stroke {
  _Stroke({required this.color, required this.points});

  final Color color;
  final List<Offset> points;
}

/// One stamp placed on the canvas.
class _Stamp {
  _Stamp({required this.id, required this.asset, required this.offset});

  final int id;
  final String asset;
  final Offset offset;
}

/// Paints every stroke as a smooth round dotted line.
class _CanvasPainter extends CustomPainter {
  _CanvasPainter({required this.strokes});

  final List<_Stroke> strokes;

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in strokes) {
      final paint = Paint()
        ..color = stroke.color
        ..strokeWidth = 9
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      if (stroke.points.length == 1) {
        final dot = Paint()..color = stroke.color;

        canvas.drawCircle(stroke.points.first, 4.5, dot);
        continue;
      }

      final path = Path()
        ..moveTo(stroke.points.first.dx, stroke.points.first.dy);

      for (final point in stroke.points.skip(1)) {
        path.lineTo(point.dx, point.dy);
      }

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _CanvasPainter oldDelegate) => true;
}

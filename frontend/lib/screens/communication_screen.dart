import 'package:flutter/material.dart';

import '../models/communication_card.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_page.dart';

/// PECS-inspired communication board for the child.
///
/// Cards are loaded from [CommunicationCard.defaultCards] (local mock data).
/// A future backend integration will replace the data source while keeping
/// the UI layer unchanged.
class CommunicationScreen extends StatefulWidget {
  const CommunicationScreen({super.key});

  @override
  State<CommunicationScreen> createState() => _CommunicationScreenState();
}

class _CommunicationScreenState extends State<CommunicationScreen> {
  /// Cards currently selected by the child (in tap order).
  final List<CommunicationCard> _selected = [];

  /// All available cards – swap for a repository call later.
  late final List<CommunicationCard> _cards = CommunicationCard.defaultCards();

  // ── Actions ────────────────────────────────────────────────────────

  void _toggleCard(CommunicationCard card) {
    setState(() {
      final alreadySelected = _selected.any((c) => c.id == card.id);
      if (alreadySelected) {
        _selected.removeWhere((c) => c.id == card.id);
      } else {
        _selected.add(card);
      }
    });
  }

  void _clearSelection() {
    setState(() => _selected.clear());
  }

  /// Placeholder for text-to-speech.
  ///
  /// When a real TTS plugin (e.g. `flutter_tts`) is added, call
  /// `await flutterTts.speak(phrase)` here.
  void _speak() {
    if (_selected.isEmpty) return;
    final phrase = _selected.map((c) => c.spokenText).join(' ');

    // TODO(Day-4): integrate flutter_tts or platform TTS channel.
    // For now we show a snackbar as confirmation.
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            '\u{1F50A}  $phrase',
            style: const TextStyle(fontSize: 18),
          ),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          ),
        ),
      );

    setState(() => _selected.clear());
  }

  // ── Build ──────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return AnimatedPage(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Communicate'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, size: 32),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Column(
          children: [
            // ── Sentence bar ──────────────────────────────────────────
            _SentenceBar(
              selected: _selected,
              onRemove: (card) =>
                  setState(() => _selected.removeWhere((c) => c.id == card.id)),
            ),

            // ── Card grid ─────────────────────────────────────────────
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spaceLG,
                  vertical: AppTheme.spaceSM,
                ),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: AppTheme.spaceSM,
                  crossAxisSpacing: AppTheme.spaceSM,
                  childAspectRatio: 0.88,
                ),
                itemCount: _cards.length,
                itemBuilder: (context, index) {
                  final card = _cards[index];
                  final isSelected = _selected.any((c) => c.id == card.id);
                  return StaggeredEntrance(
                    index: index,
                    child: _CommCardTile(
                      card: card,
                      selected: isSelected,
                      onTap: () => _toggleCard(card),
                    ),
                  );
                },
              ),
            ),

            // ── Bottom action bar ─────────────────────────────────────
            _ActionBar(
              hasSelection: _selected.isNotEmpty,
              onClear: _clearSelection,
              onSpeak: _speak,
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// Private widgets
// ═══════════════════════════════════════════════════════════════════════

/// Displays the currently selected cards as a "sentence strip".
class _SentenceBar extends StatelessWidget {
  final List<CommunicationCard> selected;
  final ValueChanged<CommunicationCard> onRemove;

  const _SentenceBar({required this.selected, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 90),
      margin: const EdgeInsets.fromLTRB(
        AppTheme.spaceMD,
        AppTheme.spaceSM,
        AppTheme.spaceMD,
        AppTheme.spaceXS,
      ),
      padding: const EdgeInsets.all(AppTheme.spaceMD),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        border: Border.all(color: AppTheme.outline),
        boxShadow: AppTheme.shadowSoft,
      ),
      child: selected.isEmpty
          ? Center(
              child: Text(
                'Tap a card to say something',
                style: TextStyle(fontSize: 18, color: AppTheme.textSecondary),
              ),
            )
          : Wrap(
              spacing: AppTheme.spaceXS,
              runSpacing: AppTheme.spaceXS,
              children: selected
                  .map(
                    (card) => Chip(
                      avatar: Text(
                        card.symbol,
                        style: const TextStyle(fontSize: 20),
                      ),
                      label: Text(
                        card.label,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      backgroundColor: (card.color ?? AppTheme.primaryLight)
                          .withValues(alpha: .25),
                      deleteIcon: const Icon(Icons.close, size: 18),
                      onDeleted: () => onRemove(card),
                    ),
                  )
                  .toList(),
            ),
    );
  }
}

/// Large, accessible card tile with press animation.
class _CommCardTile extends StatefulWidget {
  final CommunicationCard card;
  final bool selected;
  final VoidCallback onTap;

  const _CommCardTile({
    required this.card,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_CommCardTile> createState() => _CommCardTileState();
}

class _CommCardTileState extends State<_CommCardTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final cardColor = widget.card.color ?? AppTheme.primaryLight;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? .93 : (widget.selected ? 1.03 : 1),
        duration: AppTheme.animationFast,
        curve: Curves.easeOutBack,
        child: AnimatedContainer(
          duration: AppTheme.animationNormal,
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: widget.selected ? AppTheme.primary : AppTheme.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusMD),
            border: Border.all(
              color: widget.selected
                  ? AppTheme.primary
                  : cardColor.withValues(alpha: .22),
              width: widget.selected ? 2.5 : 1.5,
            ),
            boxShadow: widget.selected
                ? [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: .20),
                      blurRadius: 16,
                      offset: const Offset(0, 5),
                    ),
                  ]
                : AppTheme.shadowSoft,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedScale(
                scale: widget.selected ? 1.10 : 1,
                duration: AppTheme.animationNormal,
                child: Text(
                  widget.card.symbol,
                  style: const TextStyle(fontSize: 42),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.card.label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: widget.selected ? Colors.white : AppTheme.textPrimary,
                ),
              ),
              if (widget.selected) ...[
                const SizedBox(height: 4),
                const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Bottom bar with Clear and "Say It" buttons.
class _ActionBar extends StatelessWidget {
  final bool hasSelection;
  final VoidCallback onClear;
  final VoidCallback onSpeak;

  const _ActionBar({
    required this.hasSelection,
    required this.onClear,
    required this.onSpeak,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spaceMD),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 58,
              child: ElevatedButton(
                onPressed: hasSelection ? onClear : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.surfaceAlt,
                  foregroundColor: AppTheme.textPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                  ),
                ),
                child: const Text(
                  'Clear',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppTheme.spaceMD),
          Expanded(
            flex: 2,
            child: SizedBox(
              height: 58,
              child: ElevatedButton(
                onPressed: hasSelection ? onSpeak : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.communicateColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.volume_up_rounded, size: 28),
                    SizedBox(width: AppTheme.spaceXS),
                    Text(
                      'Say It',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

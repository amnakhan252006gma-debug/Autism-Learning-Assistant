import 'package:flutter/material.dart';

/// A single communication card in the PECS-style board.
///
/// Uses emoji as the visual symbol for now. Replace [symbol] with an
/// image asset path when real picture cards are provided by the backend.
class CommunicationCard {
  /// Unique identifier – useful for backend sync later.
  final String id;

  /// Display label shown below the symbol.
  final String label;

  /// Emoji or image asset path used as the card visual.
  final String symbol;

  /// Spoken phrase sent to the TTS engine when the card is activated.
  /// Falls back to [label] when null.
  final String? speechPhrase;

  /// Optional accent colour for the card background.
  final Color? color;

  /// Category grouping (e.g. "needs", "feelings", "responses").
  final String category;

  const CommunicationCard({
    required this.id,
    required this.label,
    required this.symbol,
    this.speechPhrase,
    this.color,
    this.category = 'general',
  });

  /// The phrase that should be spoken aloud.
  String get spokenText => speechPhrase ?? label;

  /// Factory that builds the default Day-4 card set.
  /// Kept as mock / local data – the parent dashboard will later push
  /// custom cards through the backend.
  static List<CommunicationCard> defaultCards() => const [
    CommunicationCard(
      id: 'food',
      label: 'Food',
      symbol: '\u{1F354}', // 🍔
      speechPhrase: 'I want food, please.',
      color: Color(0xFFE8C088),
      category: 'needs',
    ),
    CommunicationCard(
      id: 'drink',
      label: 'Drink',
      symbol: '\u{1F964}', // 🥤
      speechPhrase: 'I would like a drink.',
      color: Color(0xFF93C4E3),
      category: 'needs',
    ),
    CommunicationCard(
      id: 'bathroom',
      label: 'Bathroom',
      symbol: '\u{1F6BD}', // 🚽
      speechPhrase: 'I need to go to the bathroom.',
      color: Color(0xFFB4A6D6),
      category: 'needs',
    ),
    CommunicationCard(
      id: 'help',
      label: 'Help',
      symbol: '\u{1F64B}', // 🙋
      speechPhrase: 'I need help, please.',
      color: Color(0xFFE3A6A6),
      category: 'needs',
    ),
    CommunicationCard(
      id: 'yes',
      label: 'Yes',
      symbol: '\u{1F44D}', // 👍
      speechPhrase: 'Yes.',
      color: Color(0xFFA8CBA4),
      category: 'responses',
    ),
    CommunicationCard(
      id: 'no',
      label: 'No',
      symbol: '\u{1F44E}', // 👎
      speechPhrase: 'No.',
      color: Color(0xFFE3A6A6),
      category: 'responses',
    ),
    CommunicationCard(
      id: 'happy',
      label: 'Happy',
      symbol: '\u{1F60A}', // 😊
      speechPhrase: 'I feel happy!',
      color: Color(0xFFE6D693),
      category: 'feelings',
    ),
    CommunicationCard(
      id: 'sad',
      label: 'Sad',
      symbol: '\u{1F622}', // 😢
      speechPhrase: 'I feel sad.',
      color: Color(0xFF9CBCE0),
      category: 'feelings',
    ),
    CommunicationCard(
      id: 'tired',
      label: 'Tired',
      symbol: '\u{1F634}', // 😴
      speechPhrase: 'I feel tired.',
      color: Color(0xFFC5A8CF),
      category: 'feelings',
    ),
    CommunicationCard(
      id: 'more',
      label: 'More',
      symbol: '\u{2795}', // ➕
      speechPhrase: 'I want more, please.',
      color: Color(0xFF8FC0B8),
      category: 'responses',
    ),
    CommunicationCard(
      id: 'stop',
      label: 'Stop',
      symbol: '\u{1F6D1}', // 🛑
      speechPhrase: 'Please stop.',
      color: Color(0xFFD2908C),
      category: 'responses',
    ),
  ];
}

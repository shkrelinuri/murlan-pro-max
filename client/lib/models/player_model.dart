import 'card_model.dart';

class PlayerModel {
  const PlayerModel({
    required this.id,
    required this.name,
    required this.seat,
    required this.score,
    required this.connected,
    required this.hand,
    required this.isCurrentTurn,
  });

  final String id;
  final String name;
  final int seat;
  final int score;
  final bool connected;
  final List<CardModel> hand;
  final bool isCurrentTurn;
}

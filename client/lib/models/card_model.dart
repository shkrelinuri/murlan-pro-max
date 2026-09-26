class CardModel {
  const CardModel({
    required this.id,
    required this.rank,
    required this.suit,
    required this.value,
  });

  final String id;
  final String rank;
  final String suit;
  final int value;

  String get label => '$rank$suit';

  factory CardModel.fromServer(Map<String, dynamic> json) {
    return CardModel(
      id: json['id'] as String,
      rank: json['rank'] as String,
      suit: json['suit'] as String,
      value: (json['value'] as num).toInt(),
    );
  }
}

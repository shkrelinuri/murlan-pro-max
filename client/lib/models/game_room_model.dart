import 'player_model.dart';

class ChatMessage {
  const ChatMessage({
    required this.senderId,
    required this.senderName,
    required this.text,
    this.timestamp,
  });

  final String senderId;
  final String senderName;
  final String text;
  final DateTime? timestamp;
}

class GameRoomModel {
  const GameRoomModel({
    required this.roomId,
    required this.phase,
    required this.targetScore,
    required this.currentLeader,
    required this.turnIndex,
    required this.players,
    required this.stateVersion,
    required this.roundNumber,
    required this.turnTimeLeftSeconds,
    required this.chatMessages,
    required this.chatBlocked,
    required this.followedPlayerIds,
    required this.searchingForPlayers,
  });

  final String roomId;
  final String phase;
  final int targetScore;
  final int? currentLeader;
  final int turnIndex;
  final List<PlayerModel> players;
  final int stateVersion;
  final int roundNumber;
  final int turnTimeLeftSeconds;
  final List<ChatMessage> chatMessages;
  final bool chatBlocked;
  final List<String> followedPlayerIds;
  final bool searchingForPlayers;

  GameRoomModel copyWith({
    String? roomId,
    String? phase,
    int? targetScore,
    int? currentLeader,
    int? turnIndex,
    List<PlayerModel>? players,
    int? stateVersion,
    int? roundNumber,
    int? turnTimeLeftSeconds,
    List<ChatMessage>? chatMessages,
    bool? chatBlocked,
    List<String>? followedPlayerIds,
    bool? searchingForPlayers,
  }) {
    return GameRoomModel(
      roomId: roomId ?? this.roomId,
      phase: phase ?? this.phase,
      targetScore: targetScore ?? this.targetScore,
      currentLeader: currentLeader ?? this.currentLeader,
      turnIndex: turnIndex ?? this.turnIndex,
      players: players ?? this.players,
      stateVersion: stateVersion ?? this.stateVersion,
      roundNumber: roundNumber ?? this.roundNumber,
      turnTimeLeftSeconds: turnTimeLeftSeconds ?? this.turnTimeLeftSeconds,
      chatMessages: chatMessages ?? this.chatMessages,
      chatBlocked: chatBlocked ?? this.chatBlocked,
      followedPlayerIds: followedPlayerIds ?? this.followedPlayerIds,
      searchingForPlayers: searchingForPlayers ?? this.searchingForPlayers,
    );
  }

  factory GameRoomModel.initial() {
    final initialPlayers = [
      const PlayerModel(
        id: 'p1',
        name: 'You',
        seat: 0,
        score: 11,
        connected: true,
        hand: [],
        isCurrentTurn: true,
      ),
      const PlayerModel(
        id: 'p2',
        name: 'Mira',
        seat: 1,
        score: 8,
        connected: true,
        hand: [],
        isCurrentTurn: false,
      ),
      const PlayerModel(
        id: 'p3',
        name: 'Luan',
        seat: 2,
        score: 7,
        connected: true,
        hand: [],
        isCurrentTurn: false,
      ),
      const PlayerModel(
        id: 'p4',
        name: 'Ari',
        seat: 3,
        score: 6,
        connected: false,
        hand: [],
        isCurrentTurn: false,
      ),
    ];

    return GameRoomModel(
      roomId: 'room-demo',
      phase: 'playing',
      targetScore: 21,
      currentLeader: 0,
      turnIndex: 0,
      players: initialPlayers,
      stateVersion: 1,
      roundNumber: 1,
      turnTimeLeftSeconds: 20,
      chatMessages: const [
        ChatMessage(
          senderId: 'system',
          senderName: 'System',
          text: 'Match ready. Tap a card to play, or wait for auto-play when the timer ends.',
          timestamp: null,
        ),
      ],
      chatBlocked: false,
      followedPlayerIds: const [],
      searchingForPlayers: false,
    );
  }
}

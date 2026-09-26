import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/card_model.dart';
import '../models/game_room_model.dart';
import '../models/player_model.dart';

class GameRoomNotifier extends StateNotifier<GameRoomModel> {
  GameRoomNotifier() : super(GameRoomModel.initial());

  void setDemoCards() {
    final demoCards = [
      const CardModel(id: 'c1', rank: '3', suit: '♠', value: 1),
      const CardModel(id: 'c2', rank: '7', suit: '♥', value: 5),
      const CardModel(id: 'c3', rank: '9', suit: '♦', value: 7),
      const CardModel(id: 'c4', rank: 'J', suit: '♣', value: 9),
      const CardModel(id: 'c5', rank: 'Q', suit: '♠', value: 10),
      const CardModel(id: 'c6', rank: 'A', suit: '♥', value: 12),
      const CardModel(id: 'c7', rank: '2', suit: '♦', value: 13),
    ];

    final players = state.players.map((player) {
      if (player.id != 'p1') {
        return player;
      }

      return PlayerModel(
        id: player.id,
        name: player.name,
        seat: player.seat,
        score: player.score,
        connected: player.connected,
        hand: demoCards,
        isCurrentTurn: player.isCurrentTurn,
      );
    }).toList();

    state = state.copyWith(
      players: players,
      stateVersion: state.stateVersion + 1,
      turnTimeLeftSeconds: 20,
    );
  }

  void tickTurnTimer() {
    if (state.turnTimeLeftSeconds <= 1) {
      autoPlayCurrentTurn();
      return;
    }

    state = state.copyWith(turnTimeLeftSeconds: state.turnTimeLeftSeconds - 1);
  }

  void autoPlayCurrentTurn() {
    final currentPlayer = state.players[state.turnIndex];
    if (currentPlayer.hand.isEmpty) {
      advanceTurn();
      return;
    }

    final autoCardId = currentPlayer.hand.first.id;
    playSelectedCards([autoCardId], isAutoPlay: true);
  }

  void advanceTurn() {
    final nextTurn = (state.turnIndex + 1) % state.players.length;
    state = state.copyWith(
      turnIndex: nextTurn,
      turnTimeLeftSeconds: 20,
    );
  }

  void playSelectedCards(List<String> cardIds, {bool isAutoPlay = false}) {
    if (cardIds.isEmpty) {
      return;
    }

    final currentPlayerId = state.players[state.turnIndex].id;
    final updatedPlayers = state.players.map((player) {
      if (player.id == currentPlayerId) {
        final nextHand = player.hand.where((card) => !cardIds.contains(card.id)).toList(growable: false);
        return PlayerModel(
          id: player.id,
          name: player.name,
          seat: player.seat,
          score: player.score + 1,
          connected: player.connected,
          hand: nextHand,
          isCurrentTurn: false,
        );
      }
      return player;
    }).toList();

    state = state.copyWith(
      players: updatedPlayers,
      turnIndex: (state.turnIndex + 1) % state.players.length,
      turnTimeLeftSeconds: 20,
      chatMessages: [
        ...state.chatMessages,
        ChatMessage(
          senderId: currentPlayerId,
          senderName: state.players[state.turnIndex].name,
          text: isAutoPlay ? 'Auto-played a valid card after time expired.' : 'Played ${cardIds.length} card${cardIds.length == 1 ? '' : 's'}.',
          timestamp: DateTime.now(),
        ),
      ],
    );
  }

  void toggleChatBlock() {
    state = state.copyWith(chatBlocked: !state.chatBlocked);
  }

  void sendChatMessage(String message) {
    final text = message.trim();
    if (text.isEmpty || state.chatBlocked) {
      return;
    }

    state = state.copyWith(
      chatMessages: [
        ...state.chatMessages,
        ChatMessage(
          senderId: 'p1',
          senderName: 'You',
          text: text,
          timestamp: DateTime.now(),
        ),
      ],
    );
  }

  void toggleFollowPlayer(String playerId) {
    final follows = [...state.followedPlayerIds];
    if (follows.contains(playerId)) {
      follows.remove(playerId);
    } else {
      follows.add(playerId);
    }

    state = state.copyWith(followedPlayerIds: follows);
  }

  void setSearchingForPlayers(bool value) {
    state = state.copyWith(searchingForPlayers: value);
  }

  void startBotMatch() {
    final botNames = ['Mira', 'Luan', 'Ari'];

    final botCards = <List<CardModel>>[
      [
        const CardModel(id: 'b1', rank: '4', suit: '♠', value: 2),
        const CardModel(id: 'b2', rank: '8', suit: '♥', value: 6),
        const CardModel(id: 'b3', rank: '10', suit: '♣', value: 8),
        const CardModel(id: 'b4', rank: 'K', suit: '♦', value: 11),
      ],
      [
        const CardModel(id: 'b5', rank: '5', suit: '♦', value: 3),
        const CardModel(id: 'b6', rank: 'Q', suit: '♠', value: 10),
        const CardModel(id: 'b7', rank: '7', suit: '♣', value: 5),
      ],
      [
        const CardModel(id: 'b8', rank: '6', suit: '♥', value: 4),
        const CardModel(id: 'b9', rank: 'J', suit: '♦', value: 9),
        const CardModel(id: 'b10', rank: '3', suit: '♣', value: 1),
        const CardModel(id: 'b11', rank: 'A', suit: '♠', value: 12),
      ],
    ];

    final playerList = [
      PlayerModel(
        id: 'p1',
        name: 'You',
        seat: 0,
        score: 11,
        connected: true,
        hand: [
          const CardModel(id: 'c1', rank: '3', suit: '♠', value: 1),
          const CardModel(id: 'c2', rank: '7', suit: '♥', value: 5),
          const CardModel(id: 'c3', rank: '9', suit: '♦', value: 7),
          const CardModel(id: 'c4', rank: 'J', suit: '♣', value: 9),
          const CardModel(id: 'c5', rank: 'Q', suit: '♠', value: 10),
          const CardModel(id: 'c6', rank: 'A', suit: '♥', value: 12),
          const CardModel(id: 'c7', rank: '2', suit: '♦', value: 13),
          const CardModel(id: 'c8', rank: '8', suit: '♣', value: 6),
        ],
        isCurrentTurn: true,
      ),
      ...List.generate(3, (index) {
        return PlayerModel(
          id: 'bot-${index + 1}',
          name: botNames[index],
          seat: index + 1,
          score: 8 - index,
          connected: true,
          hand: botCards[index],
          isCurrentTurn: false,
        );
      }),
    ];

    state = GameRoomModel(
      roomId: 'bot-room',
      phase: 'playing',
      targetScore: 21,
      currentLeader: 0,
      turnIndex: 0,
      players: playerList,
      stateVersion: state.stateVersion + 1,
      roundNumber: 1,
      turnTimeLeftSeconds: 20,
      chatMessages: const [
        ChatMessage(
          senderId: 'system',
          senderName: 'System',
          text: 'Practice match started. You are seated opposite the main rival.',
          timestamp: null,
        ),
      ],
      chatBlocked: false,
      followedPlayerIds: const [],
      searchingForPlayers: false,
    );
  }
}

final gameRoomProvider = StateNotifierProvider<GameRoomNotifier, GameRoomModel>((ref) {
  return GameRoomNotifier();
});

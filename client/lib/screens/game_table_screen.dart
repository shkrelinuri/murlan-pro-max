import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/card_model.dart';
import '../providers/game_room_provider.dart';

class GameTableScreen extends ConsumerStatefulWidget {
  const GameTableScreen({super.key});

  @override
  ConsumerState<GameTableScreen> createState() => _GameTableScreenState();
}

class _GameTableScreenState extends ConsumerState<GameTableScreen> {
  final Set<String> selectedCardIds = <String>{};
  final TextEditingController _chatController = TextEditingController();
  Timer? _turnTimer;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(gameRoomProvider.notifier).setDemoCards());
    _turnTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      ref.read(gameRoomProvider.notifier).tickTurnTimer();
    });
  }

  @override
  void dispose() {
    _turnTimer?.cancel();
    _chatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final room = ref.watch(gameRoomProvider);
    final player = room.players.firstWhere((p) => p.id == 'p1');

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0B2E2D), Color(0xFF0A1F2E)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _topHud(room),
                const SizedBox(height: 12),
                Expanded(
                  child: Stack(
                    children: [
                      _tableCenter(room),
                      ...room.players
                          .where((opponent) => opponent.id != 'p1')
                          .map((opponent) => _seatBadge(opponent, room)),
                    ],
                  ),
                ),
                _playerHand(player.hand),
                const SizedBox(height: 12),
                _chatPanel(room),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _topHud(dynamic room) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Murlan Pro', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
            Text('Round ${room.roundNumber} • Target ${room.targetScore}', style: const TextStyle(color: Colors.white70)),
            Text('Timer: ${room.turnTimeLeftSeconds}s', style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.w700)),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            room.phase.toUpperCase(),
            style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }

  Widget _tableCenter(dynamic room) {
    return Center(
      child: Container(
        width: 240,
        height: 180,
        decoration: BoxDecoration(
          color: Colors.green.shade800.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white30, width: 2),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 18, spreadRadius: 4),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.play_arrow_rounded, size: 42, color: Colors.white),
            const SizedBox(height: 8),
            Text(
              'Current turn: ${room.players[room.turnIndex].name}',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              'Last leader: ${room.currentLeader != null ? room.players[room.currentLeader!].name : 'None'}',
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  Widget _seatBadge(dynamic player, dynamic room) {
    final isFollowing = room.followedPlayerIds.contains(player.id);

    return switch (player.seat) {
      1 => Positioned(
          top: 18,
          left: 0,
          right: 0,
          child: Align(
            alignment: Alignment.topCenter,
            child: _seatChip(player, isFollowing, room),
          ),
        ),
      2 => Positioned(
          left: 18,
          top: 0,
          bottom: 0,
          child: Align(
            alignment: Alignment.centerLeft,
            child: _seatChip(player, isFollowing, room),
          ),
        ),
      3 => Positioned(
          right: 18,
          top: 0,
          bottom: 0,
          child: Align(
            alignment: Alignment.centerRight,
            child: _seatChip(player, isFollowing, room),
          ),
        ),
      _ => Positioned(
          bottom: 18,
          left: 0,
          right: 0,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: _seatChip(player, isFollowing, room),
          ),
        ),
    };
  }

  Widget _seatChip(dynamic player, bool isFollowing, dynamic room) {
    final isCurrentTurn = room.turnIndex == player.seat;
    final timerProgress = room.turnTimeLeftSeconds / 20;

    return Container(
      width: 142,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white30),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 58,
                height: 58,
                child: CircularProgressIndicator(
                  value: isCurrentTurn ? timerProgress : 0,
                  strokeWidth: 4,
                  backgroundColor: Colors.white12,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isCurrentTurn ? Colors.amber : Colors.white24,
                  ),
                ),
              ),
              CircleAvatar(
                radius: 22,
                backgroundColor: player.seat.isEven ? Colors.teal.shade300 : Colors.indigo.shade300,
                child: Text(
                  player.name.substring(0, 1),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            player.name,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
          Text('${player.score} pts', style: const TextStyle(color: Colors.white70, fontSize: 11)),
          const SizedBox(height: 6),
          SizedBox(
            height: 34,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (final card in player.hand.take(4)) _miniCardBack(card.id),
                if (player.hand.length > 4)
                  Text('+${player.hand.length - 4}', style: const TextStyle(color: Colors.white70, fontSize: 11)),
              ],
            ),
          ),
          const SizedBox(height: 6),
          TextButton(
            onPressed: () => ref.read(gameRoomProvider.notifier).toggleFollowPlayer(player.id),
            style: TextButton.styleFrom(
              foregroundColor: isFollowing ? Colors.amber : Colors.white,
            ),
            child: Text(isFollowing ? 'Following' : 'Follow'),
          ),
        ],
      ),
    );
  }

  Widget _miniCardBack(String cardId) {
    return Container(
      key: ValueKey(cardId),
      width: 20,
      height: 30,
      margin: const EdgeInsets.symmetric(horizontal: 1),
      decoration: BoxDecoration(
        color: const Color(0xFFB13B55),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.white70),
      ),
      child: const Icon(Icons.diamond_outlined, size: 10, color: Colors.white70),
    );
  }

  Widget _chatPanel(dynamic room) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Chat', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              Row(
                children: [
                  const Text('Block chat', style: TextStyle(color: Colors.white70)),
                  Switch(
                    value: room.chatBlocked,
                    onChanged: (_) => ref.read(gameRoomProvider.notifier).toggleChatBlock(),
                    activeThumbColor: Colors.amber,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 110,
            child: ListView(
              padding: EdgeInsets.zero,
              children: <Widget>[
                for (final message in room.chatMessages)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      '${message.senderName}: ${message.text}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _chatController,
                  enabled: !room.chatBlocked,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: room.chatBlocked ? 'Chat is blocked' : 'Say something...',
                    hintStyle: const TextStyle(color: Colors.white38),
                    filled: true,
                    fillColor: Colors.black.withValues(alpha: 0.16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: room.chatBlocked
                    ? null
                    : () {
                        ref.read(gameRoomProvider.notifier).sendChatMessage(_chatController.text);
                        _chatController.clear();
                      },
                icon: const Icon(Icons.send_rounded, color: Colors.amber),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _playerHand(List<CardModel> cards) {
    final canPlaySelected = selectedCardIds.isNotEmpty;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: ElevatedButton.icon(
            onPressed: canPlaySelected
                ? () {
                    final selectedCards = cards
                        .where((card) => selectedCardIds.contains(card.id))
                        .toList(growable: false);

                    ref.read(gameRoomProvider.notifier).playSelectedCards(selectedCards.map((card) => card.id).toList());
                    setState(() => selectedCardIds.clear());
                  }
                : null,
            icon: const Icon(Icons.play_arrow_rounded),
            label: Text(canPlaySelected ? 'Play ${selectedCardIds.length} card${selectedCardIds.length == 1 ? '' : 's'}' : 'Select a card'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.black87,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.only(top: 12),
          child: SizedBox(
            height: 170,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: cards.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final card = cards[index];
                final isSelected = selectedCardIds.contains(card.id);

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        selectedCardIds.remove(card.id);
                      } else {
                        selectedCardIds.add(card.id);
                      }
                    });
                  },
                  child: AnimatedScale(
                    scale: isSelected ? 1.08 : 1,
                    duration: const Duration(milliseconds: 150),
                    child: Container(
                      width: 90,
                      height: 130,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected ? Colors.amber : Colors.white,
                          width: isSelected ? 3 : 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: isSelected ? 12 : 8,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              card.rank,
                              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black87),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              card.suit,
                              style: const TextStyle(fontSize: 18, color: Colors.black87),
                            ),
                            const Spacer(),
                            Align(
                              alignment: Alignment.bottomRight,
                              child: Text(
                                card.suit,
                                style: const TextStyle(fontSize: 22, color: Colors.black87),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

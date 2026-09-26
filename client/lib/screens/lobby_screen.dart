import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:murlan_pro/providers/game_socket_provider.dart';

class LobbyScreen extends ConsumerWidget {
  const LobbyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final socketState = ref.watch(gameSocketProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Lobby')),
      body: socketState.when(
        data: (state) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  state.connected ? 'Connected to game server' : 'Connecting...',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () {
                    state.socket.emit('create_room', {'playerName': 'Player'});
                  },
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Create Room'),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text('Socket error: $error')),
      ),
    );
  }
}

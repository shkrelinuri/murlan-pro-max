import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/social_models.dart';
import '../providers/auth_provider.dart';
import '../providers/game_room_provider.dart';
import '../providers/social_provider.dart';
import 'game_table_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool isSearching = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final user = ref.read(authProvider);
      if (user != null) {
        ref.read(socialProvider.notifier).connect(user);
      }
    });
  }

  Future<void> _startMatchFlow() async {
    if (isSearching) return;

    setState(() => isSearching = true);
    ref.read(gameRoomProvider.notifier).setSearchingForPlayers(true);

    await Future<void>.delayed(const Duration(milliseconds: 1400));

    if (!mounted) return;

    setState(() => isSearching = false);
    ref.read(gameRoomProvider.notifier).setSearchingForPlayers(false);

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF11273D),
        title: const Text('No players found', style: TextStyle(color: Colors.white)),
        content: const Text(
          'We could not find 4 connected players at this time. Please try again later, or play a practice match versus 3 bots.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider);
    final social = ref.watch(socialProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF071B2E), Color(0xFF0B2E2D)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: const Text(
                        'MURLAN PRO',
                        style: TextStyle(
                          letterSpacing: 2.2,
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    const SizedBox(height: 26),
                    const Text(
                      'Find a table. Outsmart the room.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'There are no online players available right now, so you can jump into a 4-player match against 3 bots immediately.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70, fontSize: 16, height: 1.5),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Signed in as @${user?.username ?? 'player'}', style: const TextStyle(color: Colors.white70)),
                        TextButton(
                          onPressed: () {
                            ref.read(authProvider.notifier).signOut();
                            Navigator.of(context).pop();
                          },
                          child: const Text('Sign out'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _playerDirectory(social, user),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: isSearching ? null : _startMatchFlow,
                        icon: isSearching
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                                ),
                              )
                            : const Icon(Icons.search_rounded),
                        label: Text(
                          isSearching ? 'Searching for players...' : 'Find a game',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.amber,
                          foregroundColor: Colors.black87,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: isSearching ? null : () {
                          ref.read(gameRoomProvider.notifier).startBotMatch();
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute<void>(builder: (_) => const GameTableScreen()),
                          );
                        },
                        icon: const Icon(Icons.smart_toy_rounded),
                        label: const Text('Play with 3 bots'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white30),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _playerDirectory(SocialState social, UserProfile? user) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Find players', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 17)),
          const SizedBox(height: 10),
          TextField(
            onChanged: ref.read(socialProvider.notifier).search,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search by username',
              hintStyle: const TextStyle(color: Colors.white38),
              prefixIcon: const Icon(Icons.search_rounded, color: Colors.white70),
              filled: true,
              fillColor: Colors.black.withValues(alpha: 0.14),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 8),
          if (social.results.isEmpty)
            const Text('No players match that search.', style: TextStyle(color: Colors.white60))
          else
            ...social.results.map((player) => _playerRow(player, social, user)),
          if (social.sentInvites.isNotEmpty) ...[
            const Divider(color: Colors.white12),
            Text('Invites sent: ${social.sentInvites.length}', style: const TextStyle(color: Colors.amber)),
          ],
        ],
      ),
    );
  }

  Widget _playerRow(UserProfile player, SocialState social, UserProfile? sender) {
    final invitePending = social.sentInvites.any((invite) => invite.to.id == player.id && invite.status == 'pending');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: player.online ? Colors.teal.shade300 : Colors.white24,
            child: Text(player.displayName.substring(0, 1), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(player.displayName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                Text(player.online ? 'Online' : 'Offline', style: TextStyle(color: player.online ? Colors.greenAccent : Colors.white38, fontSize: 12)),
              ],
            ),
          ),
          OutlinedButton.icon(
            onPressed: player.online && !invitePending && sender != null
                ? () => ref.read(socialProvider.notifier).sendInvite(player, sender)
                : null,
            icon: Icon(invitePending ? Icons.check_rounded : Icons.mail_outline_rounded, size: 16),
            label: Text(invitePending ? 'Sent' : 'Invite'),
          ),
        ],
      ),
    );
  }
}

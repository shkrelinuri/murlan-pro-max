import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../models/social_models.dart';

class SocialState {
  const SocialState({
    required this.directory,
    required this.sentInvites,
    required this.receivedInvites,
    this.query = '',
  });

  final List<UserProfile> directory;
  final List<PlayerInvite> sentInvites;
  final List<PlayerInvite> receivedInvites;
  final String query;

  List<UserProfile> get results {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) return directory;
    return directory.where((user) {
      return user.username.contains(normalizedQuery) || user.displayName.toLowerCase().contains(normalizedQuery);
    }).toList(growable: false);
  }

  SocialState copyWith({
    List<UserProfile>? directory,
    List<PlayerInvite>? sentInvites,
    List<PlayerInvite>? receivedInvites,
    String? query,
  }) {
    return SocialState(
      directory: directory ?? this.directory,
      sentInvites: sentInvites ?? this.sentInvites,
      receivedInvites: receivedInvites ?? this.receivedInvites,
      query: query ?? this.query,
    );
  }
}

class SocialNotifier extends StateNotifier<SocialState> {
  io.Socket? _socket;

  SocialNotifier()
      : super(const SocialState(
          directory: [
            UserProfile(id: 'player-mira', username: 'mira', displayName: 'Mira', online: true),
            UserProfile(id: 'player-luan', username: 'luan', displayName: 'Luan', online: true),
            UserProfile(id: 'player-ari', username: 'ari', displayName: 'Ari', online: false),
            UserProfile(id: 'player-niko', username: 'niko', displayName: 'Niko', online: true),
          ],
          sentInvites: [],
          receivedInvites: [],
        ));

  @override
  void dispose() {
    _socket?.dispose();
    _socket = null;
    super.dispose();
  }

  void connect(UserProfile current) {
    if (_socket != null) return;

    final socket = io.io(
      'http://localhost:4000',
      io.OptionBuilder().setTransports(['websocket']).disableAutoConnect().build(),
    );
    _socket = socket;
    socket.on('social:results', (payload) {
      final users = (payload as List<dynamic>).map((entry) {
        final data = Map<String, dynamic>.from(entry as Map);
        return UserProfile(
          id: data['id'] as String,
          username: data['username'] as String,
          displayName: data['displayName'] as String,
          online: data['online'] as bool? ?? false,
        );
      }).toList(growable: false);
      state = state.copyWith(directory: users);
    });
    socket.on('social:invite_received', (payload) {
      final data = Map<String, dynamic>.from(payload as Map);
      final from = Map<String, dynamic>.from(data['from'] as Map);
      final to = Map<String, dynamic>.from(data['to'] as Map);
      final invite = PlayerInvite(
        id: data['id'] as String,
        from: _profileFromData(from),
        to: _profileFromData(to),
        status: data['status'] as String,
      );
      state = state.copyWith(receivedInvites: [...state.receivedInvites, invite]);
    });
    socket.connect();
    socket.onConnect((_) => socket.emit('social:login', {'username': current.username}));
  }

  void search(String query) {
    state = state.copyWith(query: query);
    _socket?.emit('social:search', {'query': query});
  }

  void sendInvite(UserProfile target, UserProfile sender) {
    if (!target.online || state.sentInvites.any((invite) => invite.to.id == target.id && invite.status == 'pending')) {
      return;
    }

    state = state.copyWith(
      sentInvites: [
        ...state.sentInvites,
        PlayerInvite(
          id: 'invite-${target.id}',
          from: sender,
          to: target,
          status: 'pending',
        ),
      ],
    );
    _socket?.emit('social:invite', {'targetUserId': target.id});
  }

  UserProfile _profileFromData(Map<String, dynamic> data) {
    return UserProfile(
      id: data['id'] as String,
      username: data['username'] as String,
      displayName: data['displayName'] as String,
      online: data['online'] as bool? ?? false,
    );
  }
}

final socialProvider = StateNotifierProvider<SocialNotifier, SocialState>((ref) {
  return SocialNotifier();
});
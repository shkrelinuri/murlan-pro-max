class UserProfile {
  const UserProfile({
    required this.id,
    required this.username,
    required this.displayName,
    required this.online,
  });

  final String id;
  final String username;
  final String displayName;
  final bool online;
}

class PlayerInvite {
  const PlayerInvite({
    required this.id,
    required this.from,
    required this.to,
    required this.status,
  });

  final String id;
  final UserProfile from;
  final UserProfile to;
  final String status;
}
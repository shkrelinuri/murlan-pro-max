import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/social_models.dart';

class AuthNotifier extends StateNotifier<UserProfile?> {
  AuthNotifier() : super(null);

  bool signIn(String username, String password) {
    final normalizedUsername = username.trim().toLowerCase();
    if (normalizedUsername.isEmpty || password.trim().length < 4) {
      return false;
    }

    state = UserProfile(
      id: 'user-$normalizedUsername',
      username: normalizedUsername,
      displayName: normalizedUsername[0].toUpperCase() + normalizedUsername.substring(1),
      online: true,
    );
    return true;
  }

  void signOut() => state = null;
}

final authProvider = StateNotifierProvider<AuthNotifier, UserProfile?>((ref) {
  return AuthNotifier();
});
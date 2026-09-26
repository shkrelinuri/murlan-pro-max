export type SocialUser = {
  id: string;
  username: string;
  displayName: string;
  socketId: string;
  online: boolean;
};

export type SocialInvite = {
  id: string;
  from: SocialUser;
  to: SocialUser;
  status: 'pending' | 'accepted' | 'declined';
};

export class SocialManager {
  private readonly users = new Map<string, SocialUser>();
  private readonly invites = new Map<string, SocialInvite>();

  register(socketId: string, username: string): SocialUser {
    const normalizedUsername = username.trim().toLowerCase();
    if (!normalizedUsername) throw new Error('Username is required');

    const user: SocialUser = {
      id: `user-${normalizedUsername}`,
      username: normalizedUsername,
      displayName: normalizedUsername[0].toUpperCase() + normalizedUsername.slice(1),
      socketId,
      online: true
    };
    this.users.set(user.id, user);
    return user;
  }

  disconnect(socketId: string): void {
    const user = [...this.users.values()].find((entry) => entry.socketId === socketId);
    if (user) user.online = false;
  }

  search(query: string, requesterId: string): SocialUser[] {
    const normalizedQuery = query.trim().toLowerCase();
    return [...this.users.values()].filter((user) => {
      return user.id !== requesterId &&
        (normalizedQuery.length === 0 || user.username.includes(normalizedQuery) || user.displayName.toLowerCase().includes(normalizedQuery));
    });
  }

  invite(fromId: string, toId: string): SocialInvite {
    const from = this.users.get(fromId);
    const to = this.users.get(toId);
    if (!from || !to) throw new Error('Player not found');
    if (!to.online) throw new Error('Player is offline');

    const invite: SocialInvite = {
      id: `invite-${from.id}-${to.id}`,
      from,
      to,
      status: 'pending'
    };
    this.invites.set(invite.id, invite);
    return invite;
  }

  getById(userId: string): SocialUser | undefined {
    return this.users.get(userId);
  }
}
import { describe, expect, it } from 'vitest';
import { RoomManager } from './room-manager.js';

describe('Room manager', () => {
  it('creates a room and allows a second player to join', () => {
    const manager = new RoomManager();
    const room = manager.createRoom('player-1', 'Alice');
    const joined = manager.joinRoom(room.id, 'player-2', 'Bob');

    expect(room.id).toBeDefined();
    expect(joined.players).toHaveLength(2);
    expect(joined.players[1].seat).toBe(1);
  });

  it('starts a match and deals cards to each player', () => {
    const manager = new RoomManager();
    const room = manager.createRoom('player-1', 'Alice');
    manager.joinRoom(room.id, 'player-2', 'Bob');
    manager.joinRoom(room.id, 'player-3', 'Cara');
    manager.joinRoom(room.id, 'player-4', 'Dani');
    const started = manager.startMatch(room.id);

    expect(started.phase).toBe('playing');
    expect(started.players.every((player) => player.hand.length === 7)).toBe(true);
    expect(started.players.some((player) => player.hand.some((card) => card.id === '3-Spades'))).toBe(true);
    expect(started.openingRequired).toBe(true);
  });

  it('blocks illegal turns and validates play order', () => {
    const manager = new RoomManager();
    const room = manager.createRoom('player-1', 'Alice');
    manager.joinRoom(room.id, 'player-2', 'Bob');
    manager.joinRoom(room.id, 'player-3', 'Cara');
    manager.joinRoom(room.id, 'player-4', 'Dani');
    manager.startMatch(room.id);

    const currentPlayerId = room.players[room.turnIndex].id;
    const nonCurrentPlayer = room.players.find((player) => player.id !== currentPlayerId);
    expect(nonCurrentPlayer).toBeDefined();
    expect(() => manager.playCards(room.id, nonCurrentPlayer!.id, nonCurrentPlayer!.hand.slice(0, 1))).toThrow('It is not this player\'s turn');
    expect(() => manager.passTurn(room.id, currentPlayerId)).toThrow('A player must lead the trick first');
  });

  it('awards round finish points and advances the target score', () => {
    const manager = new RoomManager();
    const room = manager.createRoom('player-1', 'Alice');
    manager.joinRoom(room.id, 'player-2', 'Bob');
    manager.joinRoom(room.id, 'player-3', 'Cara');
    manager.joinRoom(room.id, 'player-4', 'Dani');
    manager.startMatch(room.id);

    expect(() => manager.resolveRound(room.id, ['player-1', 'player-2', 'player-3', 'player-4'])).toThrow('Round is not complete');
    room.phase = 'round-over';

    const next = manager.resolveRound(room.id, ['player-1', 'player-2', 'player-3', 'player-4']);
    const p1 = next.players.find((player) => player.id === 'player-1');
    const p2 = next.players.find((player) => player.id === 'player-2');

    expect(p1?.score).toBe(3);
    expect(p2?.score).toBe(2);
    expect(next.targetScore).toBe(31);
  });
});

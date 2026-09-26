import { canBeat, type Card, generateDeck, validateMove } from './rules.js';

export type PlayerSeat = 0 | 1 | 2 | 3;

export type Player = {
  id: string;
  name: string;
  seat: PlayerSeat;
  connected: boolean;
  ready: boolean;
  hand: Card[];
  score: number;
};

export type GamePhase = 'lobby' | 'playing' | 'round-over' | 'finished';

export type RoomState = {
  id: string;
  phase: GamePhase;
  players: Player[];
  turnIndex: number;
  currentLeader: number | null;
  targetScore: number;
  roundNumber: number;
  deck: Card[];
  stateVersion: number;
  currentHand: Card[] | null;
  passedPlayerIds: string[];
  finishOrderIds: string[];
  openingRequired: boolean;
};

const TARGETS = [21, 31, 41, 51];

export class RoomManager {
  private rooms = new Map<string, RoomState>();

  createRoom(hostId: string, hostName: string): RoomState {
    const room: RoomState = {
      id: this.generateRoomId(),
      phase: 'lobby',
      players: [this.createPlayer(hostId, hostName, 0)],
      turnIndex: 0,
      currentLeader: null,
      targetScore: 21,
      roundNumber: 1,
      deck: generateDeck(),
      stateVersion: 1,
      currentHand: null,
      passedPlayerIds: [],
      finishOrderIds: [],
      openingRequired: true
    };

    this.rooms.set(room.id, room);
    return room;
  }

  joinRoom(roomId: string, playerId: string, name: string): RoomState {
    const room = this.getRequiredRoom(roomId);
    if (room.players.length >= 4) throw new Error('Room is full');

    const occupiedSeats = room.players.map((player) => player.seat);
    const seat = ([0, 1, 2, 3] as PlayerSeat[]).find((candidate) => !occupiedSeats.includes(candidate)) ?? 0;
    room.players.push(this.createPlayer(playerId, name, seat));
    room.stateVersion += 1;
    return room;
  }

  getRoom(roomId: string): RoomState | undefined {
    return this.rooms.get(roomId);
  }

  startMatch(roomId: string): RoomState {
    const room = this.getRequiredRoom(roomId);
    if (room.players.length < 2) throw new Error('At least 2 players are required');

    const shuffled = this.shuffle(generateDeck());
    room.deck = shuffled;
    for (const player of room.players) {
      player.hand = shuffled.splice(0, 7);
      player.ready = true;
    }

    const dealtOpeningCard = room.players.some((player) => player.hand.some((card) => card.id === '3-Spades'));
    if (!dealtOpeningCard) {
      const remainderIndex = shuffled.findIndex((card) => card.id === '3-Spades');
      const recipientIndex = Math.floor(Math.random() * room.players.length);
      const replacement = room.players[recipientIndex].hand[0];
      room.players[recipientIndex].hand[0] = shuffled[remainderIndex];
      shuffled[remainderIndex] = replacement;
    }

    const openingPlayerIndex = room.players.findIndex((player) => player.hand.some((card) => card.id === '3-Spades'));
    if (openingPlayerIndex < 0) throw new Error('The opening 3 of Spades was not dealt');

    room.phase = 'playing';
    room.currentLeader = null;
    room.turnIndex = openingPlayerIndex;
    room.currentHand = null;
    room.passedPlayerIds = [];
    room.finishOrderIds = [];
    room.openingRequired = true;
    room.stateVersion += 1;
    return room;
  }

  handleReconnect(roomId: string, playerId: string): RoomState {
    const room = this.getRequiredRoom(roomId);
    const player = this.getRequiredPlayer(room, playerId);
    player.connected = true;
    room.stateVersion += 1;
    return room;
  }

  handleDisconnect(roomId: string, playerId: string): RoomState {
    const room = this.getRequiredRoom(roomId);
    const player = this.getRequiredPlayer(room, playerId);
    player.connected = false;
    room.stateVersion += 1;
    return room;
  }

  playCards(roomId: string, playerId: string, cards: Card[]): RoomState {
    const room = this.getRequiredRoom(roomId);
    const playerIndex = room.players.findIndex((player) => player.id === playerId);
    if (playerIndex < 0) throw new Error('Player not found');
    if (room.phase !== 'playing') throw new Error('Room is not accepting plays');
    if (playerIndex !== room.turnIndex) throw new Error('It is not this player\'s turn');

    const player = room.players[playerIndex];
    if (!validateMove(cards) || !cards.every((card) => player.hand.some((owned) => owned.id === card.id))) {
      throw new Error('Illegal move');
    }
    if (room.openingRequired && !cards.some((card) => card.id === '3-Spades')) {
      throw new Error('The opening play must include the 3 of Spades');
    }
    if (!canBeat(cards, room.currentHand)) throw new Error('The play does not beat the current hand');

    player.hand = player.hand.filter((owned) => !cards.some((selected) => selected.id === owned.id));
    room.currentLeader = playerIndex;
    room.currentHand = [...cards];
    room.passedPlayerIds = [];
    room.openingRequired = false;
    if (player.hand.length === 0) room.finishOrderIds.push(player.id);
    if (room.finishOrderIds.length === room.players.length) room.phase = 'round-over';
    room.turnIndex = this.nextActiveIndex(room, playerIndex);
    room.stateVersion += 1;
    return room;
  }

  passTurn(roomId: string, playerId: string): RoomState {
    const room = this.getRequiredRoom(roomId);
    const playerIndex = room.players.findIndex((player) => player.id === playerId);
    if (playerIndex < 0) throw new Error('Player not found');
    if (room.phase !== 'playing') throw new Error('Room is not accepting passes');
    if (playerIndex !== room.turnIndex) throw new Error('It is not this player\'s turn');
    if (!room.currentHand || room.currentLeader === null) throw new Error('A player must lead the trick first');

    room.passedPlayerIds = [...new Set([...room.passedPlayerIds, playerId])];
    const leaderId = room.players[room.currentLeader].id;
    const otherActivePlayers = room.players.filter((player) => {
      return player.id !== leaderId && !room.finishOrderIds.includes(player.id);
    });

    if (otherActivePlayers.every((player) => room.passedPlayerIds.includes(player.id))) {
      room.currentHand = null;
      room.passedPlayerIds = [];
      room.turnIndex = room.currentLeader;
    } else {
      room.turnIndex = this.nextActiveIndex(room, playerIndex);
    }
    room.stateVersion += 1;
    return room;
  }

  resolveRound(roomId: string, finishOrderIds: string[]): RoomState {
    const room = this.getRequiredRoom(roomId);
    if (room.phase !== 'round-over') throw new Error('Round is not complete');
    if (finishOrderIds.length !== room.players.length) throw new Error('Finish order must include every player');
    if (new Set(finishOrderIds).size !== finishOrderIds.length) throw new Error('Finish order contains duplicates');
    if (finishOrderIds.some((playerId) => !room.players.some((player) => player.id === playerId))) {
      throw new Error('Finish order contains an unknown player');
    }

    const scoreByPlace = [3, 2, 1, 0];
    for (const [index, playerId] of finishOrderIds.entries()) {
      this.getRequiredPlayer(room, playerId).score += scoreByPlace[index];
    }

    room.currentLeader = room.players.findIndex((player) => player.id === finishOrderIds[finishOrderIds.length - 1]);
    room.turnIndex = room.currentLeader;
    room.targetScore = this.nextTarget(room.targetScore);
    room.phase = 'playing';
    room.roundNumber += 1;
    room.currentHand = null;
    room.passedPlayerIds = [];
    room.finishOrderIds = [];
    room.openingRequired = false;
    room.stateVersion += 1;
    return room;
  }

  private createPlayer(id: string, name: string, seat: PlayerSeat): Player {
    return { id, name, seat, connected: true, ready: false, hand: [], score: 0 };
  }

  private getRequiredRoom(roomId: string): RoomState {
    const room = this.rooms.get(roomId);
    if (!room) throw new Error('Room not found');
    return room;
  }

  private getRequiredPlayer(room: RoomState, playerId: string): Player {
    const player = room.players.find((entry) => entry.id === playerId);
    if (!player) throw new Error(`Player not found: ${playerId}`);
    return player;
  }

  private nextActiveIndex(room: RoomState, fromIndex: number): number {
    for (let offset = 1; offset <= room.players.length; offset += 1) {
      const candidate = (fromIndex + offset) % room.players.length;
      if (!room.finishOrderIds.includes(room.players[candidate].id)) return candidate;
    }
    return fromIndex;
  }

  private generateRoomId(): string {
    return `room-${Math.random().toString(36).slice(2, 8)}`;
  }

  private shuffle<T>(items: T[]): T[] {
    const copy = [...items];
    for (let index = copy.length - 1; index > 0; index -= 1) {
      const swapIndex = Math.floor(Math.random() * (index + 1));
      [copy[index], copy[swapIndex]] = [copy[swapIndex], copy[index]];
    }
    return copy;
  }

  private nextTarget(current: number): number {
    return TARGETS.find((target) => target > current) ?? 51;
  }
}

export const SOCKET_EVENTS = {
  SERVER_CONNECTED: 'server:connected',
  ROOM_STATE: 'room_state',
  CREATE_ROOM: 'create_room',
  JOIN_ROOM: 'join_room',
  START_MATCH: 'start_match',
  PLAY_CARDS: 'play_cards',
  PASS_TURN: 'pass_turn',
  RESOLVE_ROUND: 'resolve_round',
  LEAVE_ROOM: 'leave_room',
  RECONNECT_ROOM: 'reconnect_room',
  ROOM_ERROR: 'room_error',
  SOCIAL_LOGIN: 'social:login',
  SOCIAL_SEARCH: 'social:search',
  SOCIAL_RESULTS: 'social:results',
  SOCIAL_INVITE: 'social:invite',
  SOCIAL_INVITE_RECEIVED: 'social:invite_received',
  SOCIAL_ERROR: 'social:error',
  PING: 'ping'
} as const;

export type CreateRoomPayload = {
  playerName?: string;
};

export type JoinRoomPayload = {
  roomId: string;
  playerName?: string;
};

export type StartMatchPayload = {
  roomId: string;
};

export type PlayCardsPayload = {
  roomId: string;
  playerId: string;
  cards: Array<{ id: string; rank: string; suit: string; value: number }>;
};

export type PassTurnPayload = {
  roomId: string;
  playerId: string;
};

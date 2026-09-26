import express from 'express';
import cors from 'cors';
import http from 'http';
import { Server } from 'socket.io';
import { RoomManager } from './game/room-manager.js';
import { SOCKET_EVENTS } from './game/socket-events.js';
import { SocialManager } from './social-manager.js';

const app = express();
const server = http.createServer(app);
const roomManager = new RoomManager();
const socialManager = new SocialManager();

const io = new Server(server, {
  cors: {
    origin: '*',
    methods: ['GET', 'POST']
  }
});

app.use(cors());
app.use(express.json());

app.get('/health', (_req, res) => {
  res.json({ ok: true, service: 'murlan-pro-server' });
});

io.on('connection', (socket) => {
  socket.emit(SOCKET_EVENTS.SERVER_CONNECTED, {
    socketId: socket.id,
    message: 'Connected to Murlan Pro server'
  });

  socket.on(SOCKET_EVENTS.PING, (payload, callback) => {
    callback?.({ ok: true, payload, receivedAt: Date.now() });
  });

  socket.on(SOCKET_EVENTS.SOCIAL_LOGIN, ({ username }, callback) => {
    try {
      const user = socialManager.register(socket.id, username);
      socket.data.socialUserId = user.id;
      callback?.({ ok: true, user });
    } catch (error) {
      callback?.({ ok: false, message: error instanceof Error ? error.message : 'Unable to sign in' });
    }
  });

  socket.on(SOCKET_EVENTS.SOCIAL_SEARCH, ({ query = '' }) => {
    const requesterId = socket.data.socialUserId as string | undefined;
    if (!requesterId) {
      socket.emit(SOCKET_EVENTS.SOCIAL_ERROR, { message: 'Sign in before searching for players' });
      return;
    }
    socket.emit(SOCKET_EVENTS.SOCIAL_RESULTS, socialManager.search(query, requesterId));
  });

  socket.on(SOCKET_EVENTS.SOCIAL_INVITE, ({ targetUserId }) => {
    try {
      const fromUserId = socket.data.socialUserId as string | undefined;
      if (!fromUserId) throw new Error('Sign in before sending invites');
      const invite = socialManager.invite(fromUserId, targetUserId);
      const target = socialManager.getById(targetUserId);
      if (target) io.to(target.socketId).emit(SOCKET_EVENTS.SOCIAL_INVITE_RECEIVED, invite);
    } catch (error) {
      socket.emit(SOCKET_EVENTS.SOCIAL_ERROR, { message: error instanceof Error ? error.message : 'Unable to send invite' });
    }
  });

  socket.on(SOCKET_EVENTS.CREATE_ROOM, ({ playerName = 'Player' } = {}) => {
    try {
      const room = roomManager.createRoom(socket.id, playerName);
      socket.join(room.id);
      socket.data.roomId = room.id;
      socket.data.playerId = socket.id;
      io.to(room.id).emit(SOCKET_EVENTS.ROOM_STATE, room);
    } catch (error) {
      socket.emit(SOCKET_EVENTS.ROOM_ERROR, { message: error instanceof Error ? error.message : 'Unknown error' });
    }
  });

  socket.on(SOCKET_EVENTS.JOIN_ROOM, ({ roomId, playerName = 'Guest' }) => {
    try {
      const room = roomManager.joinRoom(roomId, socket.id, playerName);
      socket.join(roomId);
      socket.data.roomId = roomId;
      socket.data.playerId = socket.id;
      io.to(roomId).emit(SOCKET_EVENTS.ROOM_STATE, room);
    } catch (error) {
      socket.emit(SOCKET_EVENTS.ROOM_ERROR, { message: error instanceof Error ? error.message : 'Unknown error' });
    }
  });

  socket.on(SOCKET_EVENTS.START_MATCH, ({ roomId }) => {
    try {
      const room = roomManager.startMatch(roomId);
      io.to(roomId).emit(SOCKET_EVENTS.ROOM_STATE, room);
    } catch (error) {
      socket.emit(SOCKET_EVENTS.ROOM_ERROR, { message: error instanceof Error ? error.message : 'Unknown error' });
    }
  });

  socket.on(SOCKET_EVENTS.RECONNECT_ROOM, ({ roomId, playerId }) => {
    try {
      const room = roomManager.handleReconnect(roomId, playerId);
      socket.join(roomId);
      socket.data.roomId = roomId;
      socket.data.playerId = playerId;
      io.to(roomId).emit(SOCKET_EVENTS.ROOM_STATE, room);
    } catch (error) {
      socket.emit(SOCKET_EVENTS.ROOM_ERROR, { message: error instanceof Error ? error.message : 'Unknown error' });
    }
  });

  socket.on(SOCKET_EVENTS.PLAY_CARDS, ({ roomId, playerId, cards }) => {
    try {
      const room = roomManager.playCards(roomId, playerId, cards as any);
      io.to(roomId).emit(SOCKET_EVENTS.ROOM_STATE, room);
    } catch (error) {
      socket.emit(SOCKET_EVENTS.ROOM_ERROR, { message: error instanceof Error ? error.message : 'Unknown error' });
    }
  });

  socket.on(SOCKET_EVENTS.PASS_TURN, ({ roomId, playerId }) => {
    try {
      const room = roomManager.passTurn(roomId, playerId);
      io.to(roomId).emit(SOCKET_EVENTS.ROOM_STATE, room);
    } catch (error) {
      socket.emit(SOCKET_EVENTS.ROOM_ERROR, { message: error instanceof Error ? error.message : 'Unknown error' });
    }
  });

  socket.on(SOCKET_EVENTS.RESOLVE_ROUND, ({ roomId, finishOrderIds }) => {
    try {
      const room = roomManager.resolveRound(roomId, finishOrderIds);
      io.to(roomId).emit(SOCKET_EVENTS.ROOM_STATE, room);
    } catch (error) {
      socket.emit(SOCKET_EVENTS.ROOM_ERROR, { message: error instanceof Error ? error.message : 'Unknown error' });
    }
  });

  socket.on(SOCKET_EVENTS.LEAVE_ROOM, ({ roomId, playerId }) => {
    try {
      const room = roomManager.handleDisconnect(roomId, playerId);
      socket.leave(roomId);
      io.to(roomId).emit(SOCKET_EVENTS.ROOM_STATE, room);
    } catch (error) {
      socket.emit(SOCKET_EVENTS.ROOM_ERROR, { message: error instanceof Error ? error.message : 'Unknown error' });
    }
  });

  socket.on('disconnect', (reason) => {
    console.log(`Socket disconnected: ${socket.id} (${reason})`);
    socialManager.disconnect(socket.id);

    if (socket.data.roomId && socket.data.playerId) {
      try {
        const room = roomManager.handleDisconnect(socket.data.roomId, socket.data.playerId);
        io.to(socket.data.roomId).emit(SOCKET_EVENTS.ROOM_STATE, room);
      } catch {
        // ignore disconnect cleanup errors
      }
    }
  });
});

const PORT = Number(process.env.PORT ?? 4000);
server.listen(PORT, () => {
  console.log(`Murlan Pro server listening on http://localhost:${PORT}`);
});

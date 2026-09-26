import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as socket_io;

class GameSocketState {
  GameSocketState({
    required this.connected,
    required this.socket,
  });

  final bool connected;
  final socket_io.Socket socket;
}

final gameSocketProvider = StreamProvider<GameSocketState>((ref) {
  final controller = StreamController<GameSocketState>();

  final socket = socket_io.io(
    'http://localhost:4000',
    socket_io.OptionBuilder().setTransports(['websocket']).build(),
  );

  socket.onConnect((_) {
    controller.add(GameSocketState(connected: true, socket: socket));
  });

  socket.onDisconnect((_) {
    controller.add(GameSocketState(connected: false, socket: socket));
  });

  socket.connect();

  ref.onDispose(() {
    socket.dispose();
    controller.close();
  });

  return controller.stream;
});

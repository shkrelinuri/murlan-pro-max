# Murlan Pro

Murlan Pro is a multiplayer card game project based on Albanian Murlan rules. The repo has a Node.js/Socket.IO server and a Flutter app shell for iOS and Android.

This workspace includes:

- `server/` — Node.js + Socket.IO authoritative game backend
- `client/` — Flutter app shell for iOS and Android

## Current state

The backend is organized around server-owned game rules, while the Flutter app is still a starting shell.

## Important rule

Game rules and validation must remain server-authoritative. The client should render and send intents, but the server must validate every move.

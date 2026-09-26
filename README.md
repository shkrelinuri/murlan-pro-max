# Murlan Pro

A cross-platform multiplayer card game application inspired by Albanian Murlan rules.

This workspace includes:

- `server/` — Node.js + Socket.IO authoritative game backend
- `client/` — Flutter app shell for iOS and Android

## Current status

This is the initial scaffold for the project. The backend is set up with a server-authoritative game engine shape and the Flutter app has a starter shell.

## Important rule

Game rules and validation must remain server-authoritative. The client should render and send intents, but the server must validate every move.

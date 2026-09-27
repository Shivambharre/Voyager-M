# Player Boundary

## Contract

`PlayerEngine` exposes a `PlayerSnapshot` and snapshot stream plus operations to
load media, play/pause, seek, change speed, and dispose. The contract uses app
types and Dart durations rather than a concrete platform player's types.

## Current state

`MockPlayerEngine` validates basic operation order and speed/seek ranges. The UI
currently presents its own local mock state and is not wired to this contract.
No video is rendered or played by the prototype player screen.

## Planned Android behavior

The production engine should publish buffering, ready, playing, paused,
completed, unavailable, and error states; report position and duration; support
seek and speed; dispose platform resources; and allow progress persistence
through feature services. Keep Android Media3/ExoPlayer APIs inside the Android
adapter.

Retain a mock implementation for deterministic widget and application tests.

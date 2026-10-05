# F64 — The Guided Walk as a Package of Its Own

**Status:** later.

**What must be true.** Any agent can lead a person through any Flutter app the way the guided walk
leads a person through this interface, from a package published on its own that the app only
depends on.

## Why

The plugin `guided_walk` is in the public repository `fuinorg/flutter-guided-walk` under
Apache-2.0, and this interface takes it by git at a version tag. The app gives it the variable that
names the folder, the theme of the panel's window, the panel's words and its own choice widgets; a
Linux part names and sizes the panel's window. An agent reaches the walk through its files or
through an MCP server over them, and the walk exists in development builds only. Sokar's backend
has no part in it.

## Acceptance

- **Published on pub.dev**, and this interface depends on it from there; the only Sokar-specific
  part left here is marking what is secret. Seen to fail: `pubspec.yaml` still takes it by git, or
  walk code other than secret marking remains in `lib/`.
- **The window's state is read from Flutter's Semantics tree**, so it describes any app, not this
  one's own widgets. Seen to fail: a test in the package describing its example app built from
  plain Material widgets with no knowledge of them.
- **Secrets are blanked generically**: every `obscureText` field, and anything an app wraps in a
  `Sensitive(child: …)` (this interface's terminals would use it). Seen to fail: a package test
  whose window state shows the content of either.
- **The way to the agent is pluggable**: a folder, a WebSocket, or an MCP server. Seen to fail: a
  package test that drives one walk over each.
- **The walk file's format is written down and versioned**, so an agent can write one without
  knowing the app's internals: steps, the keys or button words they point at, what moves them on,
  and what makes them go away. Seen to fail: a walk file with an unknown version is refused, and
  the example walks are checked against the written format.
- **The person is never left with dots alone.** While the panel waits for the agent's answer and
  shows "…", after 15 seconds it says so in words, in the panel's language, with the time that has
  passed: "Der Agent arbeitet daran - seit 1:20". The agent's next line replaces it. Seen to fail: a
  widget test that waits 15 seconds with no answer and then sends one. (Writing one line before any
  longer work is the leading agent's part, not the plugin's.)

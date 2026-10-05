# F93 — Connections: Its Rare Actions Out Of The Way

**Status:** soon.

**What must be true.** A machine's Connections shows which key or token the machine reaches each
outside address with, and its rarely needed actions, "Add a connection" and "Forget", sit in the
view's ⋮ instead of in the everyday view.

## Why

Binding a machine to a project at a forge makes those entries itself. "Add a connection" is needed
only for a repository on no forge set up here (an own git server with a token), "Forget" only to stop
a machine using a key for an address.

## Acceptance

- "Add a connection" and "Forget" are reached from the view's ⋮ and work as before; the view itself
  offers neither. Seen to fail: a scenario in `test/features/connections.feature` that finds either
  action in the view outside the ⋮, or cannot add or forget a connection through the ⋮.

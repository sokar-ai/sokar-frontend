# F29 — Try A Machine Before Watching It

Asked for by the operator on 2026-09-11, after adding a machine that then said only *"Cannot be
reached"*.

## What is wrong with the dialog today

Adding a machine is the moment somebody knows what they typed, and the dialog is the one place it
can still be corrected. Today nothing is tried there. The machine is added, and whatever is wrong
arrives later as a tile that cannot be reached, away from the fields that caused it.

What goes wrong is rarely one thing. The key is not in the agent. The host key was never accepted.
The socket belongs to another user's uid. Or no daemon runs there at all. **The last two look
identical from ssh**: the forward comes up either way, and only connecting through it finds the far
end empty.

## What must be true

**Before a machine is watched, the dialog can try it the way watching it would, and says either
what answered or what stood in the way — in words somebody can act on, while the fields are still
there to change.**

## Acceptance

- The dialog offers to try the connection once it has enough to try, and trying is never required
  to watch the machine.
- A forward raised here is raised for the trial on a socket of its own, and taken down again
  whatever the trial found. A trial never leaves a process or a socket behind, and never adds the
  machine.
- Success says what answered: the product and its version.
- A forward that cannot be raised shows what ssh said, unchanged.
- A forward that comes up while nothing answers through it says to look at the far end — that
  sokard runs there, for the user logged in as — and not that the machine cannot be reached.
- A daemon that answers but serves nothing this build understands says so.
- An answer is shown only while the fields still describe what was tried.
- A socket somebody else forwarded is tried by connecting to it, with nothing raised.

## What the backend is short of, and what it is not

Nothing. `GetInfo` answers what the trial needs: the product, its version and the interfaces it
serves.

## To be checked

- **Whether a trial should also say which user it reached — and what could tell.** The wrong uid in
  the socket path is the commonest mistake, and the trial only finds its consequence.

  **Measured on 2026-09-13, on the Ubuntu VM, logged in as uid 1001**, forwarding to three sockets
  and connecting through each: another user's socket (`/run/user/1000/…`, a `0700` directory not
  ours), our own directory with nothing serving, and a directory that does not exist. **All three
  look identical from here**: the client's connection is reset, and `ssh` says exactly
  `channel 1: open failed: connect failed: open failed` in every case. OpenSSH does not pass the
  server's reason to the client, so **ssh's own words cannot tell a wrong uid from a missing daemon.**

  **And a daemon field cannot tell either.** The earlier idea was a daemon that says which user it
  runs as. But with the wrong uid there is no daemon to ask: every user's runtime directory is `0700`,
  so the forward never reaches somebody else's socket at all. The field would only ever be read by a
  trial that had already succeeded.

  **What can tell is the login uid.** The uid in the typed path (`/run/user/<uid>/…`) compared with
  the uid the machine gives the account logged in as — `id -u` over the same `ssh` — separates the
  three cases: a different uid is *"that socket is in another user's runtime directory; you log in as
  uid 1000"*. It needs nothing from Sokar. **The open part is whether the trial may run that one
  read-only command** as part of *Try the connection*, since F30 set the rule that a command on
  somebody else's machine is a step past forwarding a socket.

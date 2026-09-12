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

- **Whether a trial should also say which user it reached.** The wrong uid is the commonest mistake
  and the trial only finds its consequence. A daemon that said which user it runs as would let
  the dialog say *"this is somebody else's Sokar"* instead of nothing at all.

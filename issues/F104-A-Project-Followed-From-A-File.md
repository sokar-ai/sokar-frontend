# F104 — A Project Followed From A File

**Status:** open; decided on 2026-10-10. Blocked by `sokar` B160, "A Project Followed From A File
Over The Socket".

**What must be true.** A person makes a project from a bundle or a directory on the machine, from
the interface, as `sokar project follow NAME FILE` does. An offline project, which can come only
that way, can be made from the interface again.

## Why

Since `sokar`'s B137, decided on 2026-10-09, an offline project never connects. `upstream:` and
`--upstream` are refused for it, and its repository comes in only as a bundle (`gate restore`) or
from a checkout on the machine. `sokar project follow NAME FILE` takes a bundle or a local directory
for every class, and a project followed from a file is never fetched in the background.

The interface follows a project only from a repository's address
(`lib/src/app/project_following.dart`, `SokarClient.follow(name, url)`). So an offline project can no
longer be made from the interface at all.

## The contract

- **Following from a file is the same `Follow`, with a path in `url`.** A value with neither a
  scheme (`https://`, `file://`) nor a host before a colon (`git@host:`) is taken as a file: a
  bundle or a directory, read once and never fetched in the background. An offline definition is
  taken only that way.
- **The path is absolute and on the machine.** Today the daemon does not make a relative path
  absolute, as `sokar project follow` does. `sokar` adds that, and says in `Follow`'s comment that
  `url` may be a path.
- **A bundle from this computer has no way to the machine yet.** `HandIn` writes into a running
  task only. The shape preferred: `Follow` takes the bundle's bytes itself, so no file outlives
  the call. The other shape would be a method that keeps the bytes on the machine and answers the
  path to give `Follow`. `sokar` B160 takes the first shape: the bytes go in the `Follow` call, the
  daemon keeps the bundle where only the account reads it, and a bundle above a limit the contract
  states is refused by name.

## The shape

- **The follow dialog offers a file beside an address**: a bundle or a directory, and for an
  offline project only that.
- **A directory or bundle already on the machine** is given as its absolute path there.
- **A bundle the person has on this computer** goes to the machine through the contract above.
- **A project followed from a file says so** in its view: that it is never fetched in the
  background, and how it is brought up to date (a new bundle).

## Acceptance

- **An offline project is made from a bundle** from the interface, on a machine reached over ssh,
  and its tasks start. Seen to fail: today's dialog, which offers only an address.
- **A project of another class is followed from a directory on the machine.** It is listed as
  followed from a file, and nothing fetches it in the background.
- **An offline project with an address is refused in Sokar's words**, and the dialog offers the file
  instead.

## To be checked

- **The limit on a bundle's size** that `sokar`'s new way takes, and how the interface shows the
  upload of a large one.

# Changelog

All notable changes to this project are recorded here.

The format is [Keep a Changelog 1.1.0](https://keepachangelog.com/en/1.1.0/), and this project
follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

Nothing has been released yet. Every build publishes a `~snapshot` package to the `snapshots`
distribution, so an entry below has reached an operator only if they follow that repository.

## [Unreleased]

### Added

- **The window opens on what needs a person**, from every machine at once: open questions
  first, nearest deadline first with the time left, and answered on their tile, a machine that cannot be reached said above them, and
  a quiet task marked as a guess.
- **Every tile carries its work's menu**, from its button or a right-click, acting on the tile's
  own machine; the task's name on it can be selected and copied.
- **A machine can be tried before it is watched**, from the dialog that adds it: what answered, or
  what stood in the way — ssh's own words, or a forward that came up with no daemon behind it.
- **Every tile is headed by its machine's name**, and what an action from the tile came to is
  said on the tile, not only in the status line.
- A window for Linux desktop that talks to `sokard` over a unix socket. Every action is reachable
  from the keyboard and from a pointer, and the selection survives a restart.
- **Projects**: what each one is and how far behind it has fallen, guided creation checked by the
  machine that will run it, an editor for what work may reach, and a removal that says what it
  destroys before it does anything.
- **Work**: started with an agent, a mode and a credential; stopped, renamed and recreated, with
  commits that never reached the gate refusing the removal rather than being lost. A named job can
  be started again.
- **Logs** read inside the interface as they are written, colour included, and files whose names
  say nothing about what they hold arrive explained.
- **Interactive sessions** inside a container, locally or over ssh, in a terminal of the
  interface's own. Leaving one closes the way in and stops nothing.
- **Blocked connections** answered where the work is listed, and what running work may reach
  widened or taken back, with the scope chosen rather than defaulted.
- **The gate**: what a project pushed, read file by file, and what a task holds that never reached
  it.
- **Backups** of a mirror listed, removed and restored, with unreviewed pushes refusing a restore;
  and the upstream asked on demand.
- **The secret store**: what it holds and whether it is open, without a value ever being shown.
- **Several machines** watched at once, told apart from one node reached two ways, with the
  forward raised and dropped by the interface.
- **An emergency stop** that names what survives it, and **notifications** for somebody who is not
  looking at the window.
- **Host readiness** and the **agent inventory**, each saying what it could not establish rather
  than reporting nothing wrong.
- Debian and RPM packages, proven to install in a clean container on every build.

### Changed

- **The frame is one rail and one place per machine.** The rail holds what needs you, every
  machine with whether it answers, and a stop for every machine. A machine's place holds its title
  with its emergency stop and menu, its projects as cards that narrow the work, its work as tiles
  beside starting work and saved jobs, and a status line of what it ran. The menu bar holds
  Machines, Options and About; the finder goes to where an action lives and marks it there.
- **Stopping keeps the work and its workspace**; removing is its own action, and what the machine
  would do on "Start it again" is shown before anybody presses it, refusals included.

### Fixed

- Working in a task by hand is no longer offered for a machine reached through a socket something
  else forwarded. It ran the local `sokar` against a task on another machine.
- A machine whose forward reaches no daemon now reads as not answering. The connection failed
  with an error nothing handled.
- A machine added under a name already watched, or one that would share its forward, is
  refused in the dialog instead of being silently dropped. The socket on the other machine is
  no longer prefilled with a guessed uid.

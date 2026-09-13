# Changelog

All notable changes to this project are recorded here.

The format is [Keep a Changelog 1.1.0](https://keepachangelog.com/en/1.1.0/), and this project
follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

Nothing has been released yet. Every build publishes a `~snapshot` package to the `snapshots`
distribution, so an entry below has reached an operator only if they follow that repository.

## [Unreleased]

### Security

- **The build no longer trusts what it downloads.** Every GitHub Action is pinned to a commit
  rather than a movable tag, kept current by Dependabot and held by a test that rejects a tag; the
  `nfpm` binary that writes the packages is verified against its digest before it runs.
- **What a machine sends is bounded and checked.** A reply that is not readable, is not an object,
  or never ends is reported as a lost connection rather than escaping as an error nobody sees.
- **A forward never takes an endpoint away from something that is using it**, and a forward that
  cannot be made readable by nobody but you is refused rather than reported as working.
- **Preferences are written in one step and readable only by their owner.** They name the machines
  somebody watches and the accounts they log in as.
- **A closing terminal session signals only a process that is still there**, and everything typed
  into one arrives whole.

### Added

- **What was run outlives the window.** Every operation is kept for 30 days in
  `~/.local/state/sokar/operations.json`, readable only by you; the list of what was run shows
  earlier ones and says where the file is, the finder opens it, and a failure nobody opened still
  waits under Needs you after a restart.
- **A trial that fails because the socket is in another user's runtime directory says so**, and
  names the path that was probably meant, instead of reporting that nothing answers.
- **The window opens on what needs a person**, from every machine at once: open questions
  first, nearest deadline first with the time left, and answered on their tile, a machine that cannot be reached said above them, and
  a quiet task marked as a guess.
- **Every tile carries its work's menu**, from its button or a right-click, acting on the tile's
  own machine; the task's name on it can be selected and copied.
- **A machine can be tried before it is watched**, from the dialog that adds it: what answered, or
  what stood in the way — ssh's own words, or a forward that came up with no daemon behind it.
- **A machine that can be reached but serves nothing is offered a start**, in the dialog that adds
  it and in the menu of a machine already watched: the line that would run is shown, nothing runs
  until somebody agrees, and the connection is tried again afterwards to say whether it worked.
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

- **Needs you lists only what needs a person**: open questions, work waiting at the gate, and a
  question that was answered or ran out, which stays with its outcome until *Got it* puts it away.
  Work that needs nobody is in its machine's area, under Running or its project. An operation
  somebody started that failed waits there too, until it has been opened.
- **The frame is a tree of machines and one place per machine.** The tree holds what needs you,
  every machine with whether it answers — opening onto Running, New project and its projects — and
  a stop for every machine. A machine's place holds its title with its emergency stop and menu,
  the chosen project's header with its menu, the work as tiles beside starting work and saved
  jobs, and a status line of what it ran. A new project is described there and chosen once made.
  The title bar says where you are and holds the finder, another machine, Options and About; the
  tree waits behind the menu button on a narrow window. The look is melkheftken's.
- **Every machine is asked again**, on its own as often as Options says and by hand with Refresh,
  so a project removed at the machine does not stay on screen.
- **A machine that cannot be reached can be marked as seen**, until it answers again. The finder goes to where an action lives and marks it there.
- **Stopping keeps the work and its workspace**; removing is its own action, and what the machine
  would do on "Start it again" is shown before anybody presses it, refusals included.

### Fixed

- **A start that fails says why.** When systemd refuses to start the daemon, its own words and exit
  code are shown, and the binary is no longer started behind its back; without a unit, a daemon that
  ends at once is reported with what it wrote instead of as started.
- **The licence is the GPL 3, like the rest of Sokar**, and its text ships in every package. The
  package metadata had said Apache-2.0.
- Working in a task by hand is no longer offered for a machine reached through a socket something
  else forwarded. It ran the local `sokar` against a task on another machine.
- A machine whose forward reaches no daemon now reads as not answering. The connection failed
  with an error nothing handled.
- A machine added under a name already watched, or one that would share its forward, is
  refused in the dialog instead of being silently dropped. The socket on the other machine is
  no longer prefilled with a guessed uid.

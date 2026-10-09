# Changelog

All notable changes to this project are recorded here.

The format is [Keep a Changelog 1.1.0](https://keepachangelog.com/en/1.1.0/), and this project
follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed

- Every workflow run is titled with its workflow, its branch or tag and its commit's subject; the
  shared rules' workflow is called "Shared rules check" and the Artifactory probe "Artifactory probe
  test".
- The build takes `sokar-parent` `0.1.4-SNAPSHOT` and with it the build tools' snapshot, and its
  Maven build and tests read the project's `settings.xml` like every other Maven call, so the
  snapshots come from Central's snapshot repository.

## [0.4.1] - 2026-10-08

### Added

- A work tile says what the build of the work's last push did, as the machine reads it from the
  forge, in a line of its own under its head: "Build passed", "Build failed" or "Build running",
  each with a mark of its own shape and colour, and the commit, the jobs and the age under it. The
  work's detail lists every job and which of them left a log in the task.
- A file on this computer can be handed to running work from a tile's menu, sent in parts that go
  on where the machine stopped after a lost connection, and taken back; the work's detail lists
  what it holds, who handed each file in, and the record of every hand-in.
- A followed project's page has "Check it now": the machine fetches the project's repository and
  asks each repository's upstream at once, rather than at its next round, and the page says
  "checking…" and then what came back.
- A repository worked on without a project says where its work comes from and goes: from the
  checkout it was started in and back into it as `sokar/<task>`, its remote left to the person, or
  from its remote and back there.
- A work's menu has "Bring it up to its source": what moved in its checkout or remote reaches the
  task without stopping it, and the status line says what moved and whether its agent was told.

### Changed

- Every push checks with `sokar-release` that no page or source cites an issue, and that every page
  under `doc/` is in the site's navigation exactly once, and runs the tests that read a document;
  a push of documents alone runs only these and leases no machine.
- Every push checks with `sokar-release` that each directory with a `pom.xml` has a `README.md`.
- A release refuses to build when anything Maven resolved for it is a snapshot - the parent, the
  tools or their plugin dependencies - and names what it found.
- The Maven build takes `sokar-parent` as its parent, which gives it the JDK, the build tools' and
  the plugins' versions, and the `ci-tools` profile that puts the tools on the checks' classpath;
  the `hetzner` profile only rents and sweeps a machine.
- The Dart and Flutter packages are at the newest versions that resolve with Flutter 3.47.0,
  `cupertino_icons` at 2.0.

### Fixed

- Text copied out of a work's terminal keeps the spaces it shows, also where the program moved the
  cursor instead of writing them, as Claude Code does.

## [0.4.0] - 2026-10-05

Initial public version.

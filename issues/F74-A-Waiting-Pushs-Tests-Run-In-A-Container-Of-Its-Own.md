# F74 — A Waiting Push's Tests Run In A Container Of Its Own

**Status:** soon; blocked by `sokar` B95.

**What must be true.** A person can run a waiting push's build or tests, and later open it in an IDE,
in a fresh container on the machine made from the project's image, and read the result beside the
review, without the run reaching the gate.

## Why

Building or testing an agent's work runs whatever the agent wrote; on the person's own computer it
would run with their rights and credentials. `sokar` B95 gives `gate try <task> -- <command>`: a fresh
container from the project's image, the waiting ref as its workspace, the project's egress and
limits, no way back to the gate, and an IDE attached there later. An IDE backend on the host is not
offered.

## Acceptance

- *Run its tests* beside the review: the command is asked once and kept for the project, run in a
  fresh container, its output streamed and its exit said beside the review. Seen to fail: a scenario
  in `work_handover.feature` against a fake `gate try`, where the output or the exit is missing.
- *Open in an IDE* attaches an IDE to the same container, when Sokar offers it. Seen to fail: a
  scenario where the IDE is attached to anything but that container.
- Nothing the run does reaches the gate: the push stays as the agent made it. Seen to fail: on the
  VM against Sokar's handover, a run that writes to its workspace changes the waiting ref.

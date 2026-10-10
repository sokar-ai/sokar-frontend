# F105 — A Task's Terminal In The Interface As Outside It

**Status:** open; decided on 2026-10-10.

**What must be true.** A task's terminal in the interface behaves as the same task in a plain
terminal, now that Sokar has set its tmux up for that: keys, colours, the clipboard and scrolling
reach the task and come back as they do outside the interface.

## Why

Sokar's B134, built on 2026-10-09 and 2026-10-10, set a task's tmux up to behave as the terminal
outside it, measured per key in a plain terminal:
- Esc arrives at once.
- Shift+Enter and focus events come through.
- Truecolor and OSC 52 come through.
- Shift+PageUp scrolls back in tmux's copy mode, and Shift+PageDown scrolls down again and leaves it.

Each person can add their own settings in `~/.config/sokar/tmux.conf`.

The interface is one of those outside terminals, and it was not measured. Its terminal is the `xterm`
library with a scrollback of its own of 10,000 lines (`lib/src/app/session.dart`). What it sends for
these keys, and whether it keeps some of them for itself, is not known. Shift+PageUp, for example,
might scroll its own scrollback instead of reaching tmux, and its own scrollback holds only what
passed through it, not tmux's history.

## The shape

- **Measure first**, through the interface on the VM, for the same keys and capabilities as B134:
  Esc, Shift+Enter, Ctrl and Alt with the arrows, truecolor, OSC 52, focus events, the mouse wheel,
  and Shift+PageUp/PageDown. Do it once in a plain terminal and once in the interface, against the
  same task.
- **Then make the interface send what a plain terminal sends**, and decide which scrollback a person
  uses: the interface's own or tmux's. They must not fight over the same keys.

## Acceptance

- **A per-key test** for each key and capability above, through the interface's terminal against a
  real task, each seen to fail first where the interface differs today.
- **Scrolling back and down works** in the interface as in a plain terminal, by the keys and by the
  wheel.

## To be checked

- **Whether the interface keeps its own scrollback** once tmux's is reachable, or gives it up for
  tasks.

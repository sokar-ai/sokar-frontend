# F77 — What A Piece Of Work Did Is One Page

**Status:** soon.

**What must be true.** A person sees on one page what a piece of work did, in words, and one
timeline of everything that happened; the logs by source are for troubleshooting only.

## Why

A piece of work's logs are split by where they come from (firewall, DNS, vault, gate, agent), and
`task.log` is one JSON object per line, so the agent's own last answer is easily left unread. That
answer is the most important information after an unattended run and must be easy to reach.

## Acceptance

- *What it did* at the top of every tile: the agent's last answer as text; its commits and their
  diff since it started; what of that waits at the gate; its messages; what the firewall stopped,
  only where something was. Seen to fail: a scenario in `work_tiles.feature` where any of these is
  missing, or the firewall part shows when nothing was stopped.
- *Everything*: all its logs in one timeline, by time, filterable by source. Seen to fail: a scenario
  in `live_logs.feature` where lines from two sources are out of time order or a filter leaves
  another source's line.
- The logs by source stay, folded away. Seen to fail: a scenario where one source's log cannot be
  opened.
- An unattended run's output ends with a line a person sees: finished, and where to go next (a push
  waiting, or nothing done and why), not only a word in the header. Seen to fail: a scenario where a
  finished unattended run shows no such line.

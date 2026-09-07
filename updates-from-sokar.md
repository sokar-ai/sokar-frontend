# Updates from Sokar

Backend changes that affect this repository, newest first. Written by the Sokar side; re-read the
IDL off a running daemon (`org.varlink.service.GetInterfaceDescription`) rather than trusting this
summary on the parts it touches.

## 2026-09-07 — a removal says what it destroyed

**Additive only**: the `Stop` reply gained one field. Nothing was removed, renamed or retyped.

```
method Stop(...) -> (
  ...
  discarded: int    # paths the container had that its image did not, when it was removed
)
```

### What to check

1. **Show it beside a removal.** `discarded` counts what the agent installed *inside* the
   container - packages, caches, a built toolchain - which is destroyed with the container and has
   nowhere to arrive, unlike the workspace, which the gate holds. Nothing else records that any of
   it existed, so a removal that does not mention it is the last chance gone. It is zero unless
   `removed` is true.

2. **It counts added paths, not changed ones.** A container that ran at all reports `/etc` and
   `/var` as changed, so a number counting those would never be zero and would mean nothing.
   Present it as "how much", not as "what": there is no file list behind it.

### Not an API change, but it changes what you will see

- **A failed task is no longer removed.** A non-zero exit now stops its container and leaves it in
  place - workspace, logs and unpushed commits intact - because `--keep` has to be decided before a
  run and the run worth looking at is the one that went wrong. So `List` will show exited tasks
  that earlier versions had swept away. They are resumable, and `Stop` with `purge` is what
  discards one. An interface that assumed "failed means gone" will show more tasks than it used to.

- **`sokar panic` exists now** as a CLI command: stops every running task and every helper it
  started, takes no container names, removes nothing. **There is no daemon method for it**, so
  F18's emergency stop still has no backend and you may not shell out for it. If you want one, ask
  - it would be a method over the same `TaskControl.stop` the CLI already uses, and adding it is
  small.

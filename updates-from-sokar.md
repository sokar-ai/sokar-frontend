# Updates from Sokar

Backend changes that affect this repository, newest first. Written by the Sokar side; read it
before trusting `doc/Backend-API.md` on the parts it touches, and re-read the IDL off a running
daemon (`org.varlink.service.GetInterfaceDescription`) rather than this summary.

## 2026-09-07 — a prompt now carries its answer

Sokar commits `bcde22b` and `d7eaeec`. **Additive only**: `Prompt` gained one optional field.
Nothing was removed, renamed or retyped, so the client keeps working untouched — it just cannot
tell an expired prompt from an open one until it reads the new field.

```
type Prompt (
  ...
  verdict: ?string    # absent while open; "allow", "deny" or "timeout" once settled
)
```

### What to check

1. **`Prompts` streams answers as well as questions.** The same destination arrives a second time
   with `verdict` set. Match it to the open question by **`task` + `key`** — both unchanged and
   stable — and update that row rather than adding one. Anything that renders every `Prompts`
   reply as a new item now shows each blocked destination twice.

2. **`"timeout"` is the case this was added for.** A prompt that ran out is never asked about
   again, so before this a question simply stopped arriving and a client could not tell "expired"
   from "still waiting for its operator". Show it as expired — and keep it answerable: `Decide`
   still works on a timed-out prompt and still takes effect. On the machine itself the desktop
   notification is replaced by one saying the destination stays blocked; a remote client should
   say the same thing.

3. **A client sees the echo of its own `Decide`.** An answer given from a client comes back on the
   stream as a verdict event too. Do not apply it twice, and do not treat it as a new prompt.

4. **`at` means two things, deliberately.** On a question it is when the connection was blocked; on
   the verdict event it is when it was decided. Keep the question's own value if you want the block
   time of an answered prompt. `prefix` is empty on a verdict event.

5. **Rely only on declared fields.** These events carry more than the IDL declares — `shown`,
   `project`, `source` among them. Those are not contract and may change without notice. If one of
   them would be useful, ask for it to be declared rather than reading it.

### Not an API change, but relevant here

- **Secret store control.** Sokar's CLI now has `sokar vault lock`, which drops the cached
  passphrase without restarting anything, and says so when a running task still holds a credential
  its proxy already read. **There is no `Lock` or `Unlock` method on the daemon** — the contract has
  no vault-mutating method at all, only `Credentials()`. A lock control in the interface needs that
  method added on the Sokar side first; ask and it will be. `Credentials().readable` already
  separates "locked" from "empty".

- **`Tail("gate.log")` no longer contains the task's git push token.** It was being printed in full
  into a log the daemon streams to whatever is tailing it. If anything here parsed a token out of
  that stream, or a fixture reproduces the old line, it has to change.

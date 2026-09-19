# F48 — Confirm A Host Key Before Trusting It

Opened on 2026-09-19 at the operator's request. His follow of `git@github.com:sokar-ai/sokar-project.git`
on the test machine failed with *"Host key verification failed"*. The machine had never met
github.com, and ssh fell back to asking through `ssh-askpass`, which a daemon cannot answer. His
ruling: **an unknown host key leads to a question in the client.** It is neither accepted
silently nor left to fail silently.

## What must be true

**When the machine meets a host whose key it does not know, the person is shown that host and its
key's fingerprint and decides whether to trust it. Nothing is trusted without that answer, and
once it is given the attempt can be made again.**

## Acceptance

- **An unknown host key is its own answer**, never a missing credential and never a generic
  failure. It names the host and the fingerprint of every key the host offered (`SHA256:…`, with
  its type), as the machine saw them.
- **The question is shown where the attempt was made**: in the follow dialog, and wherever else a
  machine fetches on somebody's behalf. It says what trusting means: *this machine will connect
  to this host from now on without asking, and a different key later will be refused.* The
  fingerprint is shown whole, so it can be compared with the one the host publishes.
- **Trusting is an explicit act**, and *Leave it* is the default. What is trusted is exactly the
  key that was shown, never *whatever the host offers next time*.
- **After trusting, the attempt is made again** without retyping anything.
- **A key that changed is not the same question.** A host whose recorded key no longer matches is
  refused, and said as a possible interception. It is not offered as *trust this one instead*
  in the same words.

## Built, 2026-09-19, against Sokar `0.1.0~snapshot.168.1+local.20260919T154521`

The follow dialog shows every key the host offers with its type and whole fingerprint, the
sentence in Sokar's words about comparing with what the host publishes, and a key that has to be
chosen. *Trust this key and follow again* records exactly that key and then follows with nothing
retyped. A host that offers other keys by then records nothing and says so. A key that changed
shows the keys and the warning, and nothing to trust. It needs the host on the answer, which is
asked for. Until that arrives, trusting is not offered, because the host is never worked out here.

## What the backend is short of

Asked of Sokar on 2026-09-19:

- **An outcome for an unknown host key** on `Follow` (and its dry run), carrying the host and the
  offered keys' types and fingerprints.
- **A way to trust exactly that key**: a method or a parameter taking the host and the
  fingerprint the person saw. The machine records the key only if it still matches.
- **A separate outcome for a changed key.**

## To be checked

- **Where else a fetch meets a new host**: a sync of the upstream, a task's own clone. Which of
  them surface to a person is Sokar's to say.

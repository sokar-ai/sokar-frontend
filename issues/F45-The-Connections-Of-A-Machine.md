# F45 — The Connections Of A Machine

Opened on 2026-09-19 at the operator's request, after a follow of a private repository failed on the
test machine; reshaped the same day when Sokar made credentials a machine's **connections**, not a
git setting. Built against the contract Agent Sokar pasted (QF41), and **measured against his local build on the
VM** (`0.1.0~snapshot.162.1+local.20260919T085632`, 2026-09-19): the integration leg, 7 of 7 —
declaring a connection through the interface, listing it, checking an address against it and
forgetting it; following a repository through the check. **Not measured: storing a value and
`READY`** — that needs the vault's passphrase, which only a person has.

## What is wrong today

A machine reaches a private repository — and later a registry or anything else — with a credential,
and nothing here can say which it has, give it one, or tell *"a credential is configured, open the
vault"* from *"nothing is configured"*. Following a private repository failed with a sentence that
sent the operator to a vault that would not have helped.

## What must be true

**A person sees every connection a machine has, adds one and forgets one, from the interface — the
description over the socket, the secret only ever stored on the machine — and nothing is followed
until the machine says the credential it would use is there.**

## Acceptance

- **Every connection is listed, even with the vault shut**: what it is for (`match`, `purpose`), of
  what kind (an ssh key, a token, a user and password, OAuth), where its value is (`source`), and
  whether it is there now (`present`). One kept outside the vault — a key in `~/.ssh`, a variable, an
  agent — is **shown as not protected, never refused**: a state, like an unverified follow.
- **Adding one declares its description**, kind chosen and never inferred from the address, and then
  stores its value **on the machine** with the command the machine names — typed or pasted into a
  terminal there, or, for a key file on this computer, sent to that command over ssh. The value never
  crosses Sokar's socket, is not written to disk here, and is never shown again.
- **What a credential opens is said before it is stored**: a person's own key or a full-access token
  reaches every repository that person can, not only the one being followed; a restricted,
  read-only token is enough to follow.
- **Forgetting one says what still holds a value** afterwards, rather than implying the secret is
  gone — a key in `~/.ssh` is the person's, and Sokar does not delete it.
- **An OAuth token shows when it expires**, and one that expired is said by name with what to run.
  There is no *Renew*: nothing renews one without a person yet.
- **The follow dialog checks first** (`CredentialCheck`) and offers *Follow it* only on `READY`; for
  every other answer it offers the way out — open the vault, add the connection, store its value.
- **Reachable from the machine's menu, and as a step of the machine wizard** after the vault.

## Built, 2026-09-19, against the contract Sokar pasted (QF41)

- **The machine's menu, *Show how this machine connects out*:** every connection with what it is
  for, its kind, where its value lives and whether it is there — *the vault is shut* said as that,
  never as *missing* — one outside the vault marked not protected, an OAuth expiry shown.
- **Adding one:** the kind chosen, never read off the address; where its value lives chosen, the
  vault by default. The machine's `storeCommand` is shown and run on the machine: typed into a
  terminal there when it asks for the value, or — for a key, which is a file — sent to it on standard
  input over ssh from a key of this computer or a pasted one, the field emptied the moment it is
  sent, and kept on screen to try again if storing failed. Declaring again says *updated*.
- **Forgetting one** says what still holds its value.
- **The follow dialog checks first**, and follows nothing that could only fail: *open the vault*,
  *set up its connection* or *store its value* beside the reason; a local path needs nothing; a
  Sokar without the check is followed as before.
- **The machine wizard ends with it**: *Watch it, then set up how it connects out*.

## What the backend is short of

The three methods and the `connections` list are decided and half built on Sokar's side (its 08:12Z
note); the IDL is asked for as QF41. Not yet on any socket.

## To be checked

- **Storing a value and `READY` on a real machine**: a person at the vault's passphrase, once.

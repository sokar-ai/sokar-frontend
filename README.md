# sokar-frontend

The interface for [Sokar](https://github.com/fuinorg/sokar), in Flutter.

Sokar runs AI coding agents in locked-down containers: no network except what a project
declares, no credential the agent can read, and nothing leaves the machine without somebody
approving it. Everything it can do is reachable from a CLI today. This is the interface that
makes it reachable without one.

## Start here

1. **[Backend API](doc/Backend-API.md)** — how to talk to the daemon. One unix socket, JSON
   objects separated by NUL bytes, no client library. It also covers reaching a Sokar on another
   machine, which is the same code and a different socket path, and the rules for staying
   compatible with a backend older than this build.
2. **[Requirements](requirements/README.md)** — what must be true for a person using it, in the
   order to build it. Each file carries its own acceptance criteria, so it can be judged done
   rather than discussed. [Design](requirements/design.md) says what it is built out of.
3. **[What the contract does not yet cover](doc/Contract-Gaps.md)** — roughly half the
   requirements have no backend method behind them yet, and which half is not obvious.
4. **[AGENT.md](AGENT.md)** — the working rules: how to talk to the backend, how to stay
   compatible with an older one, how this is tested, built and packaged.

To see what a running backend offers, with a daemon up:

```
dart tool/contract.dart
```

## What this is not

It is not a wrapper around the CLI. The daemon serves the domain directly, and an interface that
shelled out to `sokar` would be a second implementation of every refusal the product makes — the
ones that stop work being destroyed.

# sokar-frontend

The desktop interface for [Sokar](https://github.com/sokar-ai/sokar), on Linux.

Sokar runs AI coding agents in locked-down containers: no network except what a project declares, no
credential the agent can read, and nothing leaves the machine without somebody approving it. This
interface does what Sokar's command line does, on this computer and on machines reached over ssh,
without a terminal.

![The interface: the work running on a machine reached over ssh](images/sokar-frontend.gif)

## Install

From the same package repository as Sokar itself.

Debian and Ubuntu:

```bash
curl -fsSL https://fuinorg.jfrog.io/artifactory/api/security/keypair/sokar-packages/public \
  | sudo tee /usr/share/keyrings/sokar.asc > /dev/null
echo "deb [signed-by=/usr/share/keyrings/sokar.asc] https://fuinorg.jfrog.io/artifactory/sokar-dist-deb releases main" \
  | sudo tee /etc/apt/sources.list.d/sokar.list
sudo apt update && sudo apt install sokar-frontend
```

Fedora:

```bash
sudo tee /etc/yum.repos.d/sokar.repo > /dev/null <<'REPO'
[sokar]
name=Sokar
baseurl=https://fuinorg.jfrog.io/artifactory/sokar-dist-rpm/releases
enabled=1
gpgcheck=0
REPO
sudo dnf install sokar-frontend
```

Artifactory signs the repository's index, not each package, so there is no package signature to
check. Sokar itself is recommended, not required: the interface is as useful for machines reached
over ssh.

## First steps

1. **Start it**: *Sokar* among the desktop's applications. It shows this computer's Sokar, if one is
   installed, and every machine added before.
2. **Add a machine** with *Watch another machine…* in the title bar: one whose socket is forwarded
   already, one reached over ssh, where the interface raises the forward itself, or **a new machine
   just rented**, which a wizard prepares end to end, showing every command before it runs it and
   using root only for setting up.
3. **Add your forge** under *Forges*, with a token, so a repository can be picked rather than typed.
4. **Start work** with *New work* on *Work*: a machine and a repository. Without a project it runs
   with the machine's own settings. The first time, the agent asks you to sign in; the sign-in is
   kept in the machine's vault.
5. **Review what the agent did**: what it changed, the most far-reaching first, and what it was
   asked. Forward it to the repository's origin, or drop it.
6. **Follow a project** under *Projects* when work needs settings of its own: a repository holding a
   `project.yml`, whose settings are changed in that repository.

*Needs you* lists everything a person has to answer, on every machine, the most urgent first.

## More

- [Building it and working on it](https://github.com/sokar-ai/sokar-frontend/blob/main/build.md)
- [The backend API](https://github.com/sokar-ai/sokar-frontend/blob/main/doc/Backend-API.md): how a client talks to Sokar
- [Decisions](https://github.com/sokar-ai/sokar-frontend/blob/main/doc/decisions.md): what holds, and what it costs
- [Requirements](https://github.com/sokar-ai/sokar-frontend/blob/main/issues/README.md): what is still to do

## Licence

GNU General Public License, version 3 only (`GPL-3.0-only`), the same as the rest of Sokar. The
full text is in [`LICENSE`](https://github.com/sokar-ai/sokar-frontend/blob/main/LICENSE), and every package installs it beside the program.

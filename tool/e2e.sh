#!/usr/bin/env bash
# Runs the GUI integration tests against a real Sokar machine.
#
#   SOKAR_E2E_HOST=claude@192.168.122.174 \
#   SOKAR_E2E_REMOTE_SOCKET=/run/user/1001/sokar/sokard.sock \
#   SOKAR_E2E_KEY=~/.claude/.ssh/claude_key \
#   tool/e2e.sh [integration_test/connecting_test.dart]
#
# The app gets a config and runtime directory of its own and ssh a private agent holding only that
# key, so a running interface, its settings and the person's ssh setup are all left alone.
set -euo pipefail
: "${SOKAR_E2E_HOST:?name the machine as ssh would, e.g. user@host}"
: "${SOKAR_E2E_REMOTE_SOCKET:?the daemon socket on that machine}"

here=$(mktemp -d)
agent=''
cleanup() {
  if [ -n "$agent" ]; then kill "$agent" 2>/dev/null || true; fi
  rm -rf "$here"
}
trap cleanup EXIT
mkdir -p "$here/run" "$here/config"
chmod 700 "$here/run"

if [ -n "${SOKAR_E2E_KEY:-}" ]; then
  eval "$(ssh-agent -s -a "$here/agent.sock")" >/dev/null
  agent=$SSH_AGENT_PID
  ssh-add -q "${SOKAR_E2E_KEY/#\~/$HOME}"
fi

# Headless only: a test window on somebody's desktop takes their keyboard mid-sentence.
command -v xvfb-run >/dev/null || { echo "xvfb-run is missing: sudo apt install xvfb" >&2; exit 1; }
unset WAYLAND_DISPLAY
export GDK_BACKEND=x11 XDG_RUNTIME_DIR="$here/run" XDG_CONFIG_HOME="$here/config"

# Options pass through (CI adds --machine); the target is added when none was named, or
# flutter would run `test/` instead.
target=integration_test
for argument in "$@"; do
  case "$argument" in -*) ;; *) target='' ;; esac
done
xvfb-run -a -s '-screen 0 1280x800x24' flutter test -d linux "$@" $target

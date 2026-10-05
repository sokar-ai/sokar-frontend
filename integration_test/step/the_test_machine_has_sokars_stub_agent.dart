import 'package:flutter_test/flutter_test.dart';

import '../support/remote.dart';

/// Usage: the test machine has Sokar's stub agent
///
/// Sokar's own test agent, the only one that ends by its provider's refusal without a real key. Where
/// the account lacks it, it is fetched from the machine's own Sokar source and put into the account,
/// with nothing that needs root: `apt-get download`, or, where the machine's package lists are older
/// than the stub, the newest stub in that source's own index. Where it cannot be had, the scenario
/// fails here, saying so.
Future<void> theTestMachineHasSokarsStubAgent(WidgetTester tester) => onTheTestMachine(r'''
set -eu
PATH="$HOME/.local/bin:$PATH"
has() { sokar agents | awk 'NR > 1 {print $1}' | grep -qx stub; }
if ! has; then
  d=$(mktemp -d)
  trap 'rm -rf "$d"' EXIT
  if ! (cd "$d" && apt-get download sokar-agent-stub >/dev/null 2>&1); then
    set -- $(grep -rhE '^deb .*sokar-dist-deb' /etc/apt/sources.list /etc/apt/sources.list.d/ 2>/dev/null \
      | sed -E 's/\[[^]]*\] //' | head -1)
    base=${2:-}; suite=${3:-}
    test -n "$base" || { echo "this machine has no Sokar source to fetch sokar-agent-stub from" >&2; exit 1; }
    file=$(curl -fsSL "$base/dists/$suite/main/binary-amd64/Packages" \
      | awk '/^Package: /{p = ($2 == "sokar-agent-stub")} p && /^Filename: /{print $2}' | sort -V | tail -1)
    test -n "$file" || { echo "$base ($suite) offers no sokar-agent-stub" >&2; exit 1; }
    curl -fsSL -o "$d/sokar-agent-stub_fetched.deb" "$base/$file"
  fi
  dpkg-deb -x "$(ls "$d"/sokar-agent-stub_*.deb | head -1)" "$d/x"
  install -D -m 755 "$d/x/usr/libexec/sokar/agents/sokar-agent-stub" "$HOME/.local/share/sokar/agents/sokar-agent-stub"
fi
has || { echo "no agent called stub after installing it" >&2; exit 1; }
''');

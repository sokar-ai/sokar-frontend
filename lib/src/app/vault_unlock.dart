import 'connections.dart';
import 'machines.dart';

/// The line that opens [machine]'s vault in a terminal, or null where nothing here can reach it.
///
/// **The passphrase goes keyboard → terminal → ssh → sokar**, and this program never holds it: a
/// daemon has no terminal to take one at, so the terminal is the machine's own `sokar`. `ssh -t`
/// for a machine this interface reaches over ssh; the local daemon's own `sokar` for this one. A
/// socket somebody else forwarded has no host behind it, and running `sokar` here would open a
/// different vault from the one that machine uses — so it is not offered at all.
List<String>? unlockCommandFor(Machine machine) =>
    onTheMachine(machine, const <String>['sokar', 'vault', 'unlock'], terminal: true);

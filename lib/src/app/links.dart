import 'dart:io';

/// Opens an address in this desktop's browser. Injectable, so a test records what it would open.
typedef OpenLink = Future<void> Function(Uri address);

/// What opens a link here: the desktop's own opener, quiet where there is none.
OpenLink openLink = _withTheDesktop;

Future<void> _withTheDesktop(Uri address) async {
  try {
    await Process.start('xdg-open', <String>[address.toString()], mode: ProcessStartMode.detached);
  } on ProcessException {
    // No opener on this desktop; the address is on screen to be copied by hand.
  }
}

/// A web address a terminal's program marked as a link.
class TerminalLink {
  /// Constructor taking the address and whether the machine marked it as its login's page.
  const TerminalLink(this.address, {this.isTheLogin = false});

  final Uri address;

  /// Whether the machine marked it as its login's own page — the one whose reply comes back to the
  /// machine by itself (`id=sokar-login`). Read from the mark, never from the address.
  final bool isTheLogin;

  @override
  bool operator ==(Object other) =>
      other is TerminalLink && other.address == address && other.isTheLogin == isTheLogin;

  @override
  int get hashCode => Object.hash(address, isTheLogin);
}

/// The link an OSC 8 hyperlink carries, or null for the sequence that ends one, or for anything
/// that is not a web address — a terminal's link is never a way to run something here.
TerminalLink? hyperlinkOf(String code, List<String> arguments) {
  if (code != '8' || arguments.length < 2) return null;
  final address = Uri.tryParse(arguments.sublist(1).join(';'));
  if (address == null || !(address.isScheme('https') || address.isScheme('http'))) return null;
  // OSC 8's parameters are key=value pairs separated by colons.
  final marked = arguments.first.split(':').contains('id=sokar-login');
  return TerminalLink(address, isTheLogin: marked);
}

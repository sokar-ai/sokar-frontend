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

/// The address an OSC 8 hyperlink opens, or null for the sequence that ends one, or for anything
/// that is not a web address — a terminal's link is never a way to run something here.
Uri? hyperlinkOf(String code, List<String> arguments) {
  if (code != '8' || arguments.length < 2) return null;
  final address = Uri.tryParse(arguments.sublist(1).join(';'));
  if (address == null || !(address.isScheme('https') || address.isScheme('http'))) return null;
  return address;
}

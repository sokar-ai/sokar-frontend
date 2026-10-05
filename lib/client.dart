/// The Sokar backend, typed.
///
/// Everything the interface does goes through here. Nothing else in this application may open a
/// socket, and nothing anywhere may run the `sokar` CLI.
library;

export 'src/client/models.dart';
export 'src/client/sokar_client.dart';
export 'src/wire/varlink_connection.dart';
export 'src/wire/varlink_exception.dart';

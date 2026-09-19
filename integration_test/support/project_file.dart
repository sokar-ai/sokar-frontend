/// A project file `Follow` takes, for a project called [name].
///
/// **Measured, not guessed**: the file Agent Smith's acceptance legs followed and started a task in
/// on `snapshot.159`, six legs on Ubuntu and Fedora, 2026-09-19, with the second repository Agent
/// Sokar measured applying the same day — a work repository is not fetched by following, so it may
/// name a forge nobody can reach. Its `name` must be the one `Follow` is given.
String projectFile(String name) => '''
project:
  name: "$name"
  security_class: "guarded"
image:
  base_image: "ubuntu:24.04"
repositories:
  backend:
    upstream: "git@nowhere.invalid:acme/backend.git"''';

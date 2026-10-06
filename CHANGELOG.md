# Changelog

All notable changes to this project are recorded here.

The format is [Keep a Changelog 1.1.0](https://keepachangelog.com/en/1.1.0/), and this project
follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

Initial public version.

### Changed

- Every push checks with `sokar-release` that no page or source cites an issue, and that every page
  under `doc/` is in the site's navigation exactly once, and runs the tests that read a document;
  a push of documents alone runs only these and leases no machine.

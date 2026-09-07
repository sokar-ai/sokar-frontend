/// The numbers this interface is allowed to use.
///
/// Nothing outside this file may spell out a spacing, a width or a radius. A widget that writes
/// `EdgeInsets.all(16)` has made a decision this file was supposed to hold, and the next widget
/// makes a slightly different one — which is how an interface stops looking like one thing.
library;

/// Space between things, in logical pixels.
abstract final class Space {
  /// Hairline separation, inside a row.
  static const tight = 4.0;

  /// Between a mark and the words beside it.
  static const small = 8.0;

  /// Between rows, and inside a dense control.
  static const normal = 12.0;

  /// Inside a pane, around its content.
  static const wide = 16.0;

  /// Around something that stands on its own.
  static const loose = 24.0;
}

/// Fixed sizes that carry a decision rather than a measurement.
abstract final class Sizes {
  /// The projects column. Wide enough for a project name and its counts, no wider.
  static const projectsPane = 260.0;

  /// What is open, when there is room for it beside the work rather than over it.
  static const openedPane = 420.0;

  /// A mark saying whether something is running.
  static const mark = 16.0;

  /// The dot beside a task or a project.
  static const dot = 8.0;

  /// An icon inside a row.
  static const rowIcon = 18.0;
}

/// Corner radii.
abstract final class Radii {
  /// Inside a pane: a card, a summary, a block of output.
  static const small = 4.0;

  /// A card that stands on its own.
  static const medium = 8.0;
}

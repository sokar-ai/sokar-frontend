/// The numbers this interface is allowed to use.
///
/// Nothing outside this file may spell out a spacing, a width or a radius. A widget that writes
/// `EdgeInsets.all(16)` has made a decision this file was supposed to hold, and the next widget
/// makes a slightly different one — which is how an interface stops looking like one thing.
library;

import 'dart:ui' show Color;

/// Raw values, named for what they are rather than what they are for. Only the tokens below and
/// the theme read these; a widget reads the tokens.
abstract final class Primitives {
  /// The brand colour every other colour is worked out from, shared with melkheftken.
  static const Color brandIndigo600 = Color(0xFF3949AB);

  /// Four logical pixels.
  static const double space1 = 4;

  /// Eight logical pixels.
  static const double space2 = 8;

  /// Twelve logical pixels.
  static const double space3 = 12;

  /// Sixteen logical pixels.
  static const double space4 = 16;

  /// Twenty-four logical pixels.
  static const double space6 = 24;

  /// A small corner.
  static const double radiusSm = 4;

  /// A card's corner.
  static const double radiusMd = 8;
}

/// Space between things, in logical pixels.
abstract final class Space {
  /// Hairline separation, inside a row.
  static const tight = Primitives.space1;

  /// Between a mark and the words beside it.
  static const small = Primitives.space2;

  /// Between rows, and inside a dense control.
  static const normal = Primitives.space3;

  /// Inside a pane, around its content.
  static const wide = Primitives.space4;

  /// Around something that stands on its own.
  static const loose = Primitives.space6;
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

  /// A dialog that asks several things at once, wide enough for a URL or a key on one line.
  static const dialog = 620.0;

  /// A terminal inside a dialog: enough rows for a prompt, an answer and what came of it.
  static const terminal = 240.0;
}

/// Corner radii.
abstract final class Radii {
  /// Inside a pane: a card, a summary, a block of output.
  static const small = Primitives.radiusSm;

  /// A card that stands on its own.
  static const medium = Primitives.radiusMd;
}

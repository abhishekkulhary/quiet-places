import 'package:flutter/material.dart';

/// Design tokens for the "Radius" direction.
///
/// Every colour, space, radius, duration and type style in the app resolves
/// from here — widgets must not hardcode values. The concept is the circle: the
/// radius dial is the hero, geometry is concentric, type is set large and tight,
/// and a single electric accent carries all the meaning.

// ---------------------------------------------------------------------------
// Colour
// ---------------------------------------------------------------------------

/// Raw palette. Prefer the semantic [ColorScheme] in widgets; these exist so the
/// scheme and the custom accents below are defined in exactly one place.
abstract final class Palette {
  // Dark (the native state — this app lives in cinemas and meetings).
  static const ink = Color(0xFF0A0A0A); // page
  static const surface = Color(0xFF141414); // card
  static const surfaceHigh = Color(0xFF1F1F1F); // raised / pressed
  static const hairline = Color(0xFF2E2E2E);
  static const chalk = Color(0xFFF5F5F3); // primary text on dark
  static const chalkDim = Color(0xFFA0A09B); // secondary text on dark

  // Light.
  static const paper = Color(0xFFFFFFFF);
  static const paperShade = Color(0xFFF4F4F1);
  static const paperHigh = Color(0xFFEAEAE5);
  static const hairlineLight = Color(0xFFD8D8D2);

  /// Electric lime. ~15:1 on [ink]; always paired with [ink] as its foreground.
  static const lime = Color(0xFFC6F432);

  /// Lime is unreadable as text on white (~1.4:1), so light mode uses this
  /// darkened olive whenever the accent must be *text* rather than a fill.
  static const limeInk = Color(0xFF3D5200);

  /// Outline for markers drawn on top of map tiles.
  ///
  /// Deliberately theme-independent: OSM raster tiles are light in both light
  /// and dark mode, so a themed stroke would vanish against them in dark. This
  /// is the one place a fixed white is correct rather than lazy.
  static const mapMarkerStroke = Color(0xFFFFFFFF);

  static const danger = Color(0xFFFF5C4D);
  static const dangerInk = Color(0xFF8C1D12);
}

/// Accents that don't fit [ColorScheme]. Read via `Theme.of(context).extension`.
@immutable
class AppAccents extends ThemeExtension<AppAccents> {
  /// Accent safe to use as *text* on the page background.
  final Color accentInk;

  /// Ring/stroke colour for the concentric geometry.
  final Color ring;

  /// Subtle grid behind the radius dial.
  final Color grid;

  /// Glow used when a place is currently active/inside.
  final Color glow;

  const AppAccents({
    required this.accentInk,
    required this.ring,
    required this.grid,
    required this.glow,
  });

  static const dark = AppAccents(
    accentInk: Palette.lime,
    ring: Palette.lime,
    grid: Palette.hairline,
    glow: Palette.lime,
  );

  static const light = AppAccents(
    accentInk: Palette.limeInk,
    ring: Palette.limeInk,
    grid: Palette.hairlineLight,
    glow: Palette.limeInk,
  );

  @override
  AppAccents copyWith({
    Color? accentInk,
    Color? ring,
    Color? grid,
    Color? glow,
  }) =>
      AppAccents(
        accentInk: accentInk ?? this.accentInk,
        ring: ring ?? this.ring,
        grid: grid ?? this.grid,
        glow: glow ?? this.glow,
      );

  @override
  AppAccents lerp(covariant AppAccents? other, double t) {
    if (other == null) return this;
    return AppAccents(
      accentInk: Color.lerp(accentInk, other.accentInk, t)!,
      ring: Color.lerp(ring, other.ring, t)!,
      grid: Color.lerp(grid, other.grid, t)!,
      glow: Color.lerp(glow, other.glow, t)!,
    );
  }
}

// ---------------------------------------------------------------------------
// Space, geometry
// ---------------------------------------------------------------------------

abstract final class Space {
  static const xxs = 4.0;
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 48.0;

  /// Page gutter. Generous by design.
  static const gutter = 20.0;
}

abstract final class Radii {
  static const sm = 10.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const pill = 999.0;

  static const cardShape = BorderRadius.all(Radius.circular(md));
  static const sheetShape =
      BorderRadius.vertical(top: Radius.circular(lg));
}

/// Responsive breakpoints.
///
/// One number, used consistently: below it the app is a single column; at or
/// above it the list and the map sit side by side, which is the layout tablets
/// and unfolded foldables actually want.
abstract final class Breakpoints {
  /// Width at which a second pane becomes worthwhile.
  static const double twoPane = 720.0;

  /// Fixed width of the list pane in the two-pane layout; the map takes the
  /// rest, because a map benefits from extra width far more than a list does.
  static const double listPaneWidth = 420.0;

  static bool isWide(double width) => width >= twoPane;
}

/// How tall the editor's map/dial may be.
///
/// The map consumes vertical drag gestures, so if it fills the viewport the
/// page cannot be scrolled at all and everything below it becomes unreachable.
/// That is exactly what happened in landscape, where a 1.45 aspect ratio at
/// full width computes taller than the screen. The height is therefore capped
/// against the viewport as well as derived from the width.
double editorMapHeight({
  required double availableWidth,
  required Size viewport,
}) {
  const aspect = 1.45;
  final fromWidth = availableWidth / aspect;

  // Leave room for at least the name field and the save button below the fold
  // in landscape, where vertical space is scarce.
  final landscape = viewport.width > viewport.height;
  final cap = viewport.height * (landscape ? 0.55 : 0.45);

  // Never collapse to nothing on a very short viewport.
  return fromWidth.clamp(160.0, cap < 160.0 ? 160.0 : cap);
}

/// Minimum accessible hit target (Material spec is 48dp).
abstract final class Hit {
  static const min = 48.0;
}

/// Icon sizes. A closed set — the audit found eight different values in use,
/// which reads as carelessness at a glance even when no single one is wrong.
abstract final class IconSize {
  static const xs = 12.0;
  static const sm = 16.0;

  /// The default for inline and action icons.
  static const md = 20.0;
  static const lg = 24.0;

  /// Empty states and the silencing moment.
  static const hero = 40.0;
}

/// Fixed control dimensions, so buttons across screens agree.
abstract final class Sizes {
  /// Standard full-width action button.
  static const button = 58.0;

  /// The home screen's primary action, deliberately larger.
  static const buttonHero = 62.0;

  /// Floating circular action button.
  static const fab = 60.0;

  /// Bottom inset a scrollable needs so its last item can scroll clear of a
  /// floating action button rather than sitting under it.
  static const fabScrollInset = fab + Space.gutter * 2;

  /// Skeleton placeholder for a Quiet Place card.
  static const cardSkeleton = 84.0;

  /// Concentric dial badge on a card.
  static const dial = 52.0;

  /// Draggable map handles.
  static const mapHandle = 22.0;
}

/// Elevation as a surface + border system rather than drop shadows.
///
/// Dark mode uses surface tint and a hairline border to express height —
/// shadows are close to invisible on a near-black ground, so leaning on them
/// would make the dark theme read as flat boxes. Light mode adds a real but
/// restrained shadow, because there a tint alone is too subtle.
abstract final class Elevation {
  /// Flat on the page: banners, inline notices.
  static const int flat = 0;

  /// Cards and grouped settings.
  static const int raised = 1;

  /// Sheets, dialogs, menus.
  static const int floating = 2;

  /// Surface colour for a level, resolved from the scheme.
  static Color surfaceFor(ColorScheme scheme, int level) => switch (level) {
        floating => scheme.surfaceContainerHighest,
        raised => scheme.surfaceContainer,
        _ => scheme.surface,
      };

  /// Shadows are light-mode only; see the class doc.
  static List<BoxShadow> shadowFor(ColorScheme scheme, int level) {
    if (scheme.brightness == Brightness.dark || level == flat) return const [];
    final opacity = level == floating ? 0.10 : 0.05;
    final blur = level == floating ? 18.0 : 8.0;
    return [
      BoxShadow(
        color: Palette.ink.withValues(alpha: opacity),
        blurRadius: blur,
        offset: Offset(0, level == floating ? 6 : 2),
      ),
    ];
  }
}

abstract final class Strokes {
  static const hairline = 1.0;
  static const ring = 2.0;
  static const ringBold = 3.0;
}

// ---------------------------------------------------------------------------
// Motion
// ---------------------------------------------------------------------------

/// Motion choreography, so the app moves one way rather than six.
///
/// The rules, in order of how often they apply:
///
///  1. **Arrivals decelerate, departures are shorter.** Anything entering uses
///     [Motion.decelerate]; anything leaving is quicker, because waiting to
///     leave a screen feels slower than waiting to reach one.
///  2. **State changes are [Motion.base].** A card changing colour, a banner
///     appearing, a segment selecting.
///  3. **Direct manipulation is [Motion.fast] with [Motion.spring].** Press
///     feedback and the radius dial, where the finger is already moving and any
///     lag reads as lag.
///  4. **Only the signature moment is slow.** [Motion.moment] is reserved for
///     the phone going quiet; nothing else may take that long.
///  5. **Looping animation is decoration.** The shimmer and the inside-place
///     pulse are dropped entirely under reduced motion, not merely shortened.
///  6. **Everything routes through [Motion.of].** Including route transitions,
///     so switching reduced motion on genuinely stops the app moving.
abstract final class Motion {
  static const fast = Duration(milliseconds: 150);
  static const base = Duration(milliseconds: 220);
  static const slow = Duration(milliseconds: 320);

  /// The signature silencing animation.
  static const moment = Duration(milliseconds: 900);

  /// Looping shimmer on skeleton placeholders.
  static const shimmer = Duration(milliseconds: 1200);

  /// Slow breathing pulse on an active Quiet Place.
  static const pulse = Duration(milliseconds: 2600);

  /// How long an undo snackbar stays available.
  static const undoWindow = Duration(seconds: 5);

  /// Emphasised decelerate — the default for entrances and state changes.
  static const decelerate = Curves.easeOutCubic;

  /// Spring with a little overshoot, for the radius dial and press feedback.
  static const spring = Curves.easeOutBack;

  static const standard = Curves.easeInOutCubic;

  /// Collapses a duration to zero when the user has asked for reduced motion.
  ///
  /// Every animated widget in the app routes its duration through this, so
  /// "fully usable with all animation stripped out" is enforced in one place
  /// rather than remembered per widget.
  static Duration of(BuildContext context, Duration duration) =>
      MediaQuery.disableAnimationsOf(context) ? Duration.zero : duration;

  /// True when the user prefers reduced motion — use to skip looping or
  /// decorative animations entirely rather than merely shortening them.
  static bool reduced(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context);
}

// ---------------------------------------------------------------------------
// Type
// ---------------------------------------------------------------------------

abstract final class Fonts {
  static const display = 'Archivo';
  static const body = 'Inter';

  /// Archivo's width axis, pushed wide for the poster-like display treatment.
  static const expanded = [FontVariation('wdth', 118)];
  static const normalWidth = [FontVariation('wdth', 100)];
}

/// The type scale. Display sizes are deliberately large and tightly tracked;
/// numerals (radius, distance) use the expanded display face.
abstract final class AppType {
  static const _d = Fonts.display;
  static const _b = Fonts.body;

  static const displayLarge = TextStyle(
    fontFamily: _d,
    fontVariations: Fonts.expanded,
    fontSize: 44,
    height: 1.0,
    letterSpacing: -1.2,
    fontWeight: FontWeight.w700,
  );

  static const displayMedium = TextStyle(
    fontFamily: _d,
    fontVariations: Fonts.expanded,
    fontSize: 32,
    height: 1.05,
    letterSpacing: -0.8,
    fontWeight: FontWeight.w700,
  );

  /// QuietPlace names — the largest thing on a card.
  static const headline = TextStyle(
    fontFamily: _d,
    fontVariations: Fonts.expanded,
    fontSize: 26,
    height: 1.1,
    letterSpacing: -0.5,
    fontWeight: FontWeight.w600,
  );

  /// Big numerals (the radius dial).
  static const numeral = TextStyle(
    fontFamily: _d,
    fontVariations: Fonts.expanded,
    fontSize: 56,
    height: 1.0,
    letterSpacing: -2,
    fontWeight: FontWeight.w700,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static const title = TextStyle(
    fontFamily: _b,
    fontSize: 17,
    height: 1.3,
    fontWeight: FontWeight.w600,
  );

  static const body = TextStyle(
    fontFamily: _b,
    fontSize: 15,
    height: 1.45,
    fontWeight: FontWeight.w400,
  );

  static const bodySmall = TextStyle(
    fontFamily: _b,
    fontSize: 13,
    height: 1.4,
    fontWeight: FontWeight.w400,
  );

  /// All-caps micro label with wide tracking — the Swiss-poster detail.
  static const label = TextStyle(
    fontFamily: _b,
    fontSize: 11,
    height: 1.2,
    letterSpacing: 1.4,
    fontWeight: FontWeight.w600,
  );

  /// App bar / screen titles.
  static const screenTitle = TextStyle(
    fontFamily: _d,
    fontVariations: Fonts.expanded,
    fontSize: 24,
    height: 1.05,
    letterSpacing: -0.6,
    fontWeight: FontWeight.w700,
  );

  /// Slightly reduced headline, for dense cards.
  static const headlineSmall = TextStyle(
    fontFamily: _d,
    fontVariations: Fonts.expanded,
    fontSize: 22,
    height: 1.1,
    letterSpacing: -0.4,
    fontWeight: FontWeight.w600,
  );

  /// The all-caps label used on full-width buttons.
  static const buttonLabel = TextStyle(
    fontFamily: _b,
    fontSize: 13,
    height: 1.2,
    letterSpacing: 1.4,
    fontWeight: FontWeight.w600,
  );

  /// Smallest legible label — map attribution and similar fine print.
  static const micro = TextStyle(
    fontFamily: _b,
    fontSize: 10,
    height: 1.2,
    letterSpacing: 0.6,
    fontWeight: FontWeight.w500,
  );

  static const button = TextStyle(
    fontFamily: _b,
    fontSize: 15,
    height: 1.2,
    letterSpacing: 0.2,
    fontWeight: FontWeight.w600,
  );
}

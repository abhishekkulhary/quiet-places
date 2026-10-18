import 'package:flutter/material.dart';

import 'page_transitions.dart';
import 'tokens.dart';

/// Builds the Material 3 themes from [tokens.dart].
///
/// Dark is designed first and light is derived from it — not the other way
/// round — because the app is used in cinemas, meetings and theatres. The lime
/// accent is only ever a *fill* on light backgrounds; where the accent must be
/// text, [AppAccents.accentInk] supplies a contrast-safe variant.
abstract final class AppTheme {
  static ThemeData dark() {
    const scheme = ColorScheme.dark(
      primary: Palette.lime,
      onPrimary: Palette.ink,
      primaryContainer: Palette.lime,
      onPrimaryContainer: Palette.ink,
      secondary: Palette.chalk,
      onSecondary: Palette.ink,
      secondaryContainer: Palette.surfaceHigh,
      onSecondaryContainer: Palette.chalk,
      surface: Palette.ink,
      onSurface: Palette.chalk,
      surfaceContainer: Palette.surface,
      surfaceContainerHighest: Palette.surfaceHigh,
      onSurfaceVariant: Palette.chalkDim,
      outline: Palette.hairline,
      outlineVariant: Palette.hairline,
      error: Palette.danger,
      onError: Palette.ink,
      errorContainer: Color(0xFF2A100D),
      onErrorContainer: Palette.danger,
    );
    return _build(scheme, AppAccents.dark, Brightness.dark);
  }

  static ThemeData light() {
    const scheme = ColorScheme.light(
      primary: Palette.limeInk,
      onPrimary: Palette.paper,
      primaryContainer: Palette.lime,
      onPrimaryContainer: Palette.ink,
      secondary: Palette.ink,
      onSecondary: Palette.paper,
      secondaryContainer: Palette.paperHigh,
      onSecondaryContainer: Palette.ink,
      surface: Palette.paper,
      onSurface: Palette.ink,
      surfaceContainer: Palette.paperShade,
      surfaceContainerHighest: Palette.paperHigh,
      onSurfaceVariant: Color(0xFF5A5A55),
      outline: Palette.hairlineLight,
      outlineVariant: Palette.hairlineLight,
      error: Palette.dangerInk,
      onError: Palette.paper,
      errorContainer: Color(0xFFFFE5E2),
      onErrorContainer: Palette.dangerInk,
    );
    return _build(scheme, AppAccents.light, Brightness.light);
  }

  static ThemeData _build(
      ColorScheme scheme, AppAccents accents, Brightness brightness) {
    final textTheme = TextTheme(
      displayLarge: AppType.displayLarge.copyWith(color: scheme.onSurface),
      displayMedium: AppType.displayMedium.copyWith(color: scheme.onSurface),
      headlineMedium: AppType.headline.copyWith(color: scheme.onSurface),
      titleMedium: AppType.title.copyWith(color: scheme.onSurface),
      bodyMedium: AppType.body.copyWith(color: scheme.onSurface),
      bodySmall: AppType.bodySmall.copyWith(color: scheme.onSurfaceVariant),
      labelSmall: AppType.label.copyWith(color: scheme.onSurfaceVariant),
      labelLarge: AppType.button.copyWith(color: scheme.onSurface),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      // One motion language for navigation as well as for widgets.
      pageTransitionsTheme: quietPageTransitionsTheme,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      fontFamily: Fonts.body,
      textTheme: textTheme,
      extensions: [accents],
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppType.screenTitle.copyWith(color: scheme.onSurface),
        iconTheme: IconThemeData(color: scheme.onSurface),
      ),
      cardTheme: CardThemeData(
        color: scheme.surfaceContainer,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: const RoundedRectangleBorder(borderRadius: Radii.cardShape),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: Strokes.hairline,
        space: Strokes.hairline,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primaryContainer,
          foregroundColor: scheme.onPrimaryContainer,
          minimumSize: const Size(Hit.min, Hit.min),
          padding: const EdgeInsets.symmetric(
              horizontal: Space.lg, vertical: Space.md),
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(Radii.md))),
          textStyle: AppType.button,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accents.accentInk,
          minimumSize: const Size(Hit.min, Hit.min),
          textStyle: AppType.button,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.onSurface,
          minimumSize: const Size(Hit.min, Hit.min),
          side: BorderSide(color: scheme.outline, width: Strokes.hairline),
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(Radii.md))),
          textStyle: AppType.button,
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? scheme.onPrimary
                : scheme.onSurfaceVariant),
        trackColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? scheme.primary
                : scheme.surfaceContainerHighest),
        trackOutlineColor:
            WidgetStateProperty.all(scheme.outline),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: scheme.primary,
        inactiveTrackColor: scheme.surfaceContainerHighest,
        thumbColor: scheme.primary,
        overlayColor: scheme.primary.withValues(alpha: 0.14),
        trackHeight: 4,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surfaceContainerHighest,
        side: BorderSide(color: scheme.outline, width: Strokes.hairline),
        labelStyle: AppType.bodySmall.copyWith(color: scheme.onSurface),
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(Radii.pill))),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainer,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.md),
          borderSide: BorderSide(color: scheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.md),
          borderSide: BorderSide(color: scheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.md),
          borderSide: BorderSide(color: scheme.primary, width: Strokes.ring),
        ),
        labelStyle: AppType.bodySmall.copyWith(color: scheme.onSurfaceVariant),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: scheme.surfaceContainerHighest,
        contentTextStyle: AppType.body.copyWith(color: scheme.onSurface),
        actionTextColor: accents.accentInk,
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(Radii.md))),
insetPadding: const EdgeInsets.all(Space.md),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surfaceContainer,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: Radii.sheetShape),
      ),
      listTileTheme: const ListTileThemeData(
        minVerticalPadding: Space.sm,
        contentPadding: EdgeInsets.symmetric(
            horizontal: Space.gutter, vertical: Space.xxs),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          textStyle: WidgetStateProperty.all(AppType.button),
          minimumSize: WidgetStateProperty.all(const Size(0, Hit.min)),
        ),
      ),
    );
  }
}

/// Sugar for reading the custom accents.
extension AppAccentsX on BuildContext {
  AppAccents get accents =>
      Theme.of(this).extension<AppAccents>() ?? AppAccents.dark;
}

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// iOS / Apple Human Interface Guidelines system colors. Used as the
/// palette source for the whole app's [ThemeData] so every default Material
/// widget (AppBar, Card, Button, Switch, ...) already looks Apple-like
/// without per-screen overrides, and as the shared "pick a color" palette
/// offered for categories/accounts/persons/assets.
class AppleColors {
  AppleColors._();

  // System colors - light variant.
  static const blue = Color(0xFF007AFF);
  static const green = Color(0xFF34C759);
  static const red = Color(0xFFFF3B30);
  static const orange = Color(0xFFFF9500);
  static const yellow = Color(0xFFFFCC00);
  static const pink = Color(0xFFFF2D55);
  static const purple = Color(0xFFAF52DE);
  static const teal = Color(0xFF5AC8FA);
  static const indigo = Color(0xFF5856D6);
  static const brown = Color(0xFFA2845E);

  // System colors - dark variant (per HIG, slightly brighter/more saturated
  // so they hold up against a black background).
  static const blueDark = Color(0xFF0A84FF);
  static const greenDark = Color(0xFF30D158);
  static const redDark = Color(0xFFFF453A);
  static const orangeDark = Color(0xFFFF9F0A);
  static const yellowDark = Color(0xFFFFD60A);
  static const pinkDark = Color(0xFFFF375F);
  static const purpleDark = Color(0xFFBF5AF2);
  static const tealDark = Color(0xFF64D2FF);
  static const indigoDark = Color(0xFF5E5CE6);
  static const brownDark = Color(0xFFAC8E68);

  // Grays - same hex across light/dark per HIG (only their usage differs).
  static const gray = Color(0xFF8E8E93);
  static const gray2 = Color(0xFFAEAEB2);
  static const gray3 = Color(0xFFC7C7CC);
  static const gray4 = Color(0xFFD1D1D6);
  static const gray5 = Color(0xFFE5E5EA);
  static const gray6 = Color(0xFFF2F2F7);

  static const gray2Dark = Color(0xFF636366);
  static const gray3Dark = Color(0xFF48484A);
  static const gray4Dark = Color(0xFF3A3A3C);
  static const gray5Dark = Color(0xFF2C2C2E);
  static const gray6Dark = Color(0xFF1C1C1E);

  static const separatorLight = Color(0x4D3C3C43);
  static const separatorDark = Color(0x59545458);

  static const labelLight = Color(0xFF000000);
  static const secondaryLabelLight = Color(0x993C3C43);
  static const labelDark = Color(0xFFFFFFFF);
  static const secondaryLabelDark = Color(0x99EBEBF5);

  /// Distinguishable iOS system-color swatches for the color pickers used
  /// when creating/editing categories, accounts, persons, company cars and
  /// assets - replaces the previous ad-hoc Material color lists so every
  /// picker in the app offers the same, coherent palette.
  static const pickerPalette = [red, orange, yellow, green, teal, blue, indigo, purple, pink, brown, gray, gray2];
}

/// Corner-radius scale used consistently across cards, buttons, text
/// fields, dialogs and sheets - mirrors the rounded, soft-edged look of
/// iOS controls (which use much larger radii than Material's defaults).
class AppleRadii {
  AppleRadii._();

  static const small = 8.0;
  static const medium = 12.0;
  static const large = 16.0;
  static const xLarge = 20.0;
  static const pill = 999.0;
}

/// Semantic colors that don't map cleanly onto [ColorScheme]'s Material
/// roles (grouped-list backgrounds, hairline separators, positive/negative
/// amounts). Read via `Theme.of(context).extension<AppleSemantics>()!` so
/// screens don't need to re-derive brightness-dependent colors themselves.
class AppleSemantics extends ThemeExtension<AppleSemantics> {
  const AppleSemantics({
    required this.groupedBackground,
    required this.secondaryGroupedBackground,
    required this.separator,
    required this.label,
    required this.secondaryLabel,
    required this.success,
    required this.danger,
    required this.warning,
  });

  /// Page background behind grouped card sections (iOS "systemGroupedBackground").
  final Color groupedBackground;

  /// Card/row background sitting on top of [groupedBackground].
  final Color secondaryGroupedBackground;

  final Color separator;
  final Color label;
  final Color secondaryLabel;

  /// Positive amounts / income / on-target budgets.
  final Color success;

  /// Negative amounts / expenses / over-budget.
  final Color danger;

  /// Approaching-limit warnings.
  final Color warning;

  @override
  AppleSemantics copyWith({
    Color? groupedBackground,
    Color? secondaryGroupedBackground,
    Color? separator,
    Color? label,
    Color? secondaryLabel,
    Color? success,
    Color? danger,
    Color? warning,
  }) {
    return AppleSemantics(
      groupedBackground: groupedBackground ?? this.groupedBackground,
      secondaryGroupedBackground: secondaryGroupedBackground ?? this.secondaryGroupedBackground,
      separator: separator ?? this.separator,
      label: label ?? this.label,
      secondaryLabel: secondaryLabel ?? this.secondaryLabel,
      success: success ?? this.success,
      danger: danger ?? this.danger,
      warning: warning ?? this.warning,
    );
  }

  @override
  AppleSemantics lerp(ThemeExtension<AppleSemantics>? other, double t) {
    if (other is! AppleSemantics) return this;
    return AppleSemantics(
      groupedBackground: Color.lerp(groupedBackground, other.groupedBackground, t)!,
      secondaryGroupedBackground: Color.lerp(secondaryGroupedBackground, other.secondaryGroupedBackground, t)!,
      separator: Color.lerp(separator, other.separator, t)!,
      label: Color.lerp(label, other.label, t)!,
      secondaryLabel: Color.lerp(secondaryLabel, other.secondaryLabel, t)!,
      success: Color.lerp(success, other.success, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
    );
  }
}

extension AppleSemanticsContext on BuildContext {
  AppleSemantics get appleColors => Theme.of(this).extension<AppleSemantics>()!;
}

/// Builds the app's light/dark [ThemeData] with an Apple/iOS-inspired look:
/// system colors, HIG type scale, large corner radii, hairline separators
/// instead of Material elevation, and `platform: TargetPlatform.iOS` so
/// every adaptive widget (`Switch.adaptive`, `showAdaptiveDialog`, overscroll
/// behavior, ...) renders Cupertino-style on every platform this app ships
/// on - not just on an actual iPhone.
class AppTheme {
  AppTheme._();

  static ThemeData get light => _build(brightness: Brightness.light);
  static ThemeData get dark => _build(brightness: Brightness.dark);

  static ThemeData _build({required Brightness brightness}) {
    final isDark = brightness == Brightness.dark;

    final accent = isDark ? AppleColors.blueDark : AppleColors.blue;
    final groupedBackground = isDark ? Colors.black : AppleColors.gray6;
    final cardColor = isDark ? AppleColors.gray6Dark : Colors.white;
    final label = isDark ? AppleColors.labelDark : AppleColors.labelLight;
    final secondaryLabel = isDark ? AppleColors.secondaryLabelDark : AppleColors.secondaryLabelLight;
    final separator = isDark ? AppleColors.separatorDark : AppleColors.separatorLight;
    final fieldFill = isDark ? AppleColors.gray5Dark : AppleColors.gray6;

    final textTheme = _textTheme(label: label, secondaryLabel: secondaryLabel);

    final colorScheme = ColorScheme.fromSeed(seedColor: accent, brightness: brightness).copyWith(
      primary: accent,
      onPrimary: Colors.white,
      secondary: isDark ? AppleColors.indigoDark : AppleColors.indigo,
      error: isDark ? AppleColors.redDark : AppleColors.red,
      onError: Colors.white,
      surface: cardColor,
      onSurface: label,
      outline: separator,
      outlineVariant: separator,
    );

    final roundedMedium = RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppleRadii.medium));
    final roundedLarge = RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppleRadii.large), side: BorderSide(color: separator, width: 0.5));
    final roundedXLarge = RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppleRadii.xLarge));

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      platform: TargetPlatform.iOS,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: groupedBackground,
      canvasColor: groupedBackground,
      cardColor: cardColor,
      dividerColor: separator,
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      hoverColor: Colors.transparent,
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      pageTransitionsTheme: const PageTransitionsTheme(builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
        TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
        TargetPlatform.fuchsia: CupertinoPageTransitionsBuilder(),
      }),
      appBarTheme: AppBarTheme(
        backgroundColor: groupedBackground.withValues(alpha: 0.9),
        foregroundColor: label,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: textTheme.titleLarge,
        iconTheme: IconThemeData(color: accent),
        actionsIconTheme: IconThemeData(color: accent),
      ),
      cardTheme: CardThemeData(color: cardColor, elevation: 0, margin: EdgeInsets.zero, shape: roundedLarge),
      listTileTheme: ListTileThemeData(
        iconColor: accent,
        textColor: label,
        titleTextStyle: textTheme.bodyLarge,
        subtitleTextStyle: textTheme.bodyMedium?.copyWith(color: secondaryLabel),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppleRadii.medium)),
      ),
      dividerTheme: DividerThemeData(color: separator, thickness: 0.5, space: 0.5),
      switchTheme: SwitchThemeData(
        thumbColor: const WidgetStatePropertyAll(Colors.white),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? (isDark ? AppleColors.greenDark : AppleColors.green) : (isDark ? AppleColors.gray4Dark : AppleColors.gray4),
        ),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          disabledBackgroundColor: isDark ? AppleColors.gray4Dark : AppleColors.gray4,
          shape: roundedMedium,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: textTheme.labelLarge,
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: accent,
          side: BorderSide(color: separator),
          shape: roundedMedium,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: accent, textStyle: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
      ),
      iconButtonTheme: IconButtonThemeData(style: IconButton.styleFrom(foregroundColor: accent)),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accent,
        foregroundColor: Colors.white,
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppleRadii.xLarge)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: fieldFill,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppleRadii.medium), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppleRadii.medium), borderSide: BorderSide.none),
        disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppleRadii.medium), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppleRadii.medium), borderSide: BorderSide(color: accent, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppleRadii.medium), borderSide: BorderSide(color: colorScheme.error, width: 1)),
        labelStyle: TextStyle(color: secondaryLabel),
        hintStyle: TextStyle(color: secondaryLabel),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: cardColor,
        surfaceTintColor: Colors.transparent,
        shape: roundedXLarge,
        titleTextStyle: textTheme.headlineLarge,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: secondaryLabel),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: cardColor,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: separator,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppleRadii.xLarge))),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? AppleColors.gray4Dark : AppleColors.gray2,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: roundedMedium,
      ),
      popupMenuTheme: PopupMenuThemeData(color: cardColor, surfaceTintColor: Colors.transparent, shape: roundedMedium, textStyle: textTheme.bodyLarge),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: cardColor.withValues(alpha: 0.92),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 58,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 11,
            fontWeight: states.contains(WidgetState.selected) ? FontWeight.w600 : FontWeight.w400,
            color: states.contains(WidgetState.selected) ? accent : secondaryLabel,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(color: states.contains(WidgetState.selected) ? accent : secondaryLabel, size: 24),
        ),
        indicatorColor: Colors.transparent,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: cardColor,
        selectedIconTheme: IconThemeData(color: accent),
        unselectedIconTheme: IconThemeData(color: secondaryLabel),
        selectedLabelTextStyle: TextStyle(color: accent, fontWeight: FontWeight.w600, fontSize: 12),
        unselectedLabelTextStyle: TextStyle(color: secondaryLabel, fontSize: 12),
        indicatorColor: Colors.transparent,
      ),
      iconTheme: IconThemeData(color: label),
      chipTheme: ChipThemeData(
        backgroundColor: fieldFill,
        labelStyle: textTheme.bodyMedium,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppleRadii.pill)),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: accent),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          backgroundColor: fieldFill,
          foregroundColor: secondaryLabel,
          selectedBackgroundColor: accent,
          selectedForegroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppleRadii.medium)),
          side: BorderSide.none,
        ),
      ),
      extensions: [
        AppleSemantics(
          groupedBackground: groupedBackground,
          secondaryGroupedBackground: cardColor,
          separator: separator,
          label: label,
          secondaryLabel: secondaryLabel,
          success: isDark ? AppleColors.greenDark : AppleColors.green,
          danger: isDark ? AppleColors.redDark : AppleColors.red,
          warning: isDark ? AppleColors.orangeDark : AppleColors.orange,
        ),
      ],
    );
  }

  /// iOS Human Interface Guidelines type scale (San Francisco), mapped onto
  /// Material 3's [TextTheme] roles. The exact San Francisco font can't be
  /// bundled here (Apple-licensed, and this environment can't fetch fonts
  /// over the network), so sizes/weights/letter-spacing carry the "Apple"
  /// feel on top of each platform's default system font instead.
  static TextTheme _textTheme({required Color label, required Color secondaryLabel}) {
    return TextTheme(
      displayLarge: TextStyle(fontSize: 34, fontWeight: FontWeight.w700, letterSpacing: 0.4, height: 1.1, color: label),
      displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: 0.36, height: 1.15, color: label),
      displaySmall: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: 0.35, height: 1.2, color: label),
      headlineLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, letterSpacing: 0.38, color: label),
      headlineMedium: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, letterSpacing: -0.41, color: label),
      headlineSmall: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, letterSpacing: -0.41, color: label),
      titleLarge: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, letterSpacing: -0.41, color: label),
      titleMedium: TextStyle(fontSize: 17, fontWeight: FontWeight.w500, letterSpacing: -0.41, color: label),
      titleSmall: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: -0.24, color: label),
      bodyLarge: TextStyle(fontSize: 17, fontWeight: FontWeight.w400, letterSpacing: -0.41, color: label),
      bodyMedium: TextStyle(fontSize: 15, fontWeight: FontWeight.w400, letterSpacing: -0.24, color: secondaryLabel),
      bodySmall: TextStyle(fontSize: 13, fontWeight: FontWeight.w400, letterSpacing: -0.08, color: secondaryLabel),
      labelLarge: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, letterSpacing: -0.41, color: label),
      labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0, color: secondaryLabel),
      labelSmall: TextStyle(fontSize: 11, fontWeight: FontWeight.w400, letterSpacing: 0.07, color: secondaryLabel),
    );
  }
}

import 'package:flutter/material.dart';

const inspectionJet = Color(0xff050505);
const cameraGround = inspectionJet;
const inspectionViolet = Color(0xff3b0a6b);
const inspectionCyan = Color(0xff00e5ff);

BoxDecoration inspectionBackdrop(ColorScheme colors) => BoxDecoration(
      color: colors.surface,
      gradient: RadialGradient(
        center: Alignment.topRight,
        radius: 1.25,
        colors: [
          colors.brightness == Brightness.dark
              ? const Color(0xff250c3e)
              : const Color(0xfff1eaff),
          colors.surface,
        ],
        stops: const [0, .72],
      ),
    );
ThemeData inspectionTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final ink = dark ? Colors.white : Colors.black;
  final ground = dark ? inspectionJet : Colors.white;
  final c = ColorScheme(
      brightness: brightness,
      primary: inspectionViolet,
      onPrimary: Colors.white,
      secondary: dark ? inspectionCyan : inspectionViolet,
      onSecondary: ground,
      error: ink,
      onError: ground,
      surface: ground,
      onSurface: ink,
      surfaceContainerLowest: ground,
      surfaceContainerLow: ground,
      surfaceContainer: ground,
      surfaceContainerHigh: ground,
      surfaceContainerHighest: ink,
      onSurfaceVariant: ink,
      outline: ink,
      outlineVariant: ink,
      primaryContainer: inspectionViolet,
      onPrimaryContainer: Colors.white,
      secondaryContainer: ground,
      onSecondaryContainer: ink,
      tertiary: ink,
      onTertiary: ground,
      tertiaryContainer: ground,
      onTertiaryContainer: ink,
      errorContainer: ground,
      onErrorContainer: ink,
      inverseSurface: ink,
      onInverseSurface: ground,
      inversePrimary: ground,
      surfaceTint: Colors.transparent);
  const family = 'packages/inspection_ui/InspectionSans';
  final base = ThemeData(useMaterial3: true, colorScheme: c);
  return base.copyWith(
      scaffoldBackgroundColor: ground,
      progressIndicatorTheme: ProgressIndicatorThemeData(color: c.secondary),
      textTheme: base.textTheme.apply(fontFamily: family, bodyColor: ink, displayColor: ink).copyWith(
          headlineSmall: TextStyle(
              fontFamily: family,
              fontSize: 32,
              height: 1.12,
              fontWeight: FontWeight.w700,
              letterSpacing: -.5,
              color: ink),
          titleLarge: TextStyle(
              fontFamily: family,
              fontSize: 24,
              height: 1.2,
              fontWeight: FontWeight.w700,
              color: ink),
          titleMedium: TextStyle(
              fontFamily: family,
              fontSize: 20,
              height: 1.3,
              fontWeight: FontWeight.w500,
              color: ink),
          titleSmall: TextStyle(
              fontFamily: family,
              fontSize: 18,
              height: 1.35,
              fontWeight: FontWeight.w500,
              color: ink),
          bodyLarge: TextStyle(
              fontFamily: family, fontSize: 18, height: 1.45, color: ink),
          bodyMedium: TextStyle(
              fontFamily: family, fontSize: 18, height: 1.45, color: ink),
          bodySmall: TextStyle(
              fontFamily: family, fontSize: 18, height: 1.4, color: ink)),
      appBarTheme: AppBarTheme(
          backgroundColor: ground,
          foregroundColor: ink,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false),
      navigationBarTheme: NavigationBarThemeData(
          backgroundColor: ground,
          indicatorColor: c.primaryContainer,
          elevation: 0,
          iconTheme: WidgetStateProperty.resolveWith((s) => IconThemeData(
              color: s.contains(WidgetState.selected)
                  ? c.onPrimaryContainer
                  : ink)),
          labelTextStyle: WidgetStatePropertyAll(TextStyle(
              fontFamily: family,
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: ink))),
      navigationRailTheme: NavigationRailThemeData(
          backgroundColor: ground,
          indicatorColor: c.primaryContainer,
          selectedIconTheme: IconThemeData(color: c.onPrimaryContainer),
          unselectedIconTheme: IconThemeData(color: ink)),
      filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(minimumSize: const Size(48, 60), backgroundColor: c.primary, foregroundColor: c.onPrimary, disabledBackgroundColor: ground, disabledForegroundColor: ink, side: BorderSide(color: c.secondary), textStyle: const TextStyle(fontFamily: family, fontSize: 18, fontWeight: FontWeight.w500), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), elevation: 0)),
      outlinedButtonTheme: OutlinedButtonThemeData(style: OutlinedButton.styleFrom(minimumSize: const Size(48, 56), foregroundColor: ink, side: BorderSide(color: ink))),
      iconButtonTheme: IconButtonThemeData(style: IconButton.styleFrom(minimumSize: const Size(48, 48), foregroundColor: ink)),
      segmentedButtonTheme: SegmentedButtonThemeData(style: ButtonStyle(minimumSize: const WidgetStatePropertyAll(Size(48, 54)), textStyle: const WidgetStatePropertyAll(TextStyle(fontFamily: family, fontSize: 18, fontWeight: FontWeight.w500)), foregroundColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? c.onPrimaryContainer : ink), backgroundColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? c.primaryContainer : ground), side: WidgetStatePropertyAll(BorderSide(color: c.secondary)), shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))))),
      dividerTheme: DividerThemeData(color: ink, space: 1));
}

extension InspectionColors on ColorScheme {
  Color get good => onSurface;
  Color get bad => onSurface;
  Color get caution => onSurface;
  Color get goodSurface => surface;
  Color get badSurface => surface;
  Color get cautionSurface => surface;
}

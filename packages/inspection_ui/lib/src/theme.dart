import 'package:flutter/material.dart';

const cameraGround = Colors.black;
ThemeData inspectionTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final ink = dark ? Colors.white : Colors.black;
  final ground = dark ? Colors.black : Colors.white;
  final c = ColorScheme(
      brightness: brightness,
      primary: ink,
      onPrimary: ground,
      secondary: ink,
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
      primaryContainer: ground,
      onPrimaryContainer: ink,
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
      textTheme: base.textTheme
          .apply(fontFamily: family, bodyColor: ink, displayColor: ink)
          .copyWith(
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
          indicatorColor: ink,
          elevation: 0,
          iconTheme: WidgetStateProperty.resolveWith((s) => IconThemeData(
              color: s.contains(WidgetState.selected) ? ground : ink)),
          labelTextStyle: WidgetStatePropertyAll(TextStyle(
              fontFamily: family,
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: ink))),
      navigationRailTheme: NavigationRailThemeData(
          backgroundColor: ground,
          indicatorColor: ink,
          selectedIconTheme: IconThemeData(color: ground),
          unselectedIconTheme: IconThemeData(color: ink)),
      filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(minimumSize: const Size(48, 60), backgroundColor: ink, foregroundColor: ground, disabledBackgroundColor: ground, disabledForegroundColor: ink, side: BorderSide(color: ink), textStyle: const TextStyle(fontFamily: family, fontSize: 18, fontWeight: FontWeight.w500), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), elevation: 0)),
      outlinedButtonTheme: OutlinedButtonThemeData(style: OutlinedButton.styleFrom(minimumSize: const Size(48, 56), foregroundColor: ink, side: BorderSide(color: ink))),
      iconButtonTheme: IconButtonThemeData(style: IconButton.styleFrom(minimumSize: const Size(48, 48), foregroundColor: ink)),
      segmentedButtonTheme: SegmentedButtonThemeData(style: ButtonStyle(minimumSize: const WidgetStatePropertyAll(Size(48, 54)), textStyle: const WidgetStatePropertyAll(TextStyle(fontFamily: family, fontSize: 18, fontWeight: FontWeight.w500)), foregroundColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? ground : ink), backgroundColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? ink : ground), side: WidgetStatePropertyAll(BorderSide(color: ink)), shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))))),
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

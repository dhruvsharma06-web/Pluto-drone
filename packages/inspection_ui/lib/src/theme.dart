import 'package:flutter/material.dart';

const inspectionBlue = Color(0xff1259d9);
const cameraGround = Color(0xff141719);

ThemeData inspectionTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final c = ColorScheme.fromSeed(
    seedColor: inspectionBlue,
    brightness: brightness,
  ).copyWith(
    primary: dark ? const Color(0xff70b8ff) : inspectionBlue,
    onPrimary: dark ? const Color(0xff071c2b) : Colors.white,
    surface: dark ? const Color(0xff0e1216) : const Color(0xfff2f5f8),
    onSurface: dark ? const Color(0xfff1f2f4) : const Color(0xff182026),
    onSurfaceVariant: dark ? const Color(0xffb9c0c8) : const Color(0xff53606d),
    surfaceContainerLowest: dark ? const Color(0xff141a20) : Colors.white,
    surfaceContainerLow:
        dark ? const Color(0xff1c252d) : const Color(0xfff7f9fb),
    surfaceContainer: dark ? const Color(0xff23313b) : const Color(0xffe9eef4),
    surfaceContainerHighest:
        dark ? const Color(0xff2d3c48) : const Color(0xffdde5ee),
    outlineVariant: dark ? const Color(0xff3b4148) : const Color(0xffdce3ea),
  );
  final base = ThemeData(useMaterial3: true, colorScheme: c);
  const family = 'packages/inspection_ui/InspectionSans';
  return base.copyWith(
    scaffoldBackgroundColor: c.surface,
    textTheme: base.textTheme
        .apply(
          fontFamily: family,
          bodyColor: c.onSurface,
          displayColor: c.onSurface,
        )
        .copyWith(
          headlineSmall: TextStyle(
            fontFamily: family,
            fontSize: 28,
            height: 1.18,
            fontWeight: FontWeight.w700,
            letterSpacing: -.4,
            color: c.onSurface,
          ),
          titleLarge: TextStyle(
            fontFamily: family,
            fontSize: 22,
            height: 1.2,
            fontWeight: FontWeight.w700,
            letterSpacing: -.3,
            color: c.onSurface,
          ),
        ),
    appBarTheme: AppBarTheme(
      backgroundColor: c.surface,
      foregroundColor: c.onSurface,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: c.surfaceContainerLowest,
      indicatorColor: c.surfaceContainerHighest,
      elevation: 0,
      labelTextStyle: WidgetStatePropertyAll(
        TextStyle(
          fontFamily: family,
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: c.onSurface,
        ),
      ),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: c.surface,
      indicatorColor: c.surfaceContainerHighest,
      selectedIconTheme: IconThemeData(color: c.onSurface),
      unselectedIconTheme: IconThemeData(color: c.onSurfaceVariant),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 56),
        elevation: 0,
        textStyle: const TextStyle(
          fontFamily: family,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        disabledBackgroundColor: c.surfaceContainerHighest,
        disabledForegroundColor: c.onSurfaceVariant,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
        foregroundColor: WidgetStatePropertyAll(c.onSurface),
        backgroundColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? c.surfaceContainerHighest
              : c.surfaceContainerLowest,
        ),
        side: WidgetStatePropertyAll(BorderSide(color: c.outlineVariant)),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    ),
    dividerTheme: DividerThemeData(color: c.outlineVariant, space: 1),
  );
}

extension InspectionColors on ColorScheme {
  Color get good => brightness == Brightness.dark
      ? const Color(0xff89d9ac)
      : const Color(0xff17643f);
  Color get goodSurface => brightness == Brightness.dark
      ? const Color(0xff183529)
      : const Color(0xffe6f5ec);
  Color get bad => brightness == Brightness.dark
      ? const Color(0xffffb4a9)
      : const Color(0xffa8271f);
  Color get badSurface => brightness == Brightness.dark
      ? const Color(0xff42231f)
      : const Color(0xffffede9);
  Color get caution => brightness == Brightness.dark
      ? const Color(0xffffd68b)
      : const Color(0xff775000);
  Color get cautionSurface => brightness == Brightness.dark
      ? const Color(0xff3b3020)
      : const Color(0xfffff3d8);
}

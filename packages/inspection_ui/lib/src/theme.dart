import 'package:flutter/material.dart';

const inspectionControlHeight = 52.0;
const inspectionSurfaceRadius = 20.0;

const inspectionGround = Color(0xff050505);
const inspectionInk = Color(0xfff3f0f7);
const inspectionMuted = Color(0xffa49cb2);
const inspectionAccent = Color(0xff8a5cd6);
const inspectionTextAccent = Color(0xff7a4fc4);
const inspectionLightPurple = Color(0xffb79cf0);
const inspectionLine = Color(0x24f3f0f7);
const cameraGround = inspectionGround;
const inspectionSans = 'packages/inspection_ui/InspectionSans';
const inspectionDisplay = 'packages/inspection_ui/InspectionDisplay';

// The supplied identity stays dark even when the OS uses a light theme.
ThemeData inspectionTheme(Brightness brightness) {
  const c = ColorScheme.dark(
    primary: inspectionInk,
    onPrimary: inspectionGround,
    primaryContainer: Color(0xff3b0a6b),
    onPrimaryContainer: inspectionInk,
    secondary: inspectionAccent,
    onSecondary: inspectionGround,
    secondaryContainer: Color(0xff3b0a6b),
    onSecondaryContainer: inspectionInk,
    tertiary: inspectionLightPurple,
    onTertiary: inspectionGround,
    tertiaryContainer: Color(0xff3b0a6b),
    onTertiaryContainer: inspectionInk,
    error: inspectionLightPurple,
    onError: inspectionGround,
    errorContainer: Color(0xff201629),
    onErrorContainer: inspectionInk,
    surface: inspectionGround,
    onSurface: inspectionInk,
    onSurfaceVariant: inspectionMuted,
    outline: inspectionMuted,
    outlineVariant: inspectionLine,
    surfaceContainerLowest: inspectionGround,
    surfaceContainerLow: inspectionGround,
    surfaceContainer: Color(0xff111014),
    surfaceContainerHigh: Color(0xff18161c),
    surfaceContainerHighest: Color(0xff242029),
    inverseSurface: inspectionInk,
    onInverseSurface: inspectionGround,
    inversePrimary: Color(0xff3b0a6b),
    surfaceTint: Colors.transparent,
  );
  final base =
      ThemeData(useMaterial3: true, colorScheme: c, fontFamily: inspectionSans);
  TextStyle type(double size, [FontWeight weight = FontWeight.w400]) =>
      TextStyle(
          fontFamily: inspectionSans,
          fontSize: size,
          height: 1.4,
          fontWeight: weight,
          color: inspectionInk);
  final focusSide = WidgetStateProperty.resolveWith<BorderSide>((states) =>
      states.contains(WidgetState.focused)
          ? const BorderSide(color: inspectionAccent, width: 2)
          : BorderSide.none);
  final action = ButtonStyle(
    minimumSize:
        const WidgetStatePropertyAll(Size(48, inspectionControlHeight)),
    padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
    textStyle: WidgetStatePropertyAll(type(16, FontWeight.w500)),
    shape: const WidgetStatePropertyAll(StadiumBorder()),
    side: focusSide,
    foregroundBuilder: (context, states, child) => AnimatedScale(
        scale: states.contains(WidgetState.pressed) &&
                !MediaQuery.disableAnimationsOf(context)
            ? .97
            : 1,
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 120),
        child: child),
    overlayColor: WidgetStateProperty.resolveWith((s) =>
        s.contains(WidgetState.pressed) || s.contains(WidgetState.hovered)
            ? inspectionLightPurple.withValues(alpha: .25)
            : null),
  );
  return base.copyWith(
    scaffoldBackgroundColor: inspectionGround,
    focusColor: inspectionAccent.withValues(alpha: .3),
    textTheme: base.textTheme.copyWith(
      headlineSmall: const TextStyle(
          fontFamily: inspectionSans,
          fontSize: 28,
          height: 1.2,
          fontWeight: FontWeight.w500,
          color: inspectionInk),
      titleLarge: type(22, FontWeight.w500),
      titleMedium: type(20, FontWeight.w500),
      titleSmall: type(16, FontWeight.w500),
      bodyLarge: type(17),
      bodyMedium: type(16),
      bodySmall: type(15),
      labelLarge: type(16, FontWeight.w500),
      labelMedium: type(15, FontWeight.w500),
      labelSmall: type(14),
    ),
    appBarTheme: AppBarTheme(
        backgroundColor: inspectionGround,
        foregroundColor: inspectionInk,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: type(18, FontWeight.w500)),
    navigationBarTheme: NavigationBarThemeData(
        backgroundColor: inspectionGround,
        indicatorColor: const Color(0xff242029),
        elevation: 0,
        labelTextStyle: WidgetStatePropertyAll(type(14, FontWeight.w500))),
    navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: inspectionGround,
        indicatorColor: Color(0xff242029),
        selectedIconTheme: IconThemeData(color: inspectionAccent),
        unselectedIconTheme: IconThemeData(color: inspectionMuted)),
    filledButtonTheme: FilledButtonThemeData(
        style: action.copyWith(
      backgroundColor: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.disabled)
              ? const Color(0xff242029)
              : inspectionInk),
      foregroundColor: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.disabled)
              ? inspectionMuted
              : inspectionGround),
    )),
    textButtonTheme: TextButtonThemeData(
        style: action.copyWith(
            foregroundColor: const WidgetStatePropertyAll(inspectionInk))),
    outlinedButtonTheme: OutlinedButtonThemeData(style: action),
    iconButtonTheme: IconButtonThemeData(
        style: action.copyWith(
            minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
            padding: const WidgetStatePropertyAll(EdgeInsets.all(12)))),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? inspectionInk : null),
      checkColor: const WidgetStatePropertyAll(inspectionGround),
      side: const BorderSide(color: inspectionMuted, width: 2),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
        style: action.copyWith(
      foregroundBuilder: (context, states, child) =>
          child ?? const SizedBox.shrink(),
      padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 8, vertical: 12)),
      foregroundColor: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.selected)
              ? inspectionGround
              : inspectionMuted),
      backgroundColor: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.selected) ? inspectionInk : inspectionGround),
      side: WidgetStateProperty.resolveWith((s) => BorderSide(
          color: s.contains(WidgetState.focused)
              ? inspectionAccent
              : inspectionLine,
          width: s.contains(WidgetState.focused) ? 2 : 1)),
    )),
    progressIndicatorTheme:
        const ProgressIndicatorThemeData(color: inspectionAccent),
    bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: inspectionGround,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            side: BorderSide(color: inspectionLine))),
    dividerTheme: const DividerThemeData(color: inspectionLine, space: 1),
  );
}

extension InspectionColors on ColorScheme {
  Color get good => inspectionInk;
  Color get goodSurface => inspectionGround;
  Color get bad => inspectionAccent;
  Color get badSurface => inspectionGround;
  Color get caution => inspectionMuted;
  Color get cautionSurface => inspectionGround;
}

import "package:flutter/material.dart";

class MaterialTheme {
  final TextTheme textTheme;

  const MaterialTheme(this.textTheme);

  static ColorScheme lightScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: Color(4278218249),
      surfaceTint: Color(4278218249),
      onPrimary: Color(4294967295),
      primaryContainer: Color(4283747401),
      onPrimaryContainer: Color(4278202370),
      secondary: Color(4278218249),
      onSecondary: Color(4294967295),
      secondaryContainer: Color(4280530470),
      onSecondaryContainer: Color(4278195456),
      tertiary: Color(4282018103),
      onTertiary: Color(4294967295),
      tertiaryContainer: Color(4286163825),
      onTertiaryContainer: Color(4278195457),
      error: Color(4290386458),
      onError: Color(4294967295),
      errorContainer: Color(4294957782),
      onErrorContainer: Color(4282449922),
      surface: Color(4294245612),
      onSurface: Color(4279704852),
      onSurfaceVariant: Color(4282272314),
      outline: Color(4285430632),
      outlineVariant: Color(4290628277),
      shadow: Color(4278190080),
      scrim: Color(4278190080),
      inverseSurface: Color(4281020968),
      inversePrimary: Color(4285063002),
    );
  }

  ThemeData light() {
    return theme(lightScheme());
  }

  static ColorScheme lightMediumContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: Color(4278210308),
      surfaceTint: Color(4278218249),
      onPrimary: Color(4294967295),
      primaryContainer: Color(4278224909),
      onPrimaryContainer: Color(4294967295),
      secondary: Color(4278210309),
      onSecondary: Color(4294967295),
      secondaryContainer: Color(4278224911),
      onSecondaryContainer: Color(4294967295),
      tertiary: Color(4280175646),
      onTertiary: Color(4294967295),
      tertiaryContainer: Color(4283465803),
      onTertiaryContainer: Color(4294967295),
      error: Color(4287365129),
      onError: Color(4294967295),
      errorContainer: Color(4292490286),
      onErrorContainer: Color(4294967295),
      surface: Color(4294245612),
      onSurface: Color(4279704852),
      onSurfaceVariant: Color(4282009142),
      outline: Color(4283851345),
      outlineVariant: Color(4285693548),
      shadow: Color(4278190080),
      scrim: Color(4278190080),
      inverseSurface: Color(4281020968),
      inversePrimary: Color(4285063002),
      background: Color(4294245612),
      onBackground: Color(4294245612),
    );
  }

  ThemeData lightMediumContrast() {
    return theme(lightMediumContrastScheme());
  }

  static ColorScheme lightHighContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: Color(4278200577),
      surfaceTint: Color(4278218249),
      onPrimary: Color(4294967295),
      primaryContainer: Color(4278210308),
      onPrimaryContainer: Color(4294967295),
      secondary: Color(4278200577),
      onSecondary: Color(4294967295),
      secondaryContainer: Color(4278210309),
      onSecondaryContainer: Color(4294967295),
      tertiary: Color(4278200580),
      onTertiary: Color(4294967295),
      tertiaryContainer: Color(4280175646),
      onTertiaryContainer: Color(4294967295),
      error: Color(4283301890),
      onError: Color(4294967295),
      errorContainer: Color(4287365129),
      onErrorContainer: Color(4294967295),
      surface: Color(4294245612),
      onSurface: Color(4278190080),
      onSurfaceVariant: Color(4280035097),
      outline: Color(4282009142),
      outlineVariant: Color(4282009142),
      shadow: Color(4278190080),
      scrim: Color(4278190080),
      inverseSurface: Color(4281020968),
      inversePrimary: Color(4290052002),
      background: Color(4294245612),
      onBackground: Color(4294245612),
    );
  }

  ThemeData lightHighContrast() {
    return theme(lightHighContrastScheme());
  }

  static ColorScheme darkScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(4285260637),
      surfaceTint: Color(4285063002),
      onPrimary: Color(4278204930),
      primaryContainer: Color(4282366008),
      onPrimaryContainer: Color(4278196737),
      secondary: Color(4284014926),
      onSecondary: Color(4278204930),
      secondaryContainer: Color(4278224911),
      onSecondaryContainer: Color(4294967295),
      tertiary: Color(4288730263),
      onTertiary: Color(4278794508),
      tertiaryContainer: Color(4283465803),
      onTertiaryContainer: Color(4294967295),
      error: Color(4294948011),
      onError: Color(4285071365),
      errorContainer: Color(4287823882),
      onErrorContainer: Color(4294957782),
      surface: Color.fromARGB(255, 51, 55, 50),
      onSurface: Color(4292732374),
      onSurfaceVariant: Color(4290628277),
      outline: Color(4287140993),
      outlineVariant: Color(4282272314),
      shadow: Color(4278190080),
      scrim: Color(4278190080),
      inverseSurface: Color(4292732374),
      inversePrimary: Color(4278218249),
    );
  }

  ThemeData dark() {
    return theme(darkScheme());
  }

  static ColorScheme darkMediumContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(4285326430),
      surfaceTint: Color(4285063002),
      onPrimary: Color(4278197249),
      primaryContainer: Color(4282366008),
      onPrimaryContainer: Color(4278190080),
      secondary: Color(4284278354),
      onSecondary: Color(4278197249),
      secondaryContainer: Color(4278298645),
      onSecondaryContainer: Color(4278190080),
      tertiary: Color(4288993435),
      onTertiary: Color(4278197250),
      tertiaryContainer: Color(4285308261),
      onTertiaryContainer: Color(4278190080),
      error: Color(4294949553),
      onError: Color(4281794561),
      errorContainer: Color(4294923337),
      onErrorContainer: Color(4278190080),
      surface: Color(4279112972),
      onSurface: Color(4294376942),
      onSurfaceVariant: Color(4290957242),
      outline: Color(4288325523),
      outlineVariant: Color(4286220148),
      shadow: Color(4278190080),
      scrim: Color(4278190080),
      inverseSurface: Color(4292732374),
      inversePrimary: Color(4278211845),
      background: Color(4279112972),
      onBackground: Color(4279112972),
    );
  }

  ThemeData darkMediumContrast() {
    return theme(darkMediumContrastScheme());
  }

  static ColorScheme darkHighContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(4294049768),
      surfaceTint: Color(4285063002),
      onPrimary: Color(4278190080),
      primaryContainer: Color(4285326430),
      onPrimaryContainer: Color(4278190080),
      secondary: Color(4294049768),
      onSecondary: Color(4278190080),
      secondaryContainer: Color(4284278354),
      onSecondaryContainer: Color(4278190080),
      tertiary: Color(4294049769),
      onTertiary: Color(4278190080),
      tertiaryContainer: Color(4288993435),
      onTertiaryContainer: Color(4278190080),
      error: Color(4294965753),
      onError: Color(4278190080),
      errorContainer: Color(4294949553),
      onErrorContainer: Color(4278190080),
      surface: Color(4279112972),
      onSurface: Color(4294967295),
      onSurfaceVariant: Color(4294115304),
      outline: Color(4290957242),
      outlineVariant: Color(4290957242),
      shadow: Color(4278190080),
      scrim: Color(4278190080),
      inverseSurface: Color(4292732374),
      inversePrimary: Color(4278202882),
      background: Color(4279112972),
      onBackground: Color(4279112972),
    );
  }

  ThemeData darkHighContrast() {
    return theme(darkHighContrastScheme());
  }

  ThemeData theme(ColorScheme colorScheme) => ThemeData(
        useMaterial3: true,
        brightness: colorScheme.brightness,
        colorScheme: colorScheme,
        textTheme: textTheme.apply(
          bodyColor: colorScheme.onSurface,
          displayColor: colorScheme.onSurface,
        ),
        scaffoldBackgroundColor: colorScheme.background,
        canvasColor: colorScheme.surface,
      );

  /// Custom Color 1
  static const customColor1 = ExtendedColor(
    seed: Color(4287620608),
    value: Color(4287620608),
    light: ColorFamily(
      color: Color(4282345728),
      onColor: Color(4294967295),
      colorContainer: Color(4288081429),
      onColorContainer: Color(4280961280),
    ),
    lightMediumContrast: ColorFamily(
      color: Color(4282345728),
      onColor: Color(4294967295),
      colorContainer: Color(4288081429),
      onColorContainer: Color(4280961280),
    ),
    lightHighContrast: ColorFamily(
      color: Color(4282345728),
      onColor: Color(4294967295),
      colorContainer: Color(4288081429),
      onColorContainer: Color(4280961280),
    ),
    dark: ColorFamily(
      color: Color(4292870070),
      onColor: Color(4280170240),
      colorContainer: Color(4287356928),
      onColorContainer: Color(4280565760),
    ),
    darkMediumContrast: ColorFamily(
      color: Color(4292870070),
      onColor: Color(4280170240),
      colorContainer: Color(4287356928),
      onColorContainer: Color(4280565760),
    ),
    darkHighContrast: ColorFamily(
      color: Color(4292870070),
      onColor: Color(4280170240),
      colorContainer: Color(4287356928),
      onColorContainer: Color(4280565760),
    ),
  );

  List<ExtendedColor> get extendedColors => [
        customColor1,
      ];
}

class ExtendedColor {
  final Color seed, value;
  final ColorFamily light;
  final ColorFamily lightHighContrast;
  final ColorFamily lightMediumContrast;
  final ColorFamily dark;
  final ColorFamily darkHighContrast;
  final ColorFamily darkMediumContrast;

  const ExtendedColor({
    required this.seed,
    required this.value,
    required this.light,
    required this.lightHighContrast,
    required this.lightMediumContrast,
    required this.dark,
    required this.darkHighContrast,
    required this.darkMediumContrast,
  });
}

class ColorFamily {
  const ColorFamily({
    required this.color,
    required this.onColor,
    required this.colorContainer,
    required this.onColorContainer,
  });

  final Color color;
  final Color onColor;
  final Color colorContainer;
  final Color onColorContainer;
}

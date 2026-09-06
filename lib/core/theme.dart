import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'brand.dart';

ThemeData sisonkeTheme() {
  final textTheme = GoogleFonts.manropeTextTheme();
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: SisonkeColors.ivory,
    colorScheme: ColorScheme.fromSeed(
      seedColor: SisonkeColors.green,
      primary: SisonkeColors.green,
      secondary: SisonkeColors.gold,
      surface: SisonkeColors.white,
      error: SisonkeColors.red,
    ),
    textTheme: textTheme.copyWith(
      displaySmall: GoogleFonts.playfairDisplay(
        fontWeight: FontWeight.w700,
        color: SisonkeColors.ink,
      ),
      headlineSmall: GoogleFonts.playfairDisplay(
        fontWeight: FontWeight.w700,
        color: SisonkeColors.ink,
      ),
      titleLarge: GoogleFonts.manrope(
        fontWeight: FontWeight.w800,
        color: SisonkeColors.ink,
      ),
      bodyLarge: GoogleFonts.manrope(
        color: SisonkeColors.ink,
        height: 1.45,
      ),
    ),
    cardTheme: CardThemeData(
      color: SisonkeColors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: SisonkeColors.border),
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: SisonkeColors.ivory,
      foregroundColor: SisonkeColors.ink,
      elevation: 0,
      titleTextStyle: GoogleFonts.manrope(
        color: SisonkeColors.ink,
        fontWeight: FontWeight.w800,
        fontSize: 20,
      ),
    ),
  );
}

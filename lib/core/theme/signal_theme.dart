import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Signal Theme - Enterprise-grade CRM UI
/// Design Philosophy: High-clarity, low-noise, productivity-focused
class SignalTheme {
  // ============================================
  // COLOR SYSTEM (Neutral-First)
  // ============================================

  /// Primary Colors - Steel Blue (Primary Actions)
  static const Color steelBlue = Color(0xFF3B82F6);
  static const Color steelBlueLight = Color(0xFF60A5FA);
  static const Color steelBlueDark = Color(0xFF2563EB);

  /// Neutral Palette - Charcoal to Cloud
  static const Color charcoalBlack = Color(0xFF1F2937);
  static const Color softGraphite = Color(0xFF6B7280);
  static const Color cloudWhite = Color(0xFFFAFAFA);
  static const Color pureWhite = Color(0xFFFFFFFF);

  /// Semantic Colors
  static const Color mutedTeal = Color(0xFF10B981); // Success
  static const Color amber = Color(0xFFF59E0B); // Warning
  static const Color crimson = Color(0xFFEF4444); // Error

  /// Grey Scale
  static const Color grey50 = Color(0xFFF9FAFB);
  static const Color grey100 = Color(0xFFF3F4F6);
  static const Color grey200 = Color(0xFFE5E7EB);
  static const Color grey300 = Color(0xFFD1D5DB);
  static const Color grey400 = Color(0xFF9CA3AF);
  static const Color grey500 = Color(0xFF6B7280);
  static const Color grey600 = Color(0xFF4B5563);
  static const Color grey700 = Color(0xFF374151);
  static const Color grey800 = Color(0xFF1F2937);
  static const Color grey900 = Color(0xFF111827);

  /// Dark Mode Colors
  static const Color darkBackground = Color(0xFF0F172A);
  static const Color darkSurface = Color(0xFF1E293B);
  static const Color darkBorder = Color(0xFF334155);

  // ============================================
  // TYPOGRAPHY SYSTEM
  // ============================================

  static TextStyle heading1 = GoogleFonts.inter(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    height: 1.3,
    color: charcoalBlack,
    letterSpacing: -0.5,
  );

  static TextStyle heading2 = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.4,
    color: charcoalBlack,
    letterSpacing: -0.3,
  );

  static TextStyle bodyRegular = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: charcoalBlack,
  );

  static TextStyle bodyMedium = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.5,
    color: charcoalBlack,
  );

  static TextStyle bodySmall = GoogleFonts.inter(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: softGraphite,
  );

  static TextStyle helperText = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: softGraphite,
  );

  static TextStyle buttonText = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.2,
    letterSpacing: 0.2,
  );

  // ============================================
  // SPACING SYSTEM (8px base)
  // ============================================

  static const double space1 = 8.0;
  static const double space2 = 16.0;
  static const double space3 = 24.0;
  static const double space4 = 32.0;
  static const double space5 = 40.0;
  static const double space6 = 48.0;

  // ============================================
  // BORDER RADIUS (4-6px max)
  // ============================================

  static const double radiusSmall = 4.0;
  static const double radiusMedium = 6.0;
  static const double radiusLarge = 8.0;

  // ============================================
  // ELEVATION SYSTEM (Minimal shadows)
  // ============================================

  static List<BoxShadow> elevation1 = [
    BoxShadow(
      color: charcoalBlack.withOpacity(0.04),
      blurRadius: 2,
      offset: const Offset(0, 1),
    ),
  ];

  static List<BoxShadow> elevation2 = [
    BoxShadow(
      color: charcoalBlack.withOpacity(0.06),
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> elevation3 = [
    BoxShadow(
      color: charcoalBlack.withOpacity(0.08),
      blurRadius: 8,
      offset: const Offset(0, 4),
    ),
  ];

  // ============================================
  // LIGHT THEME
  // ============================================

  static ThemeData lightTheme = ThemeData(
    useMaterial3: false, // Material 2 discipline
    brightness: Brightness.light,
    fontFamily: GoogleFonts.inter().fontFamily,

    // Color Scheme
    colorScheme: const ColorScheme.light(
      primary: steelBlue,
      onPrimary: pureWhite,
      secondary: mutedTeal,
      onSecondary: pureWhite,
      error: crimson,
      onError: pureWhite,
      surface: pureWhite,
      onSurface: charcoalBlack,
      surfaceContainerHighest: grey50,
    ),

    scaffoldBackgroundColor: cloudWhite,
    dividerColor: grey200,
    disabledColor: grey400,

    // AppBar Theme
    appBarTheme: AppBarTheme(
      backgroundColor: pureWhite,
      foregroundColor: charcoalBlack,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: heading1,
      iconTheme: const IconThemeData(color: charcoalBlack, size: 20),
    ),

    // Card Theme - Subtle border, no heavy shadow
    cardTheme: CardThemeData(
      elevation: 0,
      color: pureWhite,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        side: const BorderSide(color: grey200, width: 1),
      ),
      margin: const EdgeInsets.all(0),
    ),

    // Input Decoration Theme - Outline, clear focus
    inputDecorationTheme: InputDecorationTheme(
      filled: false,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusSmall),
        borderSide: const BorderSide(color: grey300, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusSmall),
        borderSide: const BorderSide(color: grey300, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusSmall),
        borderSide: const BorderSide(color: steelBlue, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusSmall),
        borderSide: const BorderSide(color: crimson, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusSmall),
        borderSide: const BorderSide(color: crimson, width: 2),
      ),
      labelStyle: bodyRegular.copyWith(color: softGraphite),
      hintStyle: bodySmall,
      helperStyle: helperText,
      errorStyle: helperText.copyWith(color: crimson),
      prefixIconColor: softGraphite,
      suffixIconColor: softGraphite,
    ),

    // Elevated Button - Solid Steel Blue
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: steelBlue,
        foregroundColor: pureWhite,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
        ),
        textStyle: buttonText,
      ),
    ),

    // Outlined Button - Secondary actions
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: charcoalBlack,
        side: const BorderSide(color: grey300, width: 1),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
        ),
        textStyle: buttonText,
      ),
    ),

    // Text Button - Tertiary actions
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: steelBlue,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        textStyle: buttonText,
      ),
    ),

    // Floating Action Button
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: steelBlue,
      foregroundColor: pureWhite,
      elevation: 2,
    ),

    // Bottom Navigation Bar
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: pureWhite,
      selectedItemColor: steelBlue,
      unselectedItemColor: softGraphite,
      elevation: 8,
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle: bodySmall,
      unselectedLabelStyle: bodySmall,
    ),

    // Data Table Theme - Dense, minimal
    dataTableTheme: DataTableThemeData(
      headingTextStyle: bodyMedium.copyWith(color: softGraphite),
      dataTextStyle: bodyRegular,
      horizontalMargin: 16,
      columnSpacing: 24,
      dividerThickness: 1,
      headingRowColor: WidgetStateProperty.all(grey50),
      dataRowMinHeight: 48,
      dataRowMaxHeight: 56,
    ),

    // List Tile Theme
    listTileTheme: const ListTileThemeData(
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      dense: true,
      minLeadingWidth: 40,
      iconColor: softGraphite,
      textColor: charcoalBlack,
    ),

    // Chip Theme
    chipTheme: ChipThemeData(
      backgroundColor: grey100,
      labelStyle: bodySmall.copyWith(color: charcoalBlack),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusSmall),
      ),
    ),

    // Divider Theme
    dividerTheme: const DividerThemeData(
      color: grey200,
      thickness: 1,
      space: 1,
    ),

    // Text Theme
    textTheme: TextTheme(
      displayLarge: heading1.copyWith(fontSize: 32),
      displayMedium: heading1.copyWith(fontSize: 28),
      displaySmall: heading1.copyWith(fontSize: 24),
      headlineLarge: heading1,
      headlineMedium: heading2.copyWith(fontSize: 18),
      headlineSmall: heading2,
      titleLarge: bodyMedium.copyWith(fontSize: 16),
      titleMedium: bodyMedium,
      titleSmall: bodyMedium.copyWith(fontSize: 13),
      bodyLarge: bodyRegular.copyWith(fontSize: 15),
      bodyMedium: bodyRegular,
      bodySmall: bodySmall,
      labelLarge: buttonText,
      labelMedium: buttonText.copyWith(fontSize: 13),
      labelSmall: helperText,
    ),
  );

  // ============================================
  // DARK THEME
  // ============================================

  static ThemeData darkTheme = ThemeData(
    useMaterial3: false,
    brightness: Brightness.dark,
    fontFamily: GoogleFonts.inter().fontFamily,
    colorScheme: const ColorScheme.dark(
      primary: steelBlueLight,
      onPrimary: darkBackground,
      secondary: mutedTeal,
      onSecondary: darkBackground,
      error: crimson,
      onError: darkBackground,
      surface: darkSurface,
      onSurface: pureWhite,
      surfaceContainerHighest: grey800,
    ),
    scaffoldBackgroundColor: darkBackground,
    dividerColor: darkBorder,
    disabledColor: grey600,
    appBarTheme: AppBarTheme(
      backgroundColor: darkSurface,
      foregroundColor: pureWhite,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: heading1.copyWith(color: pureWhite),
      iconTheme: const IconThemeData(color: pureWhite, size: 20),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: darkSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        side: const BorderSide(color: darkBorder, width: 1),
      ),
      margin: const EdgeInsets.all(0),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: false,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusSmall),
        borderSide: const BorderSide(color: darkBorder, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusSmall),
        borderSide: const BorderSide(color: darkBorder, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusSmall),
        borderSide: const BorderSide(color: steelBlueLight, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusSmall),
        borderSide: const BorderSide(color: crimson, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusSmall),
        borderSide: const BorderSide(color: crimson, width: 2),
      ),
      labelStyle: bodyRegular.copyWith(color: grey400),
      hintStyle: bodySmall.copyWith(color: grey500),
      helperStyle: helperText.copyWith(color: grey500),
      errorStyle: helperText.copyWith(color: crimson),
      prefixIconColor: grey400,
      suffixIconColor: grey400,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: steelBlueLight,
        foregroundColor: darkBackground,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
        ),
        textStyle: buttonText,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: pureWhite,
        side: const BorderSide(color: darkBorder, width: 1),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
        ),
        textStyle: buttonText,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: steelBlueLight,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        textStyle: buttonText,
      ),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: darkSurface,
      selectedItemColor: steelBlueLight,
      unselectedItemColor: grey400,
      elevation: 8,
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle: bodySmall.copyWith(color: steelBlueLight),
      unselectedLabelStyle: bodySmall.copyWith(color: grey400),
    ),
    dataTableTheme: DataTableThemeData(
      headingTextStyle: bodyMedium.copyWith(color: grey400),
      dataTextStyle: bodyRegular.copyWith(color: pureWhite),
      horizontalMargin: 16,
      columnSpacing: 24,
      dividerThickness: 1,
      headingRowColor: WidgetStateProperty.all(grey800),
      dataRowMinHeight: 48,
      dataRowMaxHeight: 56,
    ),
    listTileTheme: ListTileThemeData(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      dense: true,
      minLeadingWidth: 40,
      iconColor: grey400,
      textColor: pureWhite,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: grey800,
      labelStyle: bodySmall.copyWith(color: pureWhite),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusSmall),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: darkBorder,
      thickness: 1,
      space: 1,
    ),
    textTheme: TextTheme(
      displayLarge: heading1.copyWith(fontSize: 32, color: pureWhite),
      displayMedium: heading1.copyWith(fontSize: 28, color: pureWhite),
      displaySmall: heading1.copyWith(fontSize: 24, color: pureWhite),
      headlineLarge: heading1.copyWith(color: pureWhite),
      headlineMedium: heading2.copyWith(fontSize: 18, color: pureWhite),
      headlineSmall: heading2.copyWith(color: pureWhite),
      titleLarge: bodyMedium.copyWith(fontSize: 16, color: pureWhite),
      titleMedium: bodyMedium.copyWith(color: pureWhite),
      titleSmall: bodyMedium.copyWith(fontSize: 13, color: pureWhite),
      bodyLarge: bodyRegular.copyWith(fontSize: 15, color: pureWhite),
      bodyMedium: bodyRegular.copyWith(color: pureWhite),
      bodySmall: bodySmall.copyWith(color: grey400),
      labelLarge: buttonText.copyWith(color: pureWhite),
      labelMedium: buttonText.copyWith(fontSize: 13, color: pureWhite),
      labelSmall: helperText.copyWith(color: grey500),
    ),
  );
}

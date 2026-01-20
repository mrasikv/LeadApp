import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors - Professional Blue
  static const Color primary = Color(0xFF2196F3);
  static const Color primaryLight = Color(0xFF64B5F6);
  static const Color primaryDark = Color(0xFF1976D2);
  static const Color primaryContainer = Color(0xFFE3F2FD);
  
  // Secondary Colors - Energetic Orange
  static const Color secondary = Color(0xFFFF9800);
  static const Color secondaryLight = Color(0xFFFFB74D);
  static const Color secondaryDark = Color(0xFFF57C00);
  static const Color secondaryContainer = Color(0xFFFFE0B2);
  
  // Accent Colors
  static const Color accent = Color(0xFF00BCD4); // Cyan
  
  // Status Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color successLight = Color(0xFF81C784);
  static const Color successDark = Color(0xFF388E3C);
  
  static const Color warning = Color(0xFFFFC107);
  static const Color warningLight = Color(0xFFFFD54F);
  static const Color warningDark = Color(0xFFFFA000);
  
  static const Color error = Color(0xFFF44336);
  static const Color errorLight = Color(0xFFE57373);
  static const Color errorDark = Color(0xFFD32F2F);
  
  static const Color info = Color(0xFF2196F3);
  
  // Neutral Colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  
  static const Color grey50 = Color(0xFFFAFAFA);
  static const Color grey100 = Color(0xFFF5F5F5);
  static const Color grey200 = Color(0xFFEEEEEE);
  static const Color grey300 = Color(0xFFE0E0E0);
  static const Color grey400 = Color(0xFFBDBDBD);
  static const Color grey500 = Color(0xFF9E9E9E);
  static const Color grey600 = Color(0xFF757575);
  static const Color grey700 = Color(0xFF616161);
  static const Color grey800 = Color(0xFF424242);
  static const Color grey900 = Color(0xFF212121);
  
  // Background Colors
  static const Color background = Color(0xFFFAFAFA);
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  
  // Text Colors
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textDisabled = Color(0xFFBDBDBD);
  static const Color textPrimaryDark = Color(0xFFFFFFFF);
  static const Color textSecondaryDark = Color(0xFFB0B0B0);
  
  // Divider & Border
  static const Color divider = Color(0xFFE0E0E0);
  static const Color border = Color(0xFFE0E0E0);
  
  // Lead Status Default Colors
  static const Color statusNew = Color(0xFF2196F3);
  static const Color statusFollowUp = Color(0xFFFF9800);
  static const Color statusRecall = Color(0xFF9C27B0);
  static const Color statusQualified = Color(0xFF4CAF50);
  static const Color statusUnanswered = Color(0xFFF44336);
  static const Color statusPotential = Color(0xFF00BCD4);
  static const Color statusIncomingCall = Color(0xFFFFC107);
  static const Color statusOfficeVisit = Color(0xFF3F51B5);
  static const Color statusWon = Color(0xFF4CAF50);
  static const Color statusLost = Color(0xFF9E9E9E);
  
  // Role Colors
  static const Color roleSuperAdmin = Color(0xFF9C27B0);
  static const Color roleCompanyAdmin = Color(0xFF2196F3);
  static const Color roleSalesUser = Color(0xFF4CAF50);
  static const Color roleCallAgent = Color(0xFFFF9800);
  static const Color roleManager = Color(0xFF3F51B5);
  static const Color roleFieldStaff = Color(0xFF00BCD4);
  
  // Chart Colors
  static const List<Color> chartColors = [
    Color(0xFF2196F3),
    Color(0xFFFF9800),
    Color(0xFF4CAF50),
    Color(0xFF9C27B0),
    Color(0xFF00BCD4),
    Color(0xFFFFC107),
    Color(0xFFF44336),
    Color(0xFF3F51B5),
  ];
  
  // Gradient Colors
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [secondary, secondaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient successGradient = LinearGradient(
    colors: [success, successDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

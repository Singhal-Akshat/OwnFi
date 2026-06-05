import 'dart:ui';
import 'package:flutter/material.dart';

class AppColors {
  static const Color midnightBg = Color(0xFF0B0F19);
  static const Color obsidianSurface = Color(0xFF121824);
  static const Color glassCard = Color(0x0EFFFFFF); // 5.5% opacity white
  static const Color glassBorder = Color(0x20FFFFFF); // 12.5% opacity white

  // Neon accents
  static const Color neonTeal = Color(0xFF00F2FE);
  static const Color neonEmerald = Color(0xFF05F8A1);
  static const Color neonPurple = Color(0xFF7F00FF);
  static const Color neonPink = Color(0xFFE100FF);
  
  // Gradients
  static const List<Color> tealBlueGradient = [Color(0xFF00F2FE), Color(0xFF4FACFE)];
  static const List<Color> emeraldGradient = [Color(0xFF05F8A1), Color(0xFF00C6FF)];
  static const List<Color> purplePinkGradient = [Color(0xFF7F00FF), Color(0xFFE100FF)];
  static const List<Color> bgGradient = [Color(0xFF0B0F19), Color(0xFF161B26), Color(0xFF1A1230)];

  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFF94A3B8); // Slate 400
  static const Color textMuted = Color(0xFF64748B); // Slate 500
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: AppColors.neonTeal,
      scaffoldBackgroundColor: AppColors.midnightBg,
      cardColor: AppColors.obsidianSurface,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.neonTeal,
        secondary: AppColors.neonEmerald,
        surface: AppColors.obsidianSurface,
        error: Colors.redAccent,
      ),
      fontFamily: 'Outfit', // Uses default system font fallback if not downloaded, looks modern
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 32,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
        headlineMedium: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 24,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
        titleLarge: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.normal,
        ),
        bodyMedium: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 14,
          fontWeight: FontWeight.normal,
        ),
        labelSmall: TextStyle(
          color: AppColors.textMuted,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        selectedItemColor: AppColors.neonTeal,
        unselectedItemColor: AppColors.textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
    );
  }

  // Frosted glass decoration utility
  static BoxDecoration glassDecoration({
    double borderRadius = 16,
    Color color = AppColors.glassCard,
    Color borderColor = AppColors.glassBorder,
  }) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: borderColor,
        width: 1.0,
      ),
    );
  }
}

// Glassmorphism blur wrapper
class GlassBlur extends StatelessWidget {
  final Widget child;
  final double blurX;
  final double blurY;
  final double borderRadius;
  final Color cardColor;
  final Color borderColor;
  final bool useBlur;

  const GlassBlur({
    super.key,
    required this.child,
    this.blurX = 15.0,
    this.blurY = 15.0,
    this.borderRadius = 16.0,
    this.cardColor = AppColors.glassCard,
    this.borderColor = AppColors.glassBorder,
    this.useBlur = true,
  });

  @override
  Widget build(BuildContext context) {
    final container = Container(
      decoration: AppTheme.glassDecoration(
        borderRadius: borderRadius,
        color: cardColor,
        borderColor: borderColor,
      ),
      child: child,
    );

    if (!useBlur || (blurX == 0.0 && blurY == 0.0)) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: container,
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurX, sigmaY: blurY),
        child: container,
      ),
    );
  }
}

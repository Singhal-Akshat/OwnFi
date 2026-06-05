import 'package:flutter/material.dart';
import '../theme.dart';

class CategoryUtils {
  static IconData getCategoryIcon(String category) {
    switch (category) {
      case 'Food':
        return Icons.fastfood_rounded;
      case 'Shopping':
        return Icons.shopping_bag_rounded;
      case 'Bills':
        return Icons.receipt_long_rounded;
      case 'Entertainment':
        return Icons.movie_rounded;
      case 'Travel':
        return Icons.directions_car_rounded;
      case 'Salary':
        return Icons.wallet_rounded;
      case 'Investment':
        return Icons.trending_up_rounded;
      case 'Health':
        return Icons.health_and_safety_rounded;
      case 'Education':
        return Icons.school_rounded;
      default:
        return Icons.category_rounded;
    }
  }

  static Color getCategoryColor(String category, Color defaultColor) {
    switch (category) {
      case 'Food':
        return Colors.orangeAccent;
      case 'Shopping':
        return Colors.pinkAccent;
      case 'Bills':
        return AppColors.neonTeal;
      case 'Entertainment':
        return AppColors.neonPurple;
      case 'Travel':
        return Colors.blueAccent;
      case 'Salary':
        return AppColors.neonEmerald;
      case 'Investment':
        return Colors.amberAccent;
      case 'Health':
        return Colors.redAccent;
      case 'Education':
        return Colors.indigoAccent;
      default:
        return defaultColor;
    }
  }
}

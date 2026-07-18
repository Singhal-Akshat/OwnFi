import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme.dart';
import 'icon_list.dart';

class CategoryUtils {
  static Map<String, IconData> customIcons = {};
  static Map<String, Color> customColors = {};

  static Map<int, IconData>? _codePointToIconMap;

  static IconData? _getIconFromCodePoint(int codePoint) {
    if (_codePointToIconMap == null) {
      final map = <int, IconData>{};
      for (final icon in availableCategoryIcons.values) {
        map[icon.codePoint] = icon;
      }
      for (final list in iconLibrary.values) {
        for (final icon in list) {
          map[icon.codePoint] = icon;
        }
      }
      for (final icon in IconList.allIcons.values) {
        map[icon.codePoint] = icon;
      }
      _codePointToIconMap = map;
    }
    return _codePointToIconMap![codePoint];
  }

  static const Map<String, IconData> availableCategoryIcons = {
    'Food': Icons.fastfood_rounded,
    'Shopping': Icons.shopping_bag_rounded,
    'Bills': Icons.receipt_long_rounded,
    'Entertainment': Icons.movie_rounded,
    'Travel': Icons.directions_car_rounded,
    'Salary': Icons.wallet_rounded,
    'Investment': Icons.trending_up_rounded,
    'Health': Icons.health_and_safety_rounded,
    'Education': Icons.school_rounded,
    'Gym': Icons.fitness_center_rounded,
    'Home': Icons.home_rounded,
    'Subscriptions': Icons.subscriptions_rounded,
    'Groceries': Icons.local_grocery_store_rounded,
    'Pets': Icons.pets_rounded,
    'Gifts': Icons.card_giftcard_rounded,
    'Maintenance': Icons.build_rounded,
    'Gaming': Icons.sports_esports_rounded,
    'Payback': Icons.assignment_return_rounded,
    'Other': Icons.category_rounded,
    'Transfer': Icons.swap_horiz_rounded,
    'Credit Card': Icons.credit_card_rounded,
    'Family': Icons.family_restroom_rounded,
    'Friend': Icons.people_alt_rounded,
    'Due Amount': Icons.pending_actions_rounded,
    'Borrow': Icons.call_received_rounded,
    'Lend': Icons.call_made_rounded,
  };

  static const Map<String, Color> availableCategoryColors = {
    'Food': Colors.orangeAccent,
    'Shopping': Colors.pinkAccent,
    'Bills': AppColors.neonTeal,
    'Entertainment': AppColors.neonPurple,
    'Travel': Colors.blueAccent,
    'Salary': AppColors.neonEmerald,
    'Investment': Colors.amberAccent,
    'Health': Colors.redAccent,
    'Education': Colors.indigoAccent,
    'Gym': Colors.tealAccent,
    'Home': Colors.deepOrangeAccent,
    'Subscriptions': Colors.lightBlueAccent,
    'Groceries': Colors.lightGreenAccent,
    'Pets': Colors.brown,
    'Gifts': Colors.purpleAccent,
    'Maintenance': Colors.blueGrey,
    'Gaming': Colors.cyanAccent,
    'Payback': Colors.tealAccent,
    'Other': AppColors.textSecondary,
    'Transfer': AppColors.neonTeal,
    'Credit Card': Colors.blueAccent,
    'Family': Colors.purpleAccent,
    'Friend': Colors.cyanAccent,
    'Due Amount': Colors.redAccent,
    'Borrow': Colors.redAccent,
    'Lend': AppColors.neonEmerald,
  };

  // Grouped Icons for Library Picker
  static const Map<String, List<IconData>> iconLibrary = {
    'Finance': [
      Icons.wallet_rounded,
      Icons.attach_money_rounded,
      Icons.credit_card_rounded,
      Icons.trending_up_rounded,
      Icons.account_balance_rounded,
      Icons.savings_rounded,
      Icons.payments_rounded,
      Icons.receipt_long_rounded,
      Icons.account_balance_wallet_rounded,
      Icons.monetization_on_rounded,
      Icons.swap_horiz_rounded,
      Icons.pending_actions_rounded,
    ],
    'Food & Drink': [
      Icons.fastfood_rounded,
      Icons.restaurant_rounded,
      Icons.local_cafe_rounded,
      Icons.local_bar_rounded,
      Icons.local_pizza_rounded,
      Icons.cake_rounded,
      Icons.bakery_dining_rounded,
      Icons.icecream_rounded,
    ],
    'Shopping': [
      Icons.shopping_bag_rounded,
      Icons.shopping_cart_rounded,
      Icons.local_mall_rounded,
      Icons.storefront_rounded,
      Icons.card_giftcard_rounded,
      Icons.qr_code_rounded,
    ],
    'Transport & Travel': [
      Icons.directions_car_rounded,
      Icons.directions_bike_rounded,
      Icons.flight_rounded,
      Icons.local_shipping_rounded,
      Icons.train_rounded,
      Icons.subway_rounded,
      Icons.commute_rounded,
      Icons.directions_bus_rounded,
    ],
    'Entertainment': [
      Icons.movie_rounded,
      Icons.sports_esports_rounded,
      Icons.music_note_rounded,
      Icons.theater_comedy_rounded,
      Icons.tv_rounded,
      Icons.book_rounded,
      Icons.videogame_asset_rounded,
    ],
    'Health & Fitness': [
      Icons.health_and_safety_rounded,
      Icons.medical_services_rounded,
      Icons.fitness_center_rounded,
      Icons.spa_rounded,
      Icons.local_hospital_rounded,
      Icons.self_improvement_rounded,
    ],
    'Family & Social': [
      Icons.people_alt_rounded,
      Icons.family_restroom_rounded,
      Icons.handshake_rounded,
      Icons.pets_rounded,
      Icons.celebration_rounded,
      Icons.child_care_rounded,
    ],
    'Home & Utilities': [
      Icons.home_rounded,
      Icons.build_rounded,
      Icons.electrical_services_rounded,
      Icons.water_drop_rounded,
      Icons.wifi_rounded,
      Icons.phone_android_rounded,
      Icons.lightbulb_rounded,
      Icons.security_rounded,
    ],
    'Education & Work': [
      Icons.school_rounded,
      Icons.work_rounded,
      Icons.class_rounded,
      Icons.menu_book_rounded,
      Icons.laptop_chromebook_rounded,
    ],
    'Other': [
      Icons.category_rounded,
      Icons.more_horiz_rounded,
      Icons.star_rounded,
      Icons.info_rounded,
      Icons.help_rounded,
    ]
  };

  static Future<void> loadCustomCategories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Initialize/migrate categories
      List<String> expenseCats = prefs.getStringList('categories_expense') ?? ['Food', 'Shopping', 'Bills', 'Entertainment', 'Travel', 'Health', 'Education', 'Payback', 'Other'];
      List<String> incomeCats = prefs.getStringList('categories_income') ?? ['Salary', 'Family Money transfer', 'Friend money transfer', 'Due Amount', 'Other'];
      List<String> transferCats = prefs.getStringList('categories_transfer') ?? ['Internal transfer', 'Credit card payment', 'Other'];

      expenseCats = List<String>.from(expenseCats);
      incomeCats = List<String>.from(incomeCats);
      transferCats = List<String>.from(transferCats);

      // Ensure expense cats has "Payback"
      if (!expenseCats.contains('Payback')) {
        final otherIdx = expenseCats.indexOf('Other');
        if (otherIdx != -1) {
          expenseCats.insert(otherIdx, 'Payback');
        } else {
          expenseCats.add('Payback');
        }
        await prefs.setStringList('categories_expense', expenseCats);
      }

      // Clean up expense cats
      expenseCats.removeWhere((c) => c.trim().toLowerCase() == 'investment');
      await prefs.setStringList('categories_expense', expenseCats);

      // Ensure income cats has "Investment"
      bool hasIncomeInv = incomeCats.any((c) => c.trim().toLowerCase() == 'investment');
      if (!hasIncomeInv) {
        incomeCats.insert(1, 'Investment');
        await prefs.setStringList('categories_income', incomeCats);
      } else {
        for (int i = 0; i < incomeCats.length; i++) {
          if (incomeCats[i].trim().toLowerCase() == 'investment') {
            incomeCats[i] = 'Investment';
          }
        }
        await prefs.setStringList('categories_income', incomeCats);
      }

      // Ensure transfer cats has "Investment"
      bool hasTransferInv = transferCats.any((c) => c.trim().toLowerCase() == 'investment');
      if (!hasTransferInv) {
        final otherIdx = transferCats.indexOf('Other');
        if (otherIdx != -1) {
          transferCats.insert(otherIdx, 'Investment');
        } else {
          transferCats.add('Investment');
        }
        await prefs.setStringList('categories_transfer', transferCats);
      } else {
        for (int i = 0; i < transferCats.length; i++) {
          if (transferCats[i].trim().toLowerCase() == 'investment') {
            transferCats[i] = 'Investment';
          }
        }
        await prefs.setStringList('categories_transfer', transferCats);
      }
      
      // Load custom category icons
      final iconMap = prefs.getStringList('custom_category_icons') ?? [];
      customIcons.clear();
      for (final item in iconMap) {
        final parts = item.split(':');
        if (parts.length == 2) {
          final cat = parts[0];
          final iconKey = parts[1];
          final codePoint = int.tryParse(iconKey);
          if (codePoint != null) {
            final staticIcon = _getIconFromCodePoint(codePoint);
            if (staticIcon != null) {
              customIcons[cat] = staticIcon;
            } else {
              customIcons[cat] = Icons.category_rounded;
            }
          } else if (availableCategoryIcons.containsKey(iconKey)) {
            customIcons[cat] = availableCategoryIcons[iconKey]!;
          }
        }
      }

      // Load custom category colors
      final colorMap = prefs.getStringList('custom_category_colors') ?? [];
      customColors.clear();
      for (final item in colorMap) {
        final parts = item.split(':');
        if (parts.length == 2) {
          final cat = parts[0];
          final hex = parts[1];
          final colorInt = int.tryParse(hex.replaceFirst('#', ''), radix: 16);
          if (colorInt != null) {
            customColors[cat] = Color(colorInt | 0xFF000000);
          }
        }
      }
    } catch (_) {}
  }

  static IconData getCategoryIcon(String category) {
    if (customIcons.containsKey(category)) {
      return customIcons[category]!;
    }
    final lower = category.toLowerCase().trim();
    if (lower == 'food') return Icons.fastfood_rounded;
    if (lower == 'shopping') return Icons.shopping_bag_rounded;
    if (lower == 'bills') return Icons.receipt_long_rounded;
    if (lower == 'entertainment') return Icons.movie_rounded;
    if (lower == 'travel') return Icons.directions_car_rounded;
    if (lower == 'salary') return Icons.wallet_rounded;
    if (lower == 'investment') return Icons.trending_up_rounded;
    if (lower == 'health') return Icons.health_and_safety_rounded;
    if (lower == 'education') return Icons.school_rounded;
    if (lower == 'payback') return Icons.assignment_return_rounded;
    if (lower.contains('internal transfer') || lower == 'transfer') return Icons.swap_horiz_rounded;
    if (lower.contains('credit card')) return Icons.credit_card_rounded;
    if (lower.contains('family')) return Icons.family_restroom_rounded;
    if (lower.contains('friend')) return Icons.people_alt_rounded;
    if (lower.contains('due')) return Icons.pending_actions_rounded;
    return Icons.category_rounded;
  }

  static Color getCategoryColor(String category, Color defaultColor) {
    if (customColors.containsKey(category)) {
      return customColors[category]!;
    }
    final lower = category.toLowerCase().trim();
    if (lower == 'food') return Colors.orangeAccent;
    if (lower == 'shopping') return Colors.pinkAccent;
    if (lower == 'bills') return AppColors.neonTeal;
    if (lower == 'entertainment') return AppColors.neonPurple;
    if (lower == 'travel') return Colors.blueAccent;
    if (lower == 'salary') return AppColors.neonEmerald;
    if (lower == 'investment') return Colors.amberAccent;
    if (lower == 'health') return Colors.redAccent;
    if (lower == 'education') return Colors.indigoAccent;
    if (lower == 'payback') return Colors.tealAccent;
    if (lower.contains('internal transfer') || lower == 'transfer') return AppColors.neonTeal;
    if (lower.contains('credit card')) return Colors.blueAccent;
    if (lower.contains('family')) return Colors.purpleAccent;
    if (lower.contains('friend')) return Colors.cyanAccent;
    if (lower.contains('due')) return Colors.redAccent;
    return defaultColor;
  }
}

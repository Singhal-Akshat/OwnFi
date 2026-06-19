import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_personal_tracker/core/theme.dart';
import 'package:my_personal_tracker/core/utils/category_utils.dart';
import 'package:my_personal_tracker/core/utils/icon_list.dart';

class CategoriesDialog extends StatefulWidget {
  const CategoriesDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (context) => const CategoriesDialog(),
    );
  }

  @override
  State<CategoriesDialog> createState() => _CategoriesDialogState();
}

class _CategoriesDialogState extends State<CategoriesDialog> {
  String _currentType = 'expense';
  IconData _selectedIconData = Icons.category_rounded;
  Color _selectedColor = AppColors.neonTeal;
  final _newCategoryController = TextEditingController();

  @override
  void dispose() {
    _newCategoryController.dispose();
    super.dispose();
  }

  void _showIconPickerDialog(BuildContext context, void Function(IconData, Color) onSelected) {
    showDialog(
      context: context,
      builder: (context) {
        String selectedCategory = CategoryUtils.iconLibrary.keys.first;
        String searchQuery = '';

        return StatefulBuilder(
          builder: (context, setState) {
            final filteredIcons = <IconData>[];
            if (searchQuery.isNotEmpty) {
              IconList.allIcons.forEach((name, icon) {
                if (name.contains(searchQuery)) {
                  filteredIcons.add(icon);
                }
              });
            } else {
              filteredIcons.addAll(CategoryUtils.iconLibrary[selectedCategory] ?? []);
            }

            return Dialog(
              backgroundColor: Colors.transparent,
              child: GlassBlur(
                borderRadius: 24,
                blurX: 30,
                blurY: 30,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Icon Library',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 12),

                      // Search field
                      TextField(
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'Search icons (e.g. food, bill, bank)...',
                          hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                          prefixIcon: const Icon(Icons.search_rounded, color: Colors.white54, size: 18),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 8),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.white24),
                          ),
                        ),
                        onChanged: (val) {
                          setState(() {
                            searchQuery = val.toLowerCase().trim();
                          });
                        },
                      ),
                      const SizedBox(height: 12),

                      // Category Tabs selector (only show when not searching)
                      if (searchQuery.isEmpty) ...[
                        SizedBox(
                          height: 38,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            children: CategoryUtils.iconLibrary.keys.map((catName) {
                              final isSelected = selectedCategory == catName;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: ChoiceChip(
                                  label: Text(catName, style: const TextStyle(fontSize: 11)),
                                  selected: isSelected,
                                  selectedColor: AppColors.neonPurple.withOpacity(0.2),
                                  checkmarkColor: AppColors.neonPurple,
                                  labelStyle: TextStyle(
                                    color: isSelected ? AppColors.neonPurple : Colors.white70,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  ),
                                  onSelected: (val) {
                                    if (val) {
                                      setState(() {
                                        selectedCategory = catName;
                                      });
                                    }
                                  },
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Icons Grid
                      Container(
                        width: double.maxFinite,
                        height: 200,
                        child: filteredIcons.isEmpty
                            ? const Center(
                                child: Text(
                                  'No matching icons found',
                                  style: TextStyle(color: Colors.white38, fontSize: 12),
                                ),
                              )
                            : GridView.builder(
                                physics: const BouncingScrollPhysics(),
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 5,
                                  crossAxisSpacing: 10,
                                  mainAxisSpacing: 10,
                                ),
                                itemCount: filteredIcons.length,
                                itemBuilder: (context, index) {
                                  final icon = filteredIcons[index];
                                  return InkWell(
                                    onTap: () {
                                      final color = Colors.primaries[icon.codePoint % Colors.primaries.length];
                                      onSelected(icon, color);
                                      Navigator.pop(context);
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.05),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: Colors.white10),
                                      ),
                                      child: Icon(icon, color: Colors.white, size: 22),
                                    ),
                                  );
                                },
                              ),
                      ),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: GlassBlur(
        borderRadius: 24,
        blurX: 30,
        blurY: 30,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Manage Categories',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('Expense', style: TextStyle(fontSize: 12)),
                      selected: _currentType == 'expense',
                      selectedColor: AppColors.neonPurple.withOpacity(0.2),
                      checkmarkColor: AppColors.neonPurple,
                      labelStyle: TextStyle(
                        color: _currentType == 'expense' ? AppColors.neonPurple : Colors.white70,
                        fontWeight: _currentType == 'expense' ? FontWeight.bold : FontWeight.normal,
                      ),
                      onSelected: (val) {
                        if (val) setState(() => _currentType = 'expense');
                      },
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('Income', style: TextStyle(fontSize: 12)),
                      selected: _currentType == 'income',
                      selectedColor: AppColors.neonEmerald.withOpacity(0.2),
                      checkmarkColor: AppColors.neonEmerald,
                      labelStyle: TextStyle(
                        color: _currentType == 'income' ? AppColors.neonEmerald : Colors.white70,
                        fontWeight: _currentType == 'income' ? FontWeight.bold : FontWeight.normal,
                      ),
                      onSelected: (val) {
                        if (val) setState(() => _currentType = 'income');
                      },
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('Transfer', style: TextStyle(fontSize: 12)),
                      selected: _currentType == 'transfer',
                      selectedColor: AppColors.neonTeal.withOpacity(0.2),
                      checkmarkColor: AppColors.neonTeal,
                      labelStyle: TextStyle(
                        color: _currentType == 'transfer' ? AppColors.neonTeal : Colors.white70,
                        fontWeight: _currentType == 'transfer' ? FontWeight.bold : FontWeight.normal,
                      ),
                      onSelected: (val) {
                        if (val) setState(() => _currentType = 'transfer');
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              FutureBuilder<SharedPreferences>(
                future: SharedPreferences.getInstance(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator(color: AppColors.neonTeal));
                  }
                  final prefs = snapshot.data!;
                  final key = 'categories_$_currentType';
                  final defaultCats = _currentType == 'expense'
                      ? ['Food', 'Shopping', 'Bills', 'Entertainment', 'Travel', 'Health', 'Education', 'Other']
                      : (_currentType == 'income'
                          ? ['Salary', 'Investment', 'Family Money transfer', 'Friend money transfer', 'Due Amount', 'Other']
                          : ['Internal transfer', 'Credit card payment', 'Investment', 'Other']);
                  final cats = prefs.getStringList(key) ?? defaultCats;

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        constraints: const BoxConstraints(maxHeight: 180),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: cats.length,
                          itemBuilder: (context, index) {
                            final cat = cats[index];
                            final icon = CategoryUtils.getCategoryIcon(cat);
                            final color = CategoryUtils.getCategoryColor(cat, Colors.white70);
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(icon, color: color, size: 18),
                              ),
                              title: Text(cat, style: const TextStyle(fontSize: 14)),
                              trailing: cat.toLowerCase() == 'other' || cat.toLowerCase() == 'others'
                                  ? null
                                  : IconButton(
                                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                                      onPressed: () async {
                                        final updated = List<String>.from(cats)..removeAt(index);
                                        await prefs.setStringList(key, updated);

                                        // Clean up custom icon and color mappings
                                        final iconMap = prefs.getStringList('custom_category_icons') ?? [];
                                        iconMap.removeWhere((item) => item.startsWith('$cat:'));
                                        await prefs.setStringList('custom_category_icons', iconMap);

                                        final colorMap = prefs.getStringList('custom_category_colors') ?? [];
                                        colorMap.removeWhere((item) => item.startsWith('$cat:'));
                                        await prefs.setStringList('custom_category_colors', colorMap);

                                        // Reload memory cache
                                        await CategoryUtils.loadCustomCategories();

                                        setState(() {});
                                      },
                                    ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _newCategoryController,
                              decoration: const InputDecoration(
                                hintText: 'New category name',
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.neonTeal, size: 28),
                            onPressed: () async {
                              final newCat = _newCategoryController.text.trim();
                              if (newCat.isNotEmpty && !cats.contains(newCat)) {
                                final updated = List<String>.from(cats)..add(newCat);
                                // Keep "Other" at the end if it's there
                                if (updated.contains('Other')) {
                                  updated.remove('Other');
                                  updated.add('Other');
                                }
                                await prefs.setStringList(key, updated);

                                // Save custom icon mapping (we store codePoint as string)
                                final iconMap = prefs.getStringList('custom_category_icons') ?? [];
                                iconMap.add('$newCat:${_selectedIconData.codePoint}');
                                await prefs.setStringList('custom_category_icons', iconMap);

                                // Save custom color mapping
                                final colorMap = prefs.getStringList('custom_category_colors') ?? [];
                                final colorHex = '#${_selectedColor.value.toRadixString(16).substring(2)}';
                                colorMap.add('$newCat:$colorHex');
                                await prefs.setStringList('custom_category_colors', colorMap);

                                // Reload memory cache
                                await CategoryUtils.loadCustomCategories();

                                _newCategoryController.clear();
                                _selectedIconData = Icons.category_rounded;
                                _selectedColor = AppColors.neonTeal;
                                setState(() {});
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Select Icon & Color:', style: TextStyle(fontSize: 12, color: Colors.white70)),
                          GestureDetector(
                            onTap: () {
                              _showIconPickerDialog(context, (icon, color) {
                                setState(() {
                                  _selectedIconData = icon;
                                  _selectedColor = color;
                                });
                              });
                            },
                            child: const Text(
                              'More Icons ➔',
                              style: TextStyle(fontSize: 12, color: AppColors.neonTeal, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        height: 44,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          children: [
                            // Current selection preview
                            GestureDetector(
                              onTap: () {
                                _showIconPickerDialog(context, (icon, color) {
                                  setState(() {
                                    _selectedIconData = icon;
                                    _selectedColor = color;
                                  });
                                });
                              },
                              child: Container(
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: _selectedColor.withOpacity(0.25),
                                  border: Border.all(color: _selectedColor, width: 2),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(_selectedIconData, color: _selectedColor, size: 18),
                              ),
                            ),
                            ...CategoryUtils.availableCategoryIcons.entries.map((e) {
                              final isSelected = _selectedIconData == e.value;
                              final iconColor = CategoryUtils.availableCategoryColors[e.key] ?? Colors.white;
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedIconData = e.value;
                                    _selectedColor = iconColor;
                                  });
                                },
                                child: Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 4),
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: isSelected ? iconColor.withOpacity(0.15) : Colors.transparent,
                                    border: Border.all(
                                      color: isSelected ? iconColor : Colors.white10,
                                      width: 1.5,
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(e.value, color: isSelected ? iconColor : Colors.white70, size: 18),
                                ),
                              );
                            }).toList(),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close', style: TextStyle(color: AppColors.textSecondary)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

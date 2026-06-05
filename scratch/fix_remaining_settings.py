with open('e:/Projects/Money_Tracker/lib/ui/settings/settings_view.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Let's target specific lines where they were undefined:
content = content.replace("selectedType == 'expense'", "controller.selectedType == 'expense'")
content = content.replace("selectedType == 'income'", "controller.selectedType == 'income'")
content = content.replace("selectedType == 'transfer'", "controller.selectedType == 'transfer'")

content = content.replace("!currentCats.contains(selectedCategory)", "!currentCats.contains(controller.selectedCategory)")
content = content.replace("selectedCategory = 'Other';", "controller.selectedCategory = 'Other';")
content = content.replace("selectedCategory = currentCats.first;", "controller.selectedCategory = currentCats.first;")
content = content.replace("selectedCategory = '';", "controller.selectedCategory = '';")

content = content.replace("selectedCategory = regexResult.category;", "controller.selectedCategory = regexResult.category;")
content = content.replace("selectedCategory == 'Utilities'", "controller.selectedCategory == 'Utilities'")
content = content.replace("selectedCategory = 'Bills';", "controller.selectedCategory = 'Bills';")
content = content.replace("!allowedCategories.contains(selectedCategory)", "!allowedCategories.contains(controller.selectedCategory)")
content = content.replace("selectedAccount = 'Cash';", "controller.selectedAccount = 'Cash';")
content = content.replace("selectedAccount == 'Cash'", "controller.selectedAccount == 'Cash'")
content = content.replace("selectedCategory = geminiResult.category;", "controller.selectedCategory = geminiResult.category;")

with open('e:/Projects/Money_Tracker/lib/ui/settings/settings_view.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("Fixed remaining variables in settings_view.dart!")

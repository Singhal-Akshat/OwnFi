with open('e:/Projects/Money_Tracker/lib/features/expenses/ui/dashboard_view.dart', 'r', encoding='utf-8') as f:
    lines = f.readlines()

# We want to keep lines up to line 1089 (index 1088)
# And the final closing brace of class DashboardView which is at the very end
keep_lines = lines[:1089]
keep_lines.append('}\n')

with open('e:/Projects/Money_Tracker/lib/features/expenses/ui/dashboard_view.dart', 'w', encoding='utf-8') as f:
    f.writelines(keep_lines)

print("Cleaned successfully!")

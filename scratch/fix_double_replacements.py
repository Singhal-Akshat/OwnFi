with open('e:/Projects/Money_Tracker/lib/ui/settings/settings_view.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Replace multiple chained controller prefixes
content = content.replace('controller.controller.controller.controller', 'controller')
content = content.replace('controller.controller.controller', 'controller')
content = content.replace('controller.controller', 'controller')

with open('e:/Projects/Money_Tracker/lib/ui/settings/settings_view.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("Double replacements fixed!")

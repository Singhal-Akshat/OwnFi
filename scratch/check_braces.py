def check_braces_optimized():
    with open(r"e:\Projects\Money_Tracker\lib\ui\settings\settings_view.dart", "r", encoding="utf-8") as f:
        content = f.read()

    # Pre-split lines to display line contents easily
    lines = content.split('\n')
    
    state = 'code'
    i = 0
    n = len(content)
    
    stack = []
    
    # Track position dynamically
    line_num = 1
    col = 1
    
    string_interpolation_stack = []

    while i < n:
        char = content[i]
        
        # Helper to get current line text
        def get_line_text(l_num):
            if 0 < l_num <= len(lines):
                return lines[l_num - 1].strip()
            return ""

        if state == 'code':
            # Check comment start
            if i + 1 < n and content[i:i+2] == '//':
                state = 'single_line_comment'
                i += 2
                col += 2
                continue
            elif i + 1 < n and content[i:i+2] == '/*':
                state = 'multi_line_comment'
                i += 2
                col += 2
                continue
            # Check triple quotes
            elif i + 2 < n and content[i:i+3] == "'''":
                state = 'string_triple_single'
                i += 3
                col += 3
                continue
            elif i + 2 < n and content[i:i+3] == '"""':
                state = 'string_triple_double'
                i += 3
                col += 3
                continue
            # Check single quotes
            elif char == "'":
                state = 'string_single'
                i += 1
                col += 1
                continue
            elif char == '"':
                state = 'string_double'
                i += 1
                col += 1
                continue
            
            # Count braces/parens/brackets in code
            if char in "{[(":
                stack.append((char, line_num, col, get_line_text(line_num), i))
            elif char in "}])":
                if not stack:
                    print(f"Extra closing char {char} at line {line_num}:{col} - {get_line_text(line_num)}")
                    i += 1
                    col += 1
                    continue
                open_char, o_line, o_col, o_text, o_pos = stack[-1]
                
                # Check matching
                if (char == "}" and open_char == "{") or \
                   (char == "]" and open_char == "[") or \
                   (char == ")" and open_char == "("):
                    stack.pop()
                    # If we popped a '}' and we were inside a string interpolation, return to string state
                    if char == "}" and string_interpolation_stack:
                        state = string_interpolation_stack.pop()
                else:
                    print(f"Mismatch: open {open_char} at {o_line}:{o_col} ({o_text}) does not match close {char} at {line_num}:{col} ({get_line_text(line_num)})")
                    stack.pop()
            
            # Advance character position
            if char == '\n':
                line_num += 1
                col = 1
            else:
                col += 1
            i += 1

        elif state == 'single_line_comment':
            if char == '\n':
                state = 'code'
                line_num += 1
                col = 1
            else:
                col += 1
            i += 1
            
        elif state == 'multi_line_comment':
            if i + 1 < n and content[i:i+2] == '*/':
                state = 'code'
                i += 2
                col += 2
            else:
                if char == '\n':
                    line_num += 1
                    col = 1
                else:
                    col += 1
                i += 1
                
        elif state in ('string_single', 'string_double', 'string_triple_single', 'string_triple_double'):
            # Check for escape char
            if char == '\\':
                if i + 1 < n:
                    next_char = content[i+1]
                    if next_char == '\n':
                        line_num += 1
                        col = 1
                    else:
                        col += 2
                    i += 2
                else:
                    i += 1
                    col += 1
                continue
                
            # Check for string interpolation '${'
            if i + 1 < n and content[i:i+2] == '${':
                string_interpolation_stack.append(state)
                stack.append(('{', line_num, col + 1, get_line_text(line_num), i + 1))
                state = 'code'
                i += 2
                col += 2
                continue
                
            # Check string end
            string_ended = False
            if state == 'string_single' and char == "'":
                string_ended = True
                i += 1
                col += 1
            elif state == 'string_double' and char == '"':
                string_ended = True
                i += 1
                col += 1
            elif state == 'string_triple_single' and i + 2 < n and content[i:i+3] == "'''":
                string_ended = True
                i += 3
                col += 3
            elif state == 'string_triple_double' and i + 2 < n and content[i:i+3] == '"""':
                string_ended = True
                i += 3
                col += 3
                
            if string_ended:
                state = 'code'
                continue
                
            if char == '\n':
                line_num += 1
                col = 1
            else:
                col += 1
            i += 1

        if line_num in (2670, 2671, 2673, 2759, 2761, 4022, 4024) and col == 1:
            print(f"Stack at line {line_num}: {[x[0] for x in stack]} (last: {stack[-1][3] if stack else 'None'}, line: {stack[-1][1] if stack else 0})")

        if i >= n - 20:
            print(f"DEBUG EOF: i={i}/{n}, char={repr(content[i-1] if i > 0 else '')}, state={state}, stack_len={len(stack)}")

    print(f"\nParser finished in state: {state}")
    print(f"String interpolation stack: {string_interpolation_stack}")
    print("\n--- Remaining open braces in stack ---")
    for char, line_num, col, text, pos in stack:
        print(f"Line {line_num}:{col} - {char} : {text}")

if __name__ == "__main__":
    check_braces_optimized()

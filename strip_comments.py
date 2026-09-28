import os
import re

def strip_comments(code):
    # Regex to match strings (single and double quotes, multi-line) and comments (//, /* */)
    pattern = r'(\'\'\'[\s\S]*?\'\'\'|\"\"\"[\s\S]*?\"\"\"|\"[^\"]*\"|\'[^\']*\')|(\/\*[\s\S]*?\*\/|\/\/.*)'
    
    def replacer(match):
        # If group 1 matched, it's a string, keep it.
        if match.group(1) is not None:
            return match.group(1)
        # Otherwise, it's a comment, remove it.
        else:
            return ''

    # Replace comments with empty strings
    stripped = re.sub(pattern, replacer, code)
    
    # Remove empty lines left behind by comment removal
    # but keep single empty lines for readability
    stripped = re.sub(r'\n\s*\n', '\n\n', stripped)
    return stripped

lib_dir = 'lib'
count = 0
for root, dirs, files in os.walk(lib_dir):
    for file in files:
        if file.endswith('.dart'):
            path = os.path.join(root, file)
            with open(path, 'r', encoding='utf-8') as f:
                content = f.read()
            new_content = strip_comments(content)
            if content != new_content:
                with open(path, 'w', encoding='utf-8') as f:
                    f.write(new_content)
                count += 1
print(f'Processed {count} files.')

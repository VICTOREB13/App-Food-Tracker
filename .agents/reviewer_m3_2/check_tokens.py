import re

with open('test/services/gemini_and_storage_adversarial_test.dart', 'r', encoding='utf-8') as f:
    code = f.read()

# Remove comments
code_no_comments = re.sub(r'//.*', '', code)
# Remove multiline strings
code_no_strings = re.sub(r"'''[\s\S]*?'''", '', code_no_comments)
code_no_strings = re.sub(r'"""[\s\S]*?"""', '', code_no_strings)
# Remove single/double quote strings
code_no_strings = re.sub(r'"(\\.|[^"\\])*"', '', code_no_strings)
code_no_strings = re.sub(r"'(\\.|[^'\\])*'", '', code_no_strings)

b_open = code_no_strings.count('{')
b_close = code_no_strings.count('}')
print(f'Code tokens without strings: {{ = {b_open}, }} = {b_close}')

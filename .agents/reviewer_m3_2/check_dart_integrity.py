import glob
import sys

files = glob.glob('lib/**/*.dart', recursive=True) + glob.glob('test/**/*.dart', recursive=True)
print('Total Dart files checked: ' + str(len(files)))
errors = []
for f in files:
    with open(f, 'r', encoding='utf-8') as fh:
        c = fh.read()
    b_open = c.count('{')
    b_close = c.count('}')
    if b_open != b_close:
        errors.append(f + ': mismatched braces ' + str(b_open) + ' vs ' + str(b_close))
    p_open = c.count('(')
    p_close = c.count(')')
    if p_open != p_close:
        errors.append(f + ': mismatched parens ' + str(p_open) + ' vs ' + str(p_close))
    k_open = c.count('[')
    k_close = c.count(']')
    if k_open != k_close:
        errors.append(f + ': mismatched brackets ' + str(k_open) + ' vs ' + str(k_close))

if errors:
    print('ERRORS FOUND:')
    for e in errors:
        print(e)
    sys.exit(1)
else:
    print('ALL DART FILES PASS BRACKET AND PARENTHESIS INTEGRITY (100% BALANCED)!')

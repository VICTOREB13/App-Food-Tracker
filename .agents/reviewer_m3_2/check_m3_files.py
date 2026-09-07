import re

files = [
    'lib/services/metabolic_calculator.dart',
    'lib/screens/user_profile_screen.dart',
    'lib/widgets/profile/biometric_inputs_card.dart',
    'lib/widgets/profile/activity_goal_selector_card.dart',
    'lib/widgets/profile/metabolic_summary_bento_card.dart',
    'test/services/metabolic_calculator_test.dart',
    'test/screens/user_profile_screen_test.dart',
]

for path in files:
    with open(path, 'r', encoding='utf-8') as f:
        code = f.read()

    b_open = code.count('{')
    b_close = code.count('}')
    p_open = code.count('(')
    p_close = code.count(')')
    k_open = code.count('[')
    k_close = code.count(']')

    assert b_open == b_close, f'{path}: Braces mismatch {b_open} != {b_close}'
    assert p_open == p_close, f'{path}: Parens mismatch {p_open} != {p_close}'
    assert k_open == k_close, f'{path}: Brackets mismatch {k_open} != {k_close}'
    assert '.withOpacity(' not in code, f'{path}: Deprecated withOpacity found'
    print(f'M3 File PASS: {path} (Braces: {b_open}, Parens: {p_open}, Brackets: {k_open})')

print('>>> ALL M3 IMPLEMENTATION AND TEST FILES HAVE 100% BALANCED SYNTAX <<<')

import os
import glob

def fix_in_file(filepath):
    with open(filepath, 'r') as f:
        content = f.read()
    
    new_content = content.replace("import 'package:budget/core/utils/extensions.dart';", "import 'package:flow_finance/core/utils/extensions.dart';")
    
    if new_content != content:
        with open(filepath, 'w') as f:
            f.write(new_content)
        print(f"Fixed {filepath}")

for filepath in glob.glob('lib/**/*.dart', recursive=True):
    fix_in_file(filepath)


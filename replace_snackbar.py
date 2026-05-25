import os
import glob
import re

def replace_in_file(filepath):
    with open(filepath, 'r') as f:
        content = f.read()
    
    # Replace ScaffoldMessenger.of(context).showSnackBar with context.showSnackBar
    new_content = re.sub(r'ScaffoldMessenger\.of\(context\)\.showSnackBar\(', r'context.showSnackBar(', content)
    
    if new_content != content:
        # Also need to make sure extensions are imported if context.showSnackBar is used
        if 'package:budget/core/utils/extensions.dart' not in new_content and '../../core/utils/extensions.dart' not in new_content:
            # Try to add import at the top
            lines = new_content.split('\n')
            import_idx = 0
            for i, line in enumerate(lines):
                if line.startswith('import '):
                    import_idx = i
            
            # calculate relative path or use package path
            lines.insert(import_idx, "import 'package:budget/core/utils/extensions.dart';")
            new_content = '\n'.join(lines)
            
        with open(filepath, 'w') as f:
            f.write(new_content)
        print(f"Updated {filepath}")

for filepath in glob.glob('lib/**/*.dart', recursive=True):
    replace_in_file(filepath)


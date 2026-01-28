#!/usr/bin/env python3
"""
Initialize a new skill directory with template structure.

Usage: init_skill.py <skill-name> --path <output-directory>
"""

import argparse
import os
import re
import sys

SKILL_MD_TEMPLATE = '''---
name: {skill_name}
description: TODO - Describe what this skill does and when it should be used. Include specific triggers/contexts.
---

# {skill_title}

TODO: Add instructions for using this skill.

## Overview

TODO: Describe what this skill provides.

## Usage

TODO: Describe how to use this skill.

## Resources

- `scripts/` - Executable code for deterministic tasks
- `references/` - Documentation to load as needed
- `assets/` - Files used in output (templates, etc.)
'''

EXAMPLE_SCRIPT = '''#!/usr/bin/env python3
"""
Example script - customize or delete as needed.
"""

def main():
    print("Hello from example script!")

if __name__ == "__main__":
    main()
'''

EXAMPLE_REFERENCE = '''# Example Reference

This is an example reference file. Customize or delete as needed.

## Contents

Add domain-specific documentation here.
'''


def validate_skill_name(name: str) -> bool:
    """Validate skill name follows hyphen-case convention."""
    if len(name) > 40:
        return False
    if not re.match(r'^[a-z][a-z0-9]*(-[a-z0-9]+)*$', name):
        return False
    return True


def create_skill(skill_name: str, output_path: str) -> None:
    """Create a new skill directory with template structure."""
    skill_dir = os.path.join(output_path, skill_name)

    if os.path.exists(skill_dir):
        print(f"Error: Directory already exists: {skill_dir}")
        sys.exit(1)

    # Create directories
    os.makedirs(skill_dir)
    os.makedirs(os.path.join(skill_dir, 'scripts'))
    os.makedirs(os.path.join(skill_dir, 'references'))
    os.makedirs(os.path.join(skill_dir, 'assets'))

    # Create SKILL.md
    skill_title = skill_name.replace('-', ' ').title()
    skill_md_content = SKILL_MD_TEMPLATE.format(
        skill_name=skill_name,
        skill_title=skill_title
    )
    with open(os.path.join(skill_dir, 'SKILL.md'), 'w') as f:
        f.write(skill_md_content)

    # Create example files
    with open(os.path.join(skill_dir, 'scripts', 'example.py'), 'w') as f:
        f.write(EXAMPLE_SCRIPT)

    with open(os.path.join(skill_dir, 'references', 'example.md'), 'w') as f:
        f.write(EXAMPLE_REFERENCE)

    with open(os.path.join(skill_dir, 'assets', '.gitkeep'), 'w') as f:
        f.write('')

    print(f"Created skill at: {skill_dir}")
    print("\nNext steps:")
    print("1. Edit SKILL.md with your skill's instructions")
    print("2. Add scripts, references, and assets as needed")
    print("3. Delete example files you don't need")
    print("4. Run package_skill.py when ready to distribute")


def main():
    parser = argparse.ArgumentParser(description='Initialize a new skill')
    parser.add_argument('skill_name', help='Name of the skill (hyphen-case)')
    parser.add_argument('--path', required=True, help='Output directory')

    args = parser.parse_args()

    if not validate_skill_name(args.skill_name):
        print("Error: Skill name must be hyphen-case (lowercase letters, digits, hyphens)")
        print("       Max 40 characters, cannot start/end with hyphen")
        sys.exit(1)

    create_skill(args.skill_name, args.path)


if __name__ == '__main__':
    main()

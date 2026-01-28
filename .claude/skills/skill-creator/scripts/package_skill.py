#!/usr/bin/env python3
"""
Package a skill into a distributable .skill file.

Usage: package_skill.py <path/to/skill-folder> [output-directory]
"""

import argparse
import os
import subprocess
import sys
import zipfile


def validate_skill(skill_path: str) -> bool:
    """Run validation before packaging."""
    validator = os.path.join(os.path.dirname(__file__), 'quick_validate.py')
    if os.path.exists(validator):
        result = subprocess.run([sys.executable, validator, skill_path])
        return result.returncode == 0
    return True


def package_skill(skill_path: str, output_dir: str = None) -> None:
    """Create a .skill file from a skill directory."""
    if not os.path.isdir(skill_path):
        print(f"Error: Not a directory: {skill_path}")
        sys.exit(1)

    skill_md = os.path.join(skill_path, 'SKILL.md')
    if not os.path.exists(skill_md):
        print(f"Error: SKILL.md not found in {skill_path}")
        sys.exit(1)

    # Run validation
    print("Validating skill...")
    if not validate_skill(skill_path):
        print("Error: Validation failed. Fix errors and try again.")
        sys.exit(1)

    print("Validation passed.")

    # Determine output path
    skill_name = os.path.basename(os.path.normpath(skill_path))
    if output_dir:
        os.makedirs(output_dir, exist_ok=True)
        output_file = os.path.join(output_dir, f"{skill_name}.skill")
    else:
        output_file = f"{skill_name}.skill"

    # Create zip archive
    print(f"Packaging {skill_name}...")
    with zipfile.ZipFile(output_file, 'w', zipfile.ZIP_DEFLATED) as zf:
        for root, dirs, files in os.walk(skill_path):
            for file in files:
                file_path = os.path.join(root, file)
                arcname = os.path.relpath(file_path, skill_path)
                zf.write(file_path, arcname)

    print(f"Created: {output_file}")


def main():
    parser = argparse.ArgumentParser(description='Package a skill')
    parser.add_argument('skill_path', help='Path to skill folder')
    parser.add_argument('output_dir', nargs='?', help='Output directory (optional)')

    args = parser.parse_args()
    package_skill(args.skill_path, args.output_dir)


if __name__ == '__main__':
    main()

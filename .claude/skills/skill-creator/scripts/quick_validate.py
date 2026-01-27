#!/usr/bin/env python3
"""
Validate a skill directory meets requirements.

Usage: quick_validate.py <path/to/skill-folder>
"""

import argparse
import os
import re
import sys
import yaml


ALLOWED_PROPERTIES = {'name', 'description', 'license', 'allowed-tools', 'metadata'}
MAX_NAME_LENGTH = 64
MAX_DESCRIPTION_LENGTH = 1024


def validate_name(name: str) -> list[str]:
    """Validate skill name format."""
    errors = []

    if not isinstance(name, str):
        errors.append("name must be a string")
        return errors

    if len(name) > MAX_NAME_LENGTH:
        errors.append(f"name exceeds {MAX_NAME_LENGTH} characters")

    if not re.match(r'^[a-z][a-z0-9]*(-[a-z0-9]+)*$', name):
        errors.append("name must be hyphen-case (lowercase letters, digits, hyphens)")

    if name.startswith('-') or name.endswith('-'):
        errors.append("name cannot start or end with hyphen")

    if '--' in name:
        errors.append("name cannot contain consecutive hyphens")

    return errors


def validate_description(description: str) -> list[str]:
    """Validate description format."""
    errors = []

    if not isinstance(description, str):
        errors.append("description must be a string")
        return errors

    if len(description) > MAX_DESCRIPTION_LENGTH:
        errors.append(f"description exceeds {MAX_DESCRIPTION_LENGTH} characters")

    if '<' in description or '>' in description:
        errors.append("description cannot contain angle brackets")

    return errors


def validate_skill(skill_path: str) -> bool:
    """Validate a skill directory."""
    errors = []

    # Check SKILL.md exists
    skill_md = os.path.join(skill_path, 'SKILL.md')
    if not os.path.exists(skill_md):
        print(f"Error: SKILL.md not found in {skill_path}")
        return False

    # Read and parse SKILL.md
    with open(skill_md, 'r') as f:
        content = f.read()

    # Extract YAML frontmatter
    if not content.startswith('---'):
        print("Error: SKILL.md must start with YAML frontmatter (---)")
        return False

    try:
        parts = content.split('---', 2)
        if len(parts) < 3:
            print("Error: Invalid YAML frontmatter format")
            return False

        frontmatter = yaml.safe_load(parts[1])
    except yaml.YAMLError as e:
        print(f"Error: Invalid YAML: {e}")
        return False

    if not isinstance(frontmatter, dict):
        print("Error: Frontmatter must be a YAML dictionary")
        return False

    # Check required fields
    if 'name' not in frontmatter:
        errors.append("Missing required field: name")
    else:
        errors.extend(validate_name(frontmatter['name']))

    if 'description' not in frontmatter:
        errors.append("Missing required field: description")
    else:
        errors.extend(validate_description(frontmatter['description']))

    # Check for unknown properties
    for key in frontmatter:
        if key not in ALLOWED_PROPERTIES:
            errors.append(f"Unknown property: {key}")

    # Report errors
    if errors:
        print("Validation errors:")
        for error in errors:
            print(f"  - {error}")
        return False

    print("Validation passed!")
    return True


def main():
    parser = argparse.ArgumentParser(description='Validate a skill')
    parser.add_argument('skill_path', help='Path to skill folder')

    args = parser.parse_args()

    if not os.path.isdir(args.skill_path):
        print(f"Error: Not a directory: {args.skill_path}")
        sys.exit(1)

    success = validate_skill(args.skill_path)
    sys.exit(0 if success else 1)


if __name__ == '__main__':
    main()

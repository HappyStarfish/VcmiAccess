#!/usr/bin/env python3
"""
Distribute accessibility strings to all language JSON files.

Usage:
    python tools/distribute_strings.py input.json [--dry-run] [--delete]

Input JSON format:
{
    "string_key": {
        "en": "English text",
        "de": "German text"
        // Other languages optional, fallback = English
    }
}

With --delete, removes the specified keys from all language files.
"""

import json
import sys
import os
import glob
import argparse


def main():
    parser = argparse.ArgumentParser(description="Distribute accessibility strings")
    parser.add_argument("input_file", help="JSON input file with strings")
    parser.add_argument("--dry-run", action="store_true", help="Show what would be changed")
    parser.add_argument("--delete", action="store_true", help="Delete specified keys")
    args = parser.parse_args()

    # Find the config directory
    script_dir = os.path.dirname(os.path.abspath(__file__))
    project_root = os.path.dirname(script_dir)
    config_dir = os.path.join(project_root, "vcmi-1.7.2", "config", "accessibility")

    if not os.path.isdir(config_dir):
        # Try relative to script location
        config_dir = os.path.join(project_root, "config", "accessibility")

    if not os.path.isdir(config_dir):
        print(f"Error: Cannot find accessibility config directory")
        sys.exit(1)

    # Load input
    with open(args.input_file, "r", encoding="utf-8") as f:
        new_strings = json.load(f)

    # Find all language files
    lang_files = sorted(glob.glob(os.path.join(config_dir, "accessibility_*.json")))
    if not lang_files:
        print("Error: No language files found")
        sys.exit(1)

    print(f"Found {len(lang_files)} language files")
    print(f"Processing {len(new_strings)} string(s)")

    for lang_file in lang_files:
        basename = os.path.basename(lang_file)
        # Extract language code: accessibility_en.json -> en
        lang_code = basename.replace("accessibility_", "").replace(".json", "")

        with open(lang_file, "r", encoding="utf-8") as f:
            data = json.load(f)

        changed = False
        for key, translations in new_strings.items():
            if args.delete:
                if key in data:
                    if args.dry_run:
                        print(f"  [{lang_code}] Would delete: {key}")
                    else:
                        del data[key]
                    changed = True
            else:
                # Use language-specific text if available, fallback to English
                value = translations.get(lang_code, translations.get("en", ""))
                if key not in data or data[key] != value:
                    if args.dry_run:
                        print(f"  [{lang_code}] {key} = {value}")
                    else:
                        data[key] = value
                    changed = True

        if changed and not args.dry_run:
            # Sort keys alphabetically and write back
            sorted_data = dict(sorted(data.items()))
            with open(lang_file, "w", encoding="utf-8") as f:
                json.dump(sorted_data, f, ensure_ascii=False, indent="\t")
                f.write("\n")
            print(f"  Updated: {basename}")
        elif not changed:
            if args.dry_run:
                print(f"  [{lang_code}] No changes needed")

    print("Done!")


if __name__ == "__main__":
    main()

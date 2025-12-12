#!/usr/bin/env python3
"""Find all CLAUDE.md files in a directory tree."""

import os
import sys
from pathlib import Path

TARGET_FILENAME = "CLAUDE.md"


def find_claude_md_files(root_dir="."):
    """
    Find all CLAUDE.md files in the directory tree.

    Args:
        root_dir: Directory to start searching from (default: current directory)

    Returns:
        List of paths to CLAUDE.md files, sorted by depth (root first)
    """
    claude_md_files = []
    root_path = Path(root_dir).resolve()

    for dirpath, dirnames, filenames in os.walk(root_path):
        if TARGET_FILENAME in filenames:
            file_path = Path(dirpath) / TARGET_FILENAME
            rel_path = file_path.relative_to(root_path)
            claude_md_files.append(str(rel_path))

    # Sort by depth (root first, then by path)
    claude_md_files.sort(key=lambda p: (p.count(os.sep), p))

    return claude_md_files


def main():
    """Main entry point."""
    root_dir = sys.argv[1] if len(sys.argv) > 1 else "."

    files = find_claude_md_files(root_dir)

    if not files:
        sys.exit(f"No {TARGET_FILENAME} files found")

    for file_path in files:
        print(file_path)


if __name__ == "__main__":
    main()

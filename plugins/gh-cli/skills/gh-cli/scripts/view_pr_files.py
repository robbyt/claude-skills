#!/usr/bin/env python3
"""
View files changed in a GitHub Pull Request using the gh CLI.

Usage:
    python view_pr_files.py <pr-number-or-url> [options]

Options:
    --list              List changed files only (no content)
    --file <path>       Show content for specific file
    --diff              Show full diff (default)

Examples:
    python view_pr_files.py 123 --list
    python view_pr_files.py https://github.com/user/repo/pull/123 --file path/to/file.go
    python view_pr_files.py 123 --diff
"""

import sys
import re
import subprocess
import argparse
import json
import base64
import urllib.parse
from typing import Optional, List


def parse_pr_reference(pr_ref: str) -> Optional[int]:
    """
    Parse PR reference (number or URL) and extract PR number.

    Args:
        pr_ref: PR number (e.g., "123") or URL (e.g., "https://github.com/user/repo/pull/123")

    Returns:
        int: PR number or None if invalid
    """
    if pr_ref.isdigit():
        return int(pr_ref)

    pattern = r"https?://github\.com/[^/]+/[^/]+/pull/(\d+)"
    match = re.match(pattern, pr_ref)

    if match:
        return int(match.group(1))

    return None


def list_pr_files(pr_number: int) -> Optional[List[str]]:
    """
    List all files changed in a PR.

    Args:
        pr_number: PR number

    Returns:
        list: List of changed file paths or None on error
    """
    try:
        result = subprocess.run(
            [
                "gh",
                "pr",
                "view",
                str(pr_number),
                "--json",
                "files",
                "--jq",
                ".files[].path",
            ],
            capture_output=True,
            text=True,
            check=True,
        )

        files = result.stdout.strip().split("\n")
        return [f for f in files if f]

    except subprocess.CalledProcessError as e:
        print(f"Error fetching PR files: {e.stderr}", file=sys.stderr)
        return None


def show_pr_diff(pr_number: int, file_path: Optional[str] = None) -> Optional[str]:
    """
    Show PR diff, optionally filtered to a specific file.

    Args:
        pr_number: PR number
        file_path: Optional file path to filter diff

    Returns:
        str: Diff content or None on error
    """
    try:
        cmd = ["gh", "pr", "diff", str(pr_number)]

        if file_path:
            cmd.extend(["--", file_path])

        result = subprocess.run(cmd, capture_output=True, text=True, check=True)

        return result.stdout

    except subprocess.CalledProcessError as e:
        print(f"Error fetching PR diff: {e.stderr}", file=sys.stderr)
        return None


def show_file_content(pr_number: int, file_path: str) -> Optional[str]:
    """
    Show the new version of a file from a PR.

    Args:
        pr_number: PR number
        file_path: File path to view

    Returns:
        str: File content or None on error
    """
    try:
        result = subprocess.run(
            ["gh", "pr", "view", str(pr_number), "--json", "headRefName"],
            capture_output=True,
            text=True,
            check=True,
        )

        head_ref = json.loads(result.stdout)["headRefName"]

        safe_path = urllib.parse.quote(file_path, safe="")

        result = subprocess.run(
            [
                "gh",
                "api",
                f"repos/{{owner}}/{{repo}}/contents/{safe_path}?ref={head_ref}",
            ],
            capture_output=True,
            text=True,
            check=True,
        )

        response = json.loads(result.stdout)

        if "content" not in response:
            print("Error: File not found or is a directory", file=sys.stderr)
            return None

        content_b64 = response["content"].replace("\n", "")

        try:
            content = base64.b64decode(content_b64).decode("utf-8")
            return content
        except UnicodeDecodeError:
            print(
                f"Error: Unable to decode file content (likely binary or non-UTF-8).",
                file=sys.stderr,
            )
            return None

    except subprocess.CalledProcessError as e:
        print(f"Error fetching file content: {e.stderr}", file=sys.stderr)
        return None
    except Exception as e:
        print(f"Unexpected error: {e}", file=sys.stderr)
        return None


def main() -> None:
    parser = argparse.ArgumentParser(
        description="View files changed in a GitHub Pull Request",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__,
    )

    parser.add_argument("pr_ref", help="PR number or URL")

    mode_group = parser.add_mutually_exclusive_group()
    mode_group.add_argument(
        "--list", action="store_true", help="List changed files only"
    )
    mode_group.add_argument(
        "--file", metavar="PATH", help="Show content for specific file"
    )
    mode_group.add_argument(
        "--diff", action="store_true", help="Show full diff (default)"
    )

    args = parser.parse_args()

    pr_number = parse_pr_reference(args.pr_ref)
    if pr_number is None:
        print(f"Error: Invalid PR reference: {args.pr_ref}", file=sys.stderr)
        print(
            "Expected: PR number (e.g., '123') or URL (e.g., 'https://github.com/user/repo/pull/123')",
            file=sys.stderr,
        )
        sys.exit(1)

    if args.list:
        files = list_pr_files(pr_number)
        if files is None:
            sys.exit(1)

        print(f"Files changed in PR #{pr_number}:", file=sys.stderr)
        for f in files:
            print(f)

    elif args.file:
        content = show_file_content(pr_number, args.file)
        if content is None:
            sys.exit(1)

        print(f"File: {args.file} (from PR #{pr_number})", file=sys.stderr)
        print(content)

    else:
        diff = show_pr_diff(pr_number, args.file)
        if diff is None:
            sys.exit(1)

        print(diff)


if __name__ == "__main__":
    main()

#!/usr/bin/env python3
"""
View raw file content from a GitHub URL using the gh CLI.

Usage:
    python view_github_file.py <github-url>

Example:
    python view_github_file.py https://github.com/user/repo/blob/main/path/to/file.go
"""

import sys
import re
import subprocess
import shutil
from typing import Optional, Tuple


def parse_github_url(url: str) -> Optional[Tuple[str, str, str, str]]:
    """
    Parse a GitHub file URL and extract components.

    Supports formats:
    - https://github.com/{owner}/{repo}/blob/{ref}/{path}
    - https://github.com/{owner}/{repo}/tree/{ref}/{path}

    Note: This regex has limitations with branch names containing slashes
    (e.g., feature/branch). The regex captures the first path segment after
    blob/tree as the ref, which may not work for all branch naming patterns.

    Returns:
        tuple: (owner, repo, ref, path) or None if invalid
    """
    pattern = r"https?://github\.com/([^/]+)/([^/]+)/(?:blob|tree)/([^/]+)/(.+)"
    match = re.match(pattern, url)

    if not match:
        return None

    owner, repo, ref, path = match.groups()
    return owner, repo, ref, path


def fetch_file_content(owner: str, repo: str, ref: str, path: str) -> Optional[str]:
    """
    Fetch file content from GitHub using gh CLI with raw media type.

    Args:
        owner: Repository owner
        repo: Repository name
        ref: Branch, tag, or commit SHA
        path: File path within repository

    Returns:
        str: File content or None on error
    """
    if not shutil.which("gh"):
        print("Error: 'gh' CLI tool is not installed or not in PATH.", file=sys.stderr)
        return None

    api_path = f"repos/{owner}/{repo}/contents/{path}?ref={ref}"

    try:
        result = subprocess.run(
            ["gh", "api", "-H", "Accept: application/vnd.github.v3.raw", api_path],
            capture_output=True,
            check=True,
        )

        return result.stdout.decode("utf-8")

    except UnicodeDecodeError:
        print(
            f"Error: File at '{path}' appears to be binary or non-UTF-8 text.",
            file=sys.stderr,
        )
        return None
    except subprocess.CalledProcessError as e:
        error_msg = e.stderr.decode("utf-8").strip() if e.stderr else "Unknown error"
        print(f"Error calling gh API: {error_msg}", file=sys.stderr)
        return None
    except Exception as e:
        print(f"Unexpected error: {e}", file=sys.stderr)
        return None


def main() -> None:
    if len(sys.argv) != 2:
        print(__doc__)
        sys.exit(1)

    url = sys.argv[1]

    parsed = parse_github_url(url)
    if not parsed:
        print(f"Error: Invalid GitHub URL format: {url}", file=sys.stderr)
        print(
            "Expected format: https://github.com/owner/repo/blob/ref/path/to/file",
            file=sys.stderr,
        )
        sys.exit(1)

    owner, repo, ref, path = parsed

    print(f"Fetching: {owner}/{repo} @ {ref}:{path}", file=sys.stderr)

    content = fetch_file_content(owner, repo, ref, path)

    if content is None:
        sys.exit(1)

    print(content)


if __name__ == "__main__":
    main()

#!/usr/bin/env python3
"""Small repo-local Markdown verifier.

This intentionally enforces the Markdown rules that have recently broken CI in
this umbrella repo without requiring Node, bunx, or markdownlint-cli2.
"""
from __future__ import annotations

import fnmatch
import sys
from pathlib import Path

EXCLUDE_PARTS = {".git", ".omc", "lifeos", "node_modules", "repos"}
EXCLUDE_PREFIXES = ("wiki/raw/", "network/slim/")
ALLOWED_FENCE_PREFIXES = ("```", "~~~")


def should_skip(path: Path) -> bool:
    rel = path.as_posix()
    if rel.startswith("tools/") and rel != "tools/README.md":
        return True
    if any(part in EXCLUDE_PARTS for part in path.parts):
        return True
    return any(rel.startswith(prefix) for prefix in EXCLUDE_PREFIXES)


def iter_markdown(root: Path) -> list[Path]:
    return sorted(
        path for path in root.rglob("*.md")
        if path.is_file() and not should_skip(path.relative_to(root))
    )


def check_file(path: Path, root: Path) -> list[str]:
    errors: list[str] = []
    in_fence = False
    fence_marker = ""
    for lineno, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        stripped = line.strip()
        marker = next((prefix for prefix in ALLOWED_FENCE_PREFIXES if stripped.startswith(prefix)), "")
        if not marker:
            continue
        if not in_fence:
            language = stripped[len(marker):].strip()
            if not language:
                errors.append(f"{path.relative_to(root)}:{lineno}: fenced code block needs a language")
            in_fence = True
            fence_marker = marker
        elif stripped.startswith(fence_marker):
            in_fence = False
            fence_marker = ""
    if in_fence:
        errors.append(f"{path.relative_to(root)}: unclosed fenced code block")
    return errors


def main() -> int:
    root = Path(sys.argv[1]) if len(sys.argv) > 1 else Path.cwd()
    root = root.resolve()
    files = iter_markdown(root)
    errors: list[str] = []
    for path in files:
        errors.extend(check_file(path, root))
    if errors:
        for error in errors:
            print(f"ERROR: {error}", file=sys.stderr)
        print(f"Summary: {len(errors)} error(s)", file=sys.stderr)
        return 1
    print(f"OK: {len(files)} markdown files checked")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

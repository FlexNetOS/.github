#!/usr/bin/env python3
"""Validate repos/MANIFEST.yaml without yq or PyYAML.

This is intentionally a small parser for the manifest subset this repo uses:
- top-level list of mappings
- scalar string values
- inline lists: [node, cargo]
- block scalars with `|`
- comments and blank lines

It is not a general YAML parser. If the manifest grows beyond this subset,
update this script before adding an external dependency.
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

REQUIRED = ("path", "url", "branch")
GITHUB_PREFIX = "https://github.com/"
INLINE_LIST_RE = re.compile(r"^\[(.*)\]$")
KEY_RE = re.compile(r"^([A-Za-z_][A-Za-z0-9_-]*):(?:\s*(.*))?$")


def strip_inline_comment(value: str) -> str:
    in_single = False
    in_double = False
    for i, ch in enumerate(value):
        if ch == "'" and not in_double:
            in_single = not in_single
        elif ch == '"' and not in_single:
            in_double = not in_double
        elif ch == "#" and not in_single and not in_double:
            if i == 0 or value[i - 1].isspace():
                return value[:i].rstrip()
    return value.rstrip()


def parse_value(raw: str) -> object:
    raw = strip_inline_comment(raw.strip())
    if raw == "":
        return ""
    if (raw.startswith('"') and raw.endswith('"')) or (raw.startswith("'") and raw.endswith("'")):
        return raw[1:-1]
    m = INLINE_LIST_RE.match(raw)
    if m:
        inner = m.group(1).strip()
        if not inner:
            return []
        return [item.strip().strip('"\'') for item in inner.split(",")]
    return raw


def parse_manifest(path: Path) -> list[dict[str, object]]:
    entries: list[dict[str, object]] = []
    current: dict[str, object] | None = None
    block_key: str | None = None
    block_indent: int | None = None
    block_lines: list[str] = []

    def finish_block() -> None:
        nonlocal block_key, block_indent, block_lines, current
        if block_key is not None and current is not None:
            current[block_key] = "\n".join(block_lines).rstrip("\n")
        block_key = None
        block_indent = None
        block_lines = []

    for lineno, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        raw = line.rstrip("\n")
        stripped = raw.strip()
        indent = len(raw) - len(raw.lstrip(" "))

        if block_key is not None:
            if stripped == "":
                block_lines.append("")
                continue
            if block_indent is None and indent > 0:
                block_indent = indent
            if block_indent is not None and indent >= block_indent:
                block_lines.append(raw[block_indent:])
                continue
            finish_block()

        if stripped == "" or stripped.startswith("#"):
            continue

        if raw.startswith("- "):
            finish_block()
            current = {}
            entries.append(current)
            rest = raw[2:].strip()
            if rest:
                m = KEY_RE.match(rest)
                if not m:
                    raise ValueError(f"line {lineno}: unsupported list item syntax: {raw}")
                key, value = m.group(1), m.group(2) or ""
                if value.strip() == "|":
                    block_key = key
                else:
                    current[key] = parse_value(value)
            continue

        if current is None:
            raise ValueError(f"line {lineno}: expected top-level list item")
        if indent < 2:
            raise ValueError(f"line {lineno}: expected indented mapping key")

        m = KEY_RE.match(raw.strip())
        if not m:
            raise ValueError(f"line {lineno}: unsupported mapping syntax: {raw}")
        key, value = m.group(1), m.group(2) or ""
        if value.strip() == "|":
            block_key = key
            block_indent = None
            block_lines = []
        else:
            current[key] = parse_value(value)

    finish_block()
    return entries


def validate(path: Path) -> int:
    try:
        entries = parse_manifest(path)
    except Exception as exc:  # noqa: BLE001 - command-line diagnostic
        print(f"ERROR: {path}: {exc}", file=sys.stderr)
        return 1

    errors: list[str] = []
    warnings: list[str] = []
    seen_paths: dict[str, int] = {}

    for idx, entry in enumerate(entries):
        for field in REQUIRED:
            value = entry.get(field)
            if not isinstance(value, str) or not value.strip():
                errors.append(f"entry {idx} missing required field: {field}")

        repo_path = str(entry.get("path", ""))
        if repo_path:
            if repo_path in seen_paths:
                errors.append(f"duplicate path: {repo_path} (entries {seen_paths[repo_path]} and {idx})")
            else:
                seen_paths[repo_path] = idx

        url = str(entry.get("url", ""))
        if url and not url.startswith(GITHUB_PREFIX):
            warnings.append(f"entry {idx} non-GitHub URL: {url}")

        groups = entry.get("groups")
        toolchain = entry.get("toolchain")
        if groups is not None and not isinstance(groups, list):
            errors.append(f"entry {idx} groups must be an inline list")
        if toolchain is not None and not isinstance(toolchain, list):
            errors.append(f"entry {idx} toolchain must be an inline list")

    for warning in warnings:
        print(f"WARNING: {warning}")
    if errors:
        for error in errors:
            print(f"ERROR: {error}", file=sys.stderr)
        return 1

    print(f"OK: {len(entries)} manifest entries parse")
    return 0


if __name__ == "__main__":
    manifest = Path(sys.argv[1]) if len(sys.argv) > 1 else Path("repos/MANIFEST.yaml")
    raise SystemExit(validate(manifest))

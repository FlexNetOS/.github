#!/usr/bin/env python3
"""Query this repo's simple YAML manifests without yq/PyYAML.

The parser supports the manifest subset used by repos/MANIFEST.yaml and
 tools/MANIFEST.yaml. Output is shell-friendly TSV so bash scripts can avoid a
runtime dependency on yq.
"""
from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path
from typing import Iterable

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


def scalar(entry: dict[str, object], key: str, default: str = "") -> str:
    value = entry.get(key, default)
    if isinstance(value, list):
        return " ".join(str(item) for item in value)
    if value is None:
        return default
    text = str(value)
    return default if text == "" else text


def list_value(entry: dict[str, object], key: str) -> str:
    value = entry.get(key, [])
    if isinstance(value, list):
        return " ".join(str(item) for item in value)
    return str(value) if value else ""


def emit_rows(entries: Iterable[dict[str, object]], fields: list[str]) -> None:
    for entry in entries:
        row: list[str] = []
        for field in fields:
            if field == "groups":
                row.append(list_value(entry, "groups"))
            elif field == "toolchain":
                row.append(list_value(entry, "toolchain"))
            elif field == "branch":
                row.append(scalar(entry, "branch", "main"))
            else:
                row.append(scalar(entry, field, ""))
        print("\t".join(row))


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("manifest", nargs="?", default="repos/MANIFEST.yaml")
    parser.add_argument("--fields", default="path,url,branch,partial_clone,groups,upstream")
    parser.add_argument("--count", action="store_true")
    args = parser.parse_args()

    try:
        entries = parse_manifest(Path(args.manifest))
    except Exception as exc:  # noqa: BLE001 - CLI diagnostic
        print(f"ERROR: {args.manifest}: {exc}", file=sys.stderr)
        return 1

    if args.count:
        print(len(entries))
        return 0

    fields = [field.strip() for field in args.fields.split(",") if field.strip()]
    emit_rows(entries, fields)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

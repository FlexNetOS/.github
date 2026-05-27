#!/usr/bin/env python3
"""Report non-hermetic patterns in workflows and scripts.

Default mode is advisory: it prints findings but exits 0. Use --fail to make new
runtime downloads/global installs block CI once the repo is ready.
"""
from __future__ import annotations

import argparse
import re
from dataclasses import dataclass
from pathlib import Path

PATTERNS: tuple[tuple[str, str, re.Pattern[str]], ...] = (
    ("remote-action", "GitHub Action fetched at runtime", re.compile(r"\buses:\s+[^./][^\s]+@")),
    ("curl-download", "curl downloads from network", re.compile(r"\bcurl\b.*https?://")),
    ("wget-download", "wget downloads from network", re.compile(r"\bwget\b.*https?://")),
    ("sudo-install", "installs into system path", re.compile(r"\bsudo\b|/usr/local/bin|/usr/bin")),
    ("package-manager", "package manager resolves deps at runtime", re.compile(r"\b(npx|npm ci|npm install|bunx|bun install|uv tool install|pip install|cargo install|go install)\b")),
    ("latest-pin", "uses moving latest/lts pin", re.compile(r"\b(latest|lts/\*)\b")),
    ("global-tool-check", "checks host PATH instead of repo-local tool first", re.compile(r"command -v\s+")),
)

SCAN_GLOBS = (
    ".github/workflows/*.yml",
    "scripts/*.sh",
    "scripts/*.py",
    "Makefile",
)

ALLOWLIST = {
    # The audit script must mention the patterns it detects.
    ("scripts/hermetic-audit.py", "remote-action"),
    ("scripts/hermetic-audit.py", "curl-download"),
    ("scripts/hermetic-audit.py", "wget-download"),
    ("scripts/hermetic-audit.py", "sudo-install"),
    ("scripts/hermetic-audit.py", "package-manager"),
    ("scripts/hermetic-audit.py", "latest-pin"),
    ("scripts/hermetic-audit.py", "global-tool-check"),
    # The Markdown verifier documents the package-manager tools it replaces.
    ("scripts/verify-markdown.py", "package-manager"),
}


@dataclass(frozen=True)
class Finding:
    path: Path
    line: int
    code: str
    message: str
    text: str


def iter_files(root: Path) -> list[Path]:
    files: set[Path] = set()
    for pattern in SCAN_GLOBS:
        files.update(path for path in root.glob(pattern) if path.is_file())
    return sorted(files)


def scan(root: Path) -> list[Finding]:
    findings: list[Finding] = []
    for path in iter_files(root):
        rel = path.relative_to(root).as_posix()
        for lineno, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
            stripped = line.strip()
            if not stripped or stripped.startswith("#"):
                continue
            for code, message, pattern in PATTERNS:
                if (rel, code) in ALLOWLIST:
                    continue
                if pattern.search(stripped):
                    findings.append(Finding(path.relative_to(root), lineno, code, message, stripped))
    return findings


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("root", nargs="?", default=".")
    parser.add_argument("--fail", action="store_true", help="exit non-zero when findings exist")
    args = parser.parse_args()

    root = Path(args.root).resolve()
    findings = scan(root)
    if not findings:
        print("OK: no hermeticity findings")
        return 0

    print(f"Hermetic audit: {len(findings)} finding(s)")
    for finding in findings:
        print(f"{finding.path}:{finding.line}: {finding.code}: {finding.message}")
        print(f"  {finding.text}")
    print("\nAdvisory mode: findings are tracked debt, not failures. Use --fail to enforce.")
    return 1 if args.fail else 0


if __name__ == "__main__":
    raise SystemExit(main())

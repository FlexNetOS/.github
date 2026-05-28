#!/usr/bin/env python3
"""Read-only FlexNetOS GitHub control-plane doctor.

This script intentionally does not mutate local files, host services, or GitHub
state. It inventories the repo-side automation surface and, when `gh` is
available, adds live GitHub signals.
"""

from __future__ import annotations

import argparse
import json
import shutil
import subprocess
import sys
from dataclasses import dataclass, asdict
from pathlib import Path
from typing import Iterable


ROOT = Path(__file__).resolve().parents[1]


@dataclass
class Check:
    area: str
    name: str
    status: str
    detail: str


def run(cmd: list[str], timeout: int = 20) -> tuple[int, str, str]:
    try:
        proc = subprocess.run(
            cmd,
            cwd=ROOT,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            timeout=timeout,
            check=False,
        )
        return proc.returncode, proc.stdout.strip(), proc.stderr.strip()
    except (OSError, subprocess.TimeoutExpired) as exc:
        return 124, "", str(exc)


def status(ok: bool, warning: bool = False) -> str:
    if ok:
        return "OK"
    if warning:
        return "WARN"
    return "MISSING"


def exists(path: str, area: str, name: str, detail: str | None = None) -> Check:
    p = ROOT / path
    return Check(area, name, status(p.exists()), detail or path)


def count_files(pattern: str) -> int:
    return len(list(ROOT.glob(pattern)))


def load_yamlish_manifest(path: Path) -> tuple[bool, str]:
    if not path.exists():
        return False, "missing"
    # Keep the doctor stdlib-only; the real structural validator is make verify.
    text = path.read_text(encoding="utf-8")
    manifest_markers = ("entries:", "repos:", "tools:", "- name:", "- path:", "url:", "branch:")
    if any(marker in text for marker in manifest_markers):
        return True, f"present ({len(text.splitlines())} lines)"
    return False, "present but does not look like a manifest"


def gh_json(args: list[str]) -> tuple[bool, object | str]:
    if not shutil.which("gh"):
        return False, "gh not installed"
    code, out, err = run(["gh", *args], timeout=30)
    if code != 0:
        return False, err or out or f"gh exited {code}"
    if not out:
        return True, None
    try:
        return True, json.loads(out)
    except json.JSONDecodeError:
        return True, out


def repo_checks() -> list[Check]:
    checks: list[Check] = []

    checks.extend(
        [
            exists("README.md", "baseline", "umbrella README"),
            exists("VISION.md", "baseline", "six-role vision"),
            exists("docs/automation.md", "baseline", "automation docs"),
            exists("docs/github-automation-roadmap.md", "baseline", "Ralph roadmap", warning_detail("planned queue lives here")),
            exists(".github/CODEOWNERS", "policy", "CODEOWNERS"),
            exists(".github/dependabot.yml", "policy", "Dependabot config"),
        ]
    )

    workflow_count = count_files(".github/workflows/*.yml")
    reusable_count = count_files(".github/workflows/reusable-*.yml")
    checks.append(Check("workflows", "workflow files", status(workflow_count > 0), f"{workflow_count} .yml files"))
    checks.append(Check("workflows", "reusable workflows", status(reusable_count > 0), f"{reusable_count} reusable-*.yml files"))

    for path, name in [
        ("runner/README.md", "runner README"),
        ("runner/install.sh", "runner installer"),
        ("runner/register.sh", "runner registration"),
        ("runner/ephemeral-spawn.sh", "ephemeral spawner"),
        ("runner/systemd/runner-spawn@.service", "ephemeral systemd service"),
        ("runner/systemd/runner-spawn@.timer", "ephemeral systemd timer"),
        ("docs/self-hosted-runner.md", "runner safety docs"),
    ]:
        checks.append(exists(path, "runner", name))

    for path, name in [
        ("scripts/secrets-sync-github-from-bitwarden.sh", "Bitwarden/Vaultwarden sync"),
        ("secrets/github-secrets.tsv.example", "GitHub secrets mapping example"),
        ("secrets/README.md", "secrets docs"),
    ]:
        checks.append(exists(path, "secrets", name))

    for manifest in ["repos/MANIFEST.yaml", "tools/MANIFEST.yaml"]:
        ok, detail = load_yamlish_manifest(ROOT / manifest)
        area = "subrepos" if manifest.startswith("repos/") else "tools"
        checks.append(Check(area, manifest, status(ok), detail))

    gitmodules = ROOT / ".gitmodules"
    checks.append(Check("subrepos", ".gitmodules", status(gitmodules.exists(), warning=True), ".gitmodules present" if gitmodules.exists() else "no registered submodules yet"))

    checks.append(exists("scripts/github-doctor.py", "control-plane", "one-command doctor"))
    return checks


def warning_detail(text: str) -> str:
    return text


def live_github_checks() -> list[Check]:
    checks: list[Check] = []
    ok, payload = gh_json(["auth", "status", "--show-token=false"])
    checks.append(Check("github-live", "gh auth", status(ok, warning=True), str(payload).splitlines()[0] if payload else "authenticated"))

    if not ok:
        return checks

    ok, prs = gh_json([
        "pr",
        "list",
        "--state",
        "open",
        "--json",
        "number,title,headRefName,baseRefName,mergeStateStatus,url",
    ])
    if ok and isinstance(prs, list):
        detail = ", ".join(f"#{p['number']} {p['headRefName']}→{p['baseRefName']}" for p in prs[:5]) or "none"
        checks.append(Check("github-live", "open PR stack", "OK", detail))
    else:
        checks.append(Check("github-live", "open PR stack", "WARN", str(prs)))

    ok, workflows = gh_json(["workflow", "list", "--json", "name,state,path"])
    if ok and isinstance(workflows, list):
        active = [w for w in workflows if w.get("state") == "active"]
        checks.append(Check("github-live", "active workflows", status(bool(active), warning=True), f"{len(active)}/{len(workflows)} active"))
    else:
        checks.append(Check("github-live", "active workflows", "WARN", str(workflows)))

    ok, repo = gh_json(["repo", "view", "--json", "nameWithOwner,defaultBranchRef,isPrivate"])
    if ok and isinstance(repo, dict):
        default_branch = (repo.get("defaultBranchRef") or {}).get("name", "unknown")
        checks.append(Check("github-live", "repo identity", "OK", f"{repo.get('nameWithOwner')} default={default_branch} private={repo.get('isPrivate')}"))
    else:
        checks.append(Check("github-live", "repo identity", "WARN", str(repo)))

    return checks


def print_table(checks: Iterable[Check]) -> None:
    rows = list(checks)
    widths = {
        "area": max([len("Area"), *(len(c.area) for c in rows)]),
        "status": max([len("Status"), *(len(c.status) for c in rows)]),
        "name": max([len("Check"), *(len(c.name) for c in rows)]),
    }
    print(f"{'Area':<{widths['area']}}  {'Status':<{widths['status']}}  {'Check':<{widths['name']}}  Detail")
    print(f"{'-' * widths['area']}  {'-' * widths['status']}  {'-' * widths['name']}  {'-' * 40}")
    for c in rows:
        print(f"{c.area:<{widths['area']}}  {c.status:<{widths['status']}}  {c.name:<{widths['name']}}  {c.detail}")


def main() -> int:
    parser = argparse.ArgumentParser(description="Read-only FlexNetOS GitHub control-plane doctor")
    parser.add_argument("--json", action="store_true", help="emit machine-readable JSON")
    parser.add_argument("--offline", action="store_true", help="skip live gh API checks")
    parser.add_argument("--strict", action="store_true", help="exit non-zero on MISSING checks")
    args = parser.parse_args()

    checks = repo_checks()
    if not args.offline:
        checks.extend(live_github_checks())

    if args.json:
        print(json.dumps([asdict(c) for c in checks], indent=2, sort_keys=True))
    else:
        print("FlexNetOS GitHub control-plane doctor")
        print(f"Repo: {ROOT}")
        print("Mode: read-only")
        print()
        print_table(checks)
        print()
        missing = [c for c in checks if c.status == "MISSING"]
        warn = [c for c in checks if c.status == "WARN"]
        print(f"Summary: {len(missing)} missing, {len(warn)} warnings, {len(checks)} checks")
        if missing:
            print("Next: fill the missing repo-side automation surfaces, then rerun `make github.doctor`.")

    if args.strict and any(c.status == "MISSING" for c in checks):
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())

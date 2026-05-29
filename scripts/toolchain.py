#!/usr/bin/env python3
"""Materialize and run pinned repo-local tool binaries.

The source of truth is tools/assets.json. Archives are downloaded only when the
verified cache is missing; every archive is checked against its pinned SHA-256
before extraction. Set FLEXNETOS_NO_TOOL_DOWNLOAD=1 to require an already
materialized cache.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
import platform
import shutil
import stat
import sys
import tarfile
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ASSET_MANIFEST = ROOT / "tools" / "assets.json"
CACHE = ROOT / "tools" / ".cache"
DOWNLOADS = CACHE / "downloads"
BIN_CACHE = CACHE / "bin"


def host_platform() -> str:
    system = platform.system().lower()
    machine = platform.machine().lower()
    if system == "linux" and machine in {"x86_64", "amd64"}:
        return "linux-x64"
    raise SystemExit(f"unsupported host platform: {system}/{machine}")


def load_manifest() -> dict:
    with ASSET_MANIFEST.open(encoding="utf-8") as fh:
        return json.load(fh)


def tool_record(name: str, plat: str) -> tuple[dict, dict]:
    manifest = load_manifest()
    try:
        tool = manifest["tools"][name]
    except KeyError as exc:
        raise SystemExit(f"unknown tool '{name}' in {ASSET_MANIFEST}") from exc
    try:
        asset = tool["platforms"][plat]
    except KeyError as exc:
        raise SystemExit(f"tool '{name}' has no asset for platform '{plat}'") from exc
    return tool, asset


def sha256(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as fh:
        for chunk in iter(lambda: fh.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()


def download(url: str, dest: Path) -> None:
    if os.environ.get("FLEXNETOS_NO_TOOL_DOWNLOAD") == "1":
        raise SystemExit(
            f"missing {dest}; refusing network download because FLEXNETOS_NO_TOOL_DOWNLOAD=1"
        )
    dest.parent.mkdir(parents=True, exist_ok=True)
    tmp = dest.with_suffix(dest.suffix + ".tmp")
    print(f"fetch: {url}", file=sys.stderr)
    with urllib.request.urlopen(url) as resp, tmp.open("wb") as fh:
        shutil.copyfileobj(resp, fh)
    tmp.replace(dest)


def verified_archive(asset: dict) -> Path:
    archive = DOWNLOADS / asset["archive"]
    expected = asset["sha256"]
    if archive.exists():
        actual = sha256(archive)
        if actual == expected:
            return archive
        archive.unlink()
        print(
            f"warning: removed cached archive with bad sha256: {actual} != {expected}",
            file=sys.stderr,
        )
    download(asset["url"], archive)
    actual = sha256(archive)
    if actual != expected:
        archive.unlink(missing_ok=True)
        raise SystemExit(f"sha256 mismatch for {archive.name}: {actual} != {expected}")
    return archive


def safe_extract_binary(archive: Path, member_name: str, dest: Path) -> None:
    with tarfile.open(archive, "r:*") as tf:
        matches = [m for m in tf.getmembers() if Path(m.name).name == member_name and m.isfile()]
        if not matches:
            raise SystemExit(f"{archive.name}: binary '{member_name}' not found")
        member = matches[0]
        src = tf.extractfile(member)
        if src is None:
            raise SystemExit(f"{archive.name}: could not read '{member.name}'")
        dest.parent.mkdir(parents=True, exist_ok=True)
        with src, dest.open("wb") as out:
            shutil.copyfileobj(src, out)
        dest.chmod(dest.stat().st_mode | stat.S_IXUSR | stat.S_IXGRP | stat.S_IXOTH)


def materialize(name: str, plat: str | None = None) -> Path:
    plat = plat or host_platform()
    tool, asset = tool_record(name, plat)
    dest = BIN_CACHE / f"{name}-{tool['version']}-{plat}" / asset["binary"]
    if dest.exists():
        return dest
    archive = verified_archive(asset)
    safe_extract_binary(archive, asset["binary"], dest)
    return dest


def ensure_all(plat: str | None = None) -> int:
    manifest = load_manifest()
    for name in sorted(manifest["tools"]):
        path = materialize(name, plat)
        print(f"{name}: {path}")
    return 0


def print_path(name: str, plat: str | None = None) -> int:
    print(materialize(name, plat))
    return 0


def run_tool(name: str, args: list[str], plat: str | None = None) -> int:
    exe = materialize(name, plat)
    os.execv(str(exe), [str(exe), *args])
    return 127


def validate_manifest(plat: str | None = None) -> int:
    manifest = load_manifest()
    plat = plat or host_platform()
    errors: list[str] = []
    if manifest.get("schema") != 1:
        errors.append("schema must be 1")
    tools = manifest.get("tools")
    if not isinstance(tools, dict) or not tools:
        errors.append("tools must be a non-empty object")
    else:
        for name, tool in sorted(tools.items()):
            if not isinstance(tool.get("version"), str) or not tool["version"]:
                errors.append(f"{name}: missing version")
            platforms = tool.get("platforms")
            if not isinstance(platforms, dict) or plat not in platforms:
                errors.append(f"{name}: missing platform {plat}")
                continue
            asset = platforms[plat]
            for field in ("archive", "url", "sha256", "binary"):
                if not isinstance(asset.get(field), str) or not asset[field]:
                    errors.append(f"{name}/{plat}: missing {field}")
            digest = str(asset.get("sha256", ""))
            if len(digest) != 64 or any(ch not in "0123456789abcdef" for ch in digest):
                errors.append(f"{name}/{plat}: sha256 must be 64 lowercase hex chars")
            if not str(asset.get("url", "")).startswith("https://github.com/"):
                errors.append(f"{name}/{plat}: URL must be a pinned GitHub release asset")
    if errors:
        for error in errors:
            print(f"ERROR: {error}", file=sys.stderr)
        return 1
    print(f"OK: {len(tools) if isinstance(tools, dict) else 0} pinned tool assets for {plat}")
    return 0


def verify_assets(plat: str | None = None) -> int:
    manifest = load_manifest()
    plat = plat or host_platform()
    errors = 0
    for name in sorted(manifest["tools"]):
        _tool, asset = tool_record(name, plat)
        archive = DOWNLOADS / asset["archive"]
        if not archive.exists():
            print(f"MISS: {archive}")
            errors += 1
            continue
        actual = sha256(archive)
        if actual == asset["sha256"]:
            print(f"OK: {archive.name}")
        else:
            print(f"BAD: {archive.name}: {actual} != {asset['sha256']}")
            errors += 1
    return 1 if errors else 0


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--platform", default=None, help="asset platform, default: detected host")
    sub = parser.add_subparsers(dest="cmd", required=True)
    p_run = sub.add_parser("run", help="materialize a tool and exec it")
    p_run.add_argument("tool")
    p_run.add_argument("args", nargs=argparse.REMAINDER)
    p_path = sub.add_parser("path", help="materialize a tool and print its path")
    p_path.add_argument("tool")
    sub.add_parser("ensure", help="materialize every tool for this platform")
    sub.add_parser("validate", help="validate tools/assets.json without downloading")
    sub.add_parser("verify-assets", help="verify already downloaded archives")
    args = parser.parse_args()

    if args.cmd == "run":
        return run_tool(args.tool, args.args, args.platform)
    if args.cmd == "path":
        return print_path(args.tool, args.platform)
    if args.cmd == "ensure":
        return ensure_all(args.platform)
    if args.cmd == "validate":
        return validate_manifest(args.platform)
    if args.cmd == "verify-assets":
        return verify_assets(args.platform)
    raise AssertionError(args.cmd)


if __name__ == "__main__":
    raise SystemExit(main())

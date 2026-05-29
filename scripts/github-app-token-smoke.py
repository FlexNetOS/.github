#!/usr/bin/env python3
"""Smoke-test a GitHub App installation token exchange.

The script is intentionally conservative:
- it fails closed when required environment variables are absent;
- it never prints private keys, JWTs, installation tokens, or cleartext secrets;
- it uses only the GitHub App JWT flow and a single installation-token request;
- it can run with --dry-run to validate local inputs/signing without contacting
  GitHub.
"""

from __future__ import annotations

import argparse
import base64
import json
import os
import sys
import time
import urllib.error
import urllib.request
from pathlib import Path
from typing import Any


def b64url(data: bytes) -> str:
    return base64.urlsafe_b64encode(data).rstrip(b"=").decode("ascii")


def load_private_key() -> str:
    key_file = os.environ.get("GITHUB_APP_PRIVATE_KEY_FILE")
    key_value = os.environ.get("GITHUB_APP_PRIVATE_KEY")
    if key_file:
        path = Path(key_file).expanduser()
        if not path.exists():
            raise SystemExit(f"ERROR: GITHUB_APP_PRIVATE_KEY_FILE does not exist: {path}")
        return path.read_text(encoding="utf-8")
    if key_value:
        # Secret managers sometimes store PEM newlines escaped.
        return key_value.replace("\\n", "\n")
    raise SystemExit("ERROR: set GITHUB_APP_PRIVATE_KEY_FILE or GITHUB_APP_PRIVATE_KEY")


def require_env(name: str) -> str:
    value = os.environ.get(name, "").strip()
    if not value:
        raise SystemExit(f"ERROR: set {name}")
    return value


def sign_jwt(app_id: str, private_key_pem: str) -> tuple[str, int]:
    try:
        from cryptography.hazmat.primitives import hashes, serialization
        from cryptography.hazmat.primitives.asymmetric import padding, rsa
    except ImportError as exc:
        raise SystemExit(
            "ERROR: Python package 'cryptography' is required to sign GitHub App JWTs. "
            "Install it in a local venv or use a pinned repo-local toolchain before running non-dry smoke tests."
        ) from exc

    now = int(time.time())
    expires_at = now + 540  # GitHub permits max 10 minutes; leave margin.
    header = {"alg": "RS256", "typ": "JWT"}
    payload = {"iat": now - 60, "exp": expires_at, "iss": app_id}
    signing_input = f"{b64url(json.dumps(header, separators=(',', ':')).encode())}.{b64url(json.dumps(payload, separators=(',', ':')).encode())}"
    key = serialization.load_pem_private_key(private_key_pem.encode("utf-8"), password=None)
    if not isinstance(key, rsa.RSAPrivateKey):
        raise SystemExit("ERROR: GitHub App private key must be an RSA PEM private key")
    signature = key.sign(signing_input.encode("ascii"), padding.PKCS1v15(), hashes.SHA256())
    return f"{signing_input}.{b64url(signature)}", expires_at


def github_request(api_url: str, installation_id: str, jwt: str) -> dict[str, Any]:
    url = f"{api_url.rstrip('/')}/app/installations/{installation_id}/access_tokens"
    request = urllib.request.Request(
        url,
        method="POST",
        headers={
            "Accept": "application/vnd.github+json",
            "Authorization": f"Bearer {jwt}",
            "X-GitHub-Api-Version": "2022-11-28",
            "User-Agent": "flexnetos-github-app-token-smoke",
        },
        data=b"{}",
    )
    try:
        with urllib.request.urlopen(request, timeout=30) as response:
            return json.loads(response.read().decode("utf-8"))
    except urllib.error.HTTPError as exc:
        body = exc.read().decode("utf-8", errors="replace")
        raise SystemExit(f"ERROR: GitHub token request failed: HTTP {exc.code}: {body}") from exc
    except urllib.error.URLError as exc:
        raise SystemExit(f"ERROR: GitHub token request failed: {exc}") from exc


def main() -> int:
    parser = argparse.ArgumentParser(description="GitHub App installation token smoke test")
    parser.add_argument("--dry-run", action="store_true", help="validate env and JWT signing without calling GitHub")
    parser.add_argument("--json", action="store_true", help="emit machine-readable masked metadata")
    args = parser.parse_args()

    app_id = require_env("GITHUB_APP_ID")
    installation_id = require_env("GITHUB_APP_INSTALLATION_ID")
    private_key = load_private_key()
    api_url = os.environ.get("GITHUB_API_URL", "https://api.github.com")

    jwt, jwt_expires_at = sign_jwt(app_id, private_key)
    result: dict[str, Any] = {
        "status": "ok",
        "mode": "dry-run" if args.dry_run else "live",
        "app_id_present": True,
        "installation_id_present": True,
        "api_url": api_url,
        "jwt_expires_at": jwt_expires_at,
    }

    if not args.dry_run:
        token_payload = github_request(api_url, installation_id, jwt)
        result.update(
            {
                "token_received": bool(token_payload.get("token")),
                "token_masked": "***" if token_payload.get("token") else None,
                "expires_at": token_payload.get("expires_at"),
                "repository_selection": token_payload.get("repository_selection"),
                "permissions": token_payload.get("permissions", {}),
            }
        )

    if args.json:
        print(json.dumps(result, indent=2, sort_keys=True))
    else:
        print("GitHub App token smoke test: OK")
        print(f"Mode: {result['mode']}")
        print(f"API: {api_url}")
        print(f"JWT expires at unix: {jwt_expires_at}")
        if not args.dry_run:
            print(f"Installation token received: {result['token_received']} (masked)")
            print(f"Installation token expires at: {result.get('expires_at')}")
            print(f"Repository selection: {result.get('repository_selection')}")
            print(f"Permissions: {json.dumps(result.get('permissions', {}), sort_keys=True)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())

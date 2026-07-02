#!/usr/bin/env python3
"""Validate workspace project intent lock before genesis/scaffold/implementation."""
from __future__ import annotations

import argparse
import json
import os
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
INTENT_PATH = ROOT / ".factory" / "project-intent.json"

VALID_ROLES = frozenset(
    {
        "factory-template",
        "android-app",
        "web-app",
        "laravel-mysql-fullstack",
        "existing-project-import",
        "test-sandbox",
    }
)

VALID_PLATFORMS = frozenset({"none", "android", "web", "fullstack", "mixed", "existing"})

ROLE_PLATFORM = {
    "factory-template": "none",
    "android-app": "android",
    "web-app": "web",
    "laravel-mysql-fullstack": "fullstack",
    "existing-project-import": "existing",
    "test-sandbox": "none",
}

REQUIRED_SOURCE = "explicit-user-confirmation"
SCHEMA_VERSION = 1


def load_intent() -> tuple[dict | None, str | None]:
    if not INTENT_PATH.exists():
        return None, None
    try:
        data = json.loads(INTENT_PATH.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        return None, f"malformed JSON: {exc}"
    if not isinstance(data, dict):
        return None, "intent root must be a JSON object"
    return data, None


def validate_schema(intent: dict) -> list[str]:
    errors: list[str] = []
    if intent.get("schema_version") != SCHEMA_VERSION:
        errors.append(f"schema_version must be {SCHEMA_VERSION}")
    if intent.get("source") != REQUIRED_SOURCE:
        errors.append(f"source must be {REQUIRED_SOURCE!r}")
    role = intent.get("workspace_role")
    if role not in VALID_ROLES:
        errors.append(f"invalid workspace_role: {role!r}")
    platform = intent.get("platform")
    if platform not in VALID_PLATFORMS:
        errors.append(f"invalid platform: {platform!r}")
    if role in ROLE_PLATFORM and platform != ROLE_PLATFORM[role]:
        errors.append(
            f"role/platform mismatch: {role!r} requires platform={ROLE_PLATFORM[role]!r}, got {platform!r}"
        )
    if role == "android-app":
        pkg = intent.get("package_name")
        if not pkg or not str(pkg).strip():
            errors.append("android-app requires non-empty package_name")
    return errors


def main() -> int:
    parser = argparse.ArgumentParser(description="Project Intent Gate validator")
    parser.add_argument(
        "--mode",
        choices=("diagnostic", "genesis", "scaffold", "implementation"),
        default="diagnostic",
    )
    parser.add_argument("--platform", choices=("android", "web", "fullstack", "existing", "none"))
    parser.add_argument("--require-role", choices=sorted(VALID_ROLES))
    args = parser.parse_args()

    intent, parse_err = load_intent()

    if parse_err:
        print(f"⛔ BLOCKED: {parse_err}")
        return 1

    if intent is None:
        if args.mode == "diagnostic":
            print("ℹ️  Project intent not locked — diagnostic mode allowed")
            return 0
        if (
            args.mode == "scaffold"
            and args.platform == "android"
            and os.environ.get("APP_FABRIKA_ALLOW_TEMPLATE_SCAFFOLD") == "1"
        ):
            print("ℹ️  Template scaffold allowed for isolated CI smoke build")
            return 0
        print(f"⛔ BLOCKED: mode={args.mode} requires explicit project intent lock.")
        print("   → Run /prompt-genesis and confirm .factory/project-intent.json")
        return 2

    schema_errors = validate_schema(intent)
    if schema_errors:
        for err in schema_errors:
            print(f"⛔ BLOCKED: {err}")
        return 1

    role = intent["workspace_role"]
    platform = intent["platform"]

    if args.require_role and role != args.require_role:
        print(
            f"⛔ BLOCKED: workspace_role={role!r} does not match required {args.require_role!r}"
        )
        return 2

    if args.mode == "genesis" and role == "factory-template":
        print("⛔ BLOCKED: mode=genesis requires explicit non-factory project intent.")
        return 2

    if args.mode == "scaffold" and args.platform == "android" and role != "android-app":
        print(
            f"⛔ BLOCKED: Android scaffold requires workspace_role=android-app (got {role!r})"
        )
        return 2

    if args.mode == "implementation" and role in ("factory-template", "test-sandbox"):
        print(f"⛔ BLOCKED: mode=implementation not allowed for workspace_role={role!r}")
        return 2

    if args.mode == "genesis" and role == "test-sandbox":
        print("⛔ BLOCKED: test-sandbox requires explicit promotion before genesis.")
        return 2

    print(f"✅ Project intent valid — role={role} platform={platform} mode={args.mode}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

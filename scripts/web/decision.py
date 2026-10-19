#!/usr/bin/env python3
"""Webrail Decision Layer — açık kaynak JEV-mantığı (ücretli JEV MCP yok).

Girdi: domain-report.json (+ opsiyonel web-state, project-intent, modules/catalog)
Çıktı: .factory/decision.json

İlkeler (JEV felsefesi, ücretsiz uygulama):
- Karar ucuz olmalı (yerel deterministik script; LLM çağrısı yok).
- Pahalı modeli gereksiz yere çağırma (routing önerisi + bağlam allowlist).
- Önce modül/skill; yoksa üret.
"""
from __future__ import annotations

import argparse
import json
import os
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


def die(msg: str, code: int = 1) -> None:
    print(f"decision: {msg}", file=sys.stderr)
    sys.exit(code)


def load_json(path: Path) -> dict[str, Any] | None:
    if not path.is_file():
        return None
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        die(f"{path} okunamadı: {exc}")


def norm_module(name: str) -> str:
    return (name or "").strip().lower().replace("_", "-")


def build_decision(project: Path, factory_root: Path) -> dict[str, Any]:
    fac = project / ".factory"
    report = load_json(fac / "domain-report.json")
    if not report:
        die("domain-report.json yok — önce P1 tamamlanmalı")

    state = load_json(fac / "web-state.json") or {}
    intent = load_json(fac / "project-intent.json") or {}
    catalog_path = factory_root / ".factory" / "modules" / "catalog.json"
    # Bootstrapped projede katalog proje içinde de olabilir
    local_catalog = fac / "modules" / "catalog.json"
    catalog = load_json(local_catalog) or load_json(catalog_path) or {"modules": {}}
    modules_map: dict[str, Any] = catalog.get("modules") or {}

    compliance = (
        report.get("compliance")
        or intent.get("compliance")
        or "none"
    )
    # Arketip: intent > report > gap-report > brochure
    archetype = (
        (intent.get("project_type") or intent.get("archetype") or "")
        or (report.get("project_type") or report.get("archetype") or "")
        or ""
    )
    if not archetype:
        gap = load_json(project / "gap-report.json") or {}
        archetype = str(gap.get("archetype") or "")
    archetype = str(archetype).strip().lower() or "brochure"

    # ecommerce-only skill paketleri (showcase/onepage zorlanmaz)
    ECOM_ONLY = {"payment", "payments", "odeme", "ödeme", "reviews", "review", "yorum"}
    NOTIFY_OK = {"ecommerce", "webapp", "catalog_rfq"}
    CART_OK = {"ecommerce", "catalog_rfq"}

    matrix = report.get("module_matrix") or []
    manifest = report.get("file_manifest") or []
    if isinstance(manifest, dict):
        manifest = list(manifest.keys())

    # Bağlam allowlist: manifest + sabit kontrat yolları (JEV prune karşılığı)
    allowlist = [
        ".factory/domain-report.json",
        ".factory/decision.json",
        ".factory/contracts/",
        "RUN-STATUS.md",
    ]
    for item in manifest:
        if isinstance(item, str) and item.strip():
            allowlist.append(item.strip())
        elif isinstance(item, dict) and item.get("path"):
            allowlist.append(str(item["path"]))
    # tekilleştir, sırayı koru
    seen: set[str] = set()
    context_allowlist: list[str] = []
    for p in allowlist:
        if p not in seen:
            seen.add(p)
            context_allowlist.append(p)

    modules_to_apply: list[dict[str, Any]] = []
    has_catalog_like = False
    has_cart = False
    skipped_archetype: list[str] = []

    for row in matrix:
        if not isinstance(row, dict):
            continue
        mod = norm_module(str(row.get("module", "")))
        status = str(row.get("status", "")).lower()
        if not mod:
            continue
        if mod in ("catalog", "product", "products", "ürün", "urun"):
            has_catalog_like = True
        if mod in ("cart", "order", "orders", "sepet", "siparis", "sipariş"):
            has_cart = status in ("present", "injected")
            if status in ("present", "injected"):
                has_catalog_like = True

        if status not in ("present", "injected", "missing", "proposed"):
            continue
        # Skill uygula: injected/missing/proposed veya compliance kaynaklı
        apply = status in ("injected", "missing", "proposed")
        if mod in ("rbac", "auth", "seo") and status == "present":
            apply = True  # skill referans — yeniden icat yasağı
        if mod in ("kvkk", "gdpr") or (
            compliance in ("kvkk", "gdpr") and mod in ("legal", "consent")
        ):
            apply = True

        # Arketip filtresi
        if mod in ECOM_ONLY and archetype != "ecommerce":
            skipped_archetype.append(mod)
            continue
        if mod in ("notifications", "notification", "bildirim", "bildirimler") and archetype not in NOTIFY_OK:
            if status in ("proposed", "missing", "injected"):
                skipped_archetype.append(mod)
                continue
        if mod in ("cart", "order", "orders", "sepet") and archetype not in CART_OK:
            if status in ("proposed", "missing", "injected"):
                skipped_archetype.append(mod)
                continue

        if not apply:
            continue

        entry = modules_map.get(mod) or {}
        skill = entry.get("skill")
        modules_to_apply.append(
            {
                "module": mod,
                "skill": skill,
                "reason": (
                    f"module_matrix.status={status}; archetype={archetype}; "
                    f"{entry.get('summary', '')}"
                ).strip(),
            }
        )

    if compliance in ("kvkk", "gdpr"):
        if not any(m["module"] in ("kvkk", "gdpr") for m in modules_to_apply):
            entry = modules_map.get(compliance) or modules_map.get("kvkk") or {}
            modules_to_apply.append(
                {
                    "module": compliance,
                    "skill": entry.get("skill"),
                    "reason": f"intent/report compliance={compliance}",
                }
            )

    # Katalog yok / sepet anlamsız → --allow-no-cart öner
    qa_extra = ""
    if not has_catalog_like and not has_cart:
        qa_extra = "--allow-no-cart"

    phase = state.get("current_phase") or "P1"
    model_routing = {
        "P1": os.environ.get("MODEL_P1", "nvidia/z-ai/glm-5.3-flash"),
        "P2": os.environ.get("MODEL_P2", "nvidia/z-ai/glm-5.3"),
        "P4": os.environ.get("MODEL_P4", "nvidia/z-ai/glm-5.3"),
        "rationale": (
            "P1 ucuz/hızlı analiz; P2/P4 güçlü kod. "
            "Ücretli JEV yok — env MODEL_* ile override. "
            "Bağlam yalnız context_allowlist."
        ),
    }

    next_actions = [
        "RUN-STATUS.md dosyasını oku (handoff).",
        "P2 öncesi .factory/decision.json → modules_to_apply skill'lerini uygula.",
        "Yalnız context_allowlist + domain-report ile çalış; geniş repo taraması yasak.",
    ]
    if qa_extra:
        next_actions.append(
            f"QA için önerilen bayrak: QA_GATE_EXTRA='{qa_extra}' "
            "(katalog/sepet yok — onaylı istisna)."
        )
    if phase in ("P1", "P2"):
        next_actions.append(
            "İskelet eksikse: P2_HUMAN_ASSIST=true ile hybrid veya orchestrate --auto."
        )

    return {
        "schema_version": 1,
        "generated_at": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "project": str(report.get("project") or project.name),
        "phase_hint": phase,
        "archetype": archetype,
        "model_routing": model_routing,
        "modules_to_apply": modules_to_apply,
        "skipped_archetype": skipped_archetype,
        "context_allowlist": context_allowlist[:80],
        "qa_gate_extra": qa_extra,
        "next_actions": next_actions,
        "result": "READY",
        "engine": "webrail-decision-layer",
        "note": "Open-source JEV-logic; no paid JEV MCP.",
    }


def main() -> None:
    ap = argparse.ArgumentParser(description="Webrail Decision Layer")
    ap.add_argument("project", nargs="?", default=".")
    ap.add_argument(
        "--factory-root",
        default="",
        help="Webrail kökü (catalog için); boşsa script'ten türetilir",
    )
    args = ap.parse_args()
    project = Path(args.project).resolve()
    if not project.is_dir():
        die(f"dizin yok: {project}")

    if args.factory_root:
        factory_root = Path(args.factory_root).resolve()
    else:
        factory_root = Path(__file__).resolve().parents[2]

    decision = build_decision(project, factory_root)
    out = project / ".factory" / "decision.json"
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(decision, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"decision: yazıldı → {out} (result={decision['result']})")
    print(f"  modules={len(decision['modules_to_apply'])} "
          f"allowlist={len(decision['context_allowlist'])} "
          f"qa_extra={decision['qa_gate_extra']!r}")


if __name__ == "__main__":
    main()

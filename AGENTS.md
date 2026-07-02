# Ulas Autonomous Android APP Factory — Ajan Dizini

**Yazar:** [Ulaş Kaşıkcı](docs/AUTHOR.md)

Her Android projesine aktarılabilir fabrika paketi (Executive OS + 16 ajan) · **v3.0.0-intelligence-alpha**

> **AGENTS FREEZE (V3):** Yeni ajan veya council eklenmez.  
> **INTELLIGENCE FREEZE (V4):** Yeni engine eklenmez.  
> **North star:** [`FACTORY_MISSION.md`](FACTORY_MISSION.md) — **FROZEN · MAINTENANCE · Validate through products**  
> **DEVELOPMENT FREEZE:** [`.factory/freeze.json`](.factory/freeze.json)

---

## Executive Layer

| Agent | Rule | Denetleyen (L1+) |
|-------|------|------------------|
| **CEO V7** | `11-ceo-agent.mdc` | CSGB → EGC |
| **EGC** | `14-executive-governance-council.mdc` | — |
| **CSGB** | `governance/csgb/DEPARTMENT_CHARTER.md` | EGC |
| **CAO** | `12-chief-audit-officer.mdc` | CEO → EGC |
| **PDC** | `09-product-decision-council.mdc` | CAO → CEO |
| **CEC** | `13-chief-execution-council.mdc` | CEO → CSGB |
| **CDID** | `15-chief-delivery-intelligence.mdc` | CEC → CAO |

## Intelligence Division

| Agent | Rule | Denetleyen |
|-------|------|------------|
| LIUD | `07-linguistic-intelligence.mdc` | PDC → CAO |
| CIKA | `08-curriculum-intelligence.mdc` | PDC → CAO |
| AID | `16-analytics-intelligence.mdc` | CAO → CEO |
| Mavi Okyanus | `10-mavi-okyanus.mdc` | PDC → CAO |
| Growth | `17-marketing-growth.mdc` | CPO → CAO |

**Charter-only (cursor rule yok):** Finance, Localization, Clinical, Trends — `governance/FACTORY_REPO_POLICY.md`

## Factory Division

| # | Agent | Rule | L1 | L2 |
|---|-------|------|----|----|
| 1 | CPO | `01-product-cpo.mdc` | PDC | CAO |
| 2 | Architect | `02-architect.mdc` | CEC | CAO |
| 3 | Android | `03-android-elite.mdc` | Architect | CPO |
| 4 | Security | `04-auditor-security.mdc` | Architect | CAO |
| 5 | OEM | `05-oem-compat-auditor.mdc` | Android | Security |
| 6 | MCP | `06-mcp-orchestrator.mdc` | Architect | Security |

**Tam eşleme:** `governance/executive/HIERARCHICAL_AUDIT_CHAIN.md`

---

## Project Intent and After Action Awareness

Agents must **not** treat previous conversation context as active project intent.

Before domain-specific genesis/scaffold/implementation:

1. Apply `21-project-intent-gate.mdc` — workspace role/domain lock.
2. Apply `20-agent-intent-gate.mdc` — DIAGNOSTIC vs IMPLEMENTATION mode.
3. Apply `00-overmind-zero-hallucination.mdc` — YAPILACAKLAR, evidence-first, no hallucination.

After execution summaries:

- Use `/cevap` or `/after-action` as **DIAGNOSTIC/AAR** only.
- Do **not** modify files during AAR.
- Follow [`docs/CEVAP_REPORT_CONTRACT.md`](docs/CEVAP_REPORT_CONTRACT.md).

Belge: [`docs/PROJECT_INTENT_GATE.md`](docs/PROJECT_INTENT_GATE.md) · Komutlar: [`prompt-genesis`](.cursor/commands/prompt-genesis.md), [`cevap`](.cursor/commands/cevap.md), [`after-action`](.cursor/commands/after-action.md)

---

## Bootstrap

```bash
./scripts/first-setup.sh
# Cursor → /prompt-genesis → android-app intent lock
./scripts/init-new-app.sh "MyApp" "com.company.myapp"   # + init-governance + YAPILACAKLAR
./scripts/ceo/run_ceo_cycle.sh
python3 scripts/governance/validate-audit-chain.py
python3 scripts/governance/validate-yapilacaklar.py
./scripts/agent-approval-gate.sh
./scripts/factory-quality-gate.sh
./scripts/run-factory-audit.sh
./scripts/factory/run-intelligence-cycle.sh   # V3 — Proof, Memory, Revenue, Benchmark
./scripts/verify-environment.sh
```

## YAPILACAKLAR (zorunlu plan)

| Dosya | Rol |
|-------|-----|
| `YAPILACAKLAR.md` | F0–F8 faz planı · `bekliyor` / `işleniyor` / `tamamlandı` |
| `docs/YAPILACAKLAR_SISTEMI.md` | Bina metaforu + komutlar |

**Cursor:** `/baslat` → prompt plana yazılır · `/devam-et` → aktif faz · `/denetle` → L1+L2

## Cursor (.cursor/)

| Tür | İçerik |
|-----|--------|
| Rules | `00-overmind-zero-hallucination.mdc` + `01`–`17` + `18-state-recovery` + `19-claude-reasoning` + `20-agent-intent-gate` + `21-project-intent-gate` + `22-quality-after-action-contract` |
| Skills | `zero-hallucination`, `yapilacaklar-planner`, `yapilacaklar-executor`, `hierarchical-audit`, `after-action-review` |
| Knowledge OS | `docs/KNOWLEDGE_OS.md` · `.factory/context/` · `knowledge/` |
| Learning Factory | `docs/LEARNING_FACTORY.md` · `intelligence-engine.py` |
| V3 Evidence | `docs/V3_EVIDENCE.md` · `knowledge/evidence/` |
| Commands | `prompt-genesis`, `baslat`, `devam-et`, `denetle`, `faz-durumu`, `yeni-proje`, `cevap`, `after-action` |
| Subagents | `phase-verifier`, `plan-expander`, `phase-auditor`, `hallucination-guard` |

## Governance (canonical)

| Kaynak | Path |
|--------|------|
| Operating system | `governance/executive/CEO_OPERATING_SYSTEM.md` |
| Hierarchical audit | `governance/executive/HIERARCHICAL_AUDIT_CHAIN.md` |
| Approval protocol v3 | `governance/executive/AGENT_APPROVAL_PROTOCOL.md` |
| Sprint lock | `governance/executive/SPRINT_LOCK.json` |
| Roadmap | `governance/product_decision/roadmap_priorities.json` |

## Import to existing project

```bash
./scripts/sync-standards.sh /path/to/project
cd /path/to/project && ./scripts/governance/init-governance.sh
```

---

**Not:** Bu repo fabrika şablonudur. Canlı proje verileri (sprint lock, approval queue, CEO raporları) `init-governance.sh` ile **her projede sıfırdan** oluşturulur; başka uygulamanın runtime dosyaları kopyalanmaz.

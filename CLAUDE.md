> Bu ajan docs/MASTER-PROMPT-V2.md'deki K1-K8 kurallarına tabidir.

# CLAUDE CODE EXECUTION DIRECTIVES — Webrail

**Role:** Senior Web Architect & Automator for the Webrail control plane.
**Factory source:** `https://github.com/UlasKasikci/repo` — only when
`.factory/workspace-role.json` says `webrail-factory`. Customer/bootstrap trees are
`customer-app` (see `WEBRAIL-CUSTOMER.md`); never point their `origin` at the factory.
**Mode:** deterministic — canonical spec: `docs/WEB-EDITION.md` · state contract:
`.factory/web-state-graph.json` · never invent paths or features that are not in the spec.
**Session start:** `bash scripts/web/status.sh .` → `guard.sh matrix .` → `RUN-STATUS.md` →
`.factory/web-state.json` → `domain-report` → `decision.json`.  
Customer protocol: `docs/CUSTOMER-START.md`.
**Decision layer:** `bash scripts/web/decide.sh` (open-source JEV-logic; no paid JEV).
**Operation gate:** before write-code / package / claim-pass / git-push / doctor →
`bash scripts/web/guard.sh <op> .` (DENY = stop; follow printed `fix:`).
Audit: `.factory/guard-log.jsonl`.
**Git push:** default DENY. Never `git push` unless the user explicitly asks. Then
`WEBRAIL_ALLOW_GIT_PUSH=1` and `guard.sh git-push` must ALLOW. Customer-app must never
push to `UlasKasikci/repo`.
**Error Doctor:** on QA FAIL run `bash scripts/web/doctor.sh . --loop` then apply only
`FIX-BRIEF.md` (do not paste full `qa-report.json` into the model — token waste).

## Workflow (State Graph — 5 phases)

1. **Analyze:** extract ONLY web-related patterns (PHP 8.1+, MySQL, HTML/CSS/JS).
   Freeze all business rules, edge cases and security context before writing code.
2. **Validate scope:** run the proactive domain audit — missing RBAC (`role_id`/`permissions`),
   missing cart/order flow for catalogs, missing SEO/KVKK modules → inject or flag them.
3. **Plan State Graph transitions:** Domain Analysis → Code → QA Check → Package.
   Preferred driver: `bash scripts/web/orchestrate.sh <project> [--auto] [--strict]` — artifact
   gates via `.factory/domain-report.json` + `.factory/contracts/*.schema.json`
   (missing artifact = exit 3 wait, invalid = exit 1).
4. **Code:** clean MVC (`core/`, `views/`, `index.php`), PDO prepared statements,
   CSRF tokens, `htmlspecialchars` on output, `PASSWORD_ARGON2ID`.
5. **QA gate (mandatory, zero tolerance):**

   ```bash
   bash scripts/web/qa-gate.sh <project>      # 0 Error, 0 Warning required
   php -l <file>                              # every PHP file
   bash scripts/web/state.sh status           # active phase
   ```

6. **Package (only after QA PASS):**

   ```bash
   bash scripts/web/package-yukleme.sh <project>
   ```

   Creates `Yukleme/` with `Yukleme/SQL/veritabani.sql` (tables + FK + indexes + seed,
   UTF-8) and strips every dev dependency: `node_modules`, `.git`, `.env` (`.env.example`
   allowed), tests, `.scss`/`.ts` sources, reports.

## Loop limits

- `max_retries: 3` — QA failures 1–3 go to P4 (Revision); the **4th failure HALTs** the
  graph, writes `debug_report.json` and stops. Never loop infinitely; surface the report.
- Exit codes: `0` PASS · `1` FAIL/invalid · `2` HALT · `3` orchestrator waiting (LLM step).

## Output

Zero-fluff, production-ready, fully executable terminal commands and structured files.
Never mark work complete without a green `qa-gate.sh` run; never commit `Yukleme/`
artifacts or secrets (`.env`, keys, dumps with credentials).
Never push to GitHub without an explicit user command and a green `guard.sh git-push`.

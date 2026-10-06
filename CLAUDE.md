# CLAUDE CODE EXECUTION DIRECTIVES — App-Fabrika Web Edition

**Role:** FAANG-grade Senior Web Architect & Automator.
**Mode:** deterministic — canonical spec: `docs/WEB-EDITION.md` · state contract:
`.factory/web-state-graph.json` · never invent paths or features that are not in the spec.

## Workflow (State Graph — 5 phases)

1. **Analyze:** extract ONLY web-related patterns (PHP 8.1+, MySQL, HTML/CSS/JS).
   Freeze all business rules, edge cases and security context before writing code.
2. **Validate scope:** run the proactive domain audit — missing RBAC (`role_id`/`permissions`),
   missing cart/order flow for catalogs, missing SEO/KVKK modules → inject or flag them.
3. **Plan State Graph transitions:** Domain Analysis → Code → QA Check → Package.
   Preferred driver: `bash scripts/web/orchestrate.sh <project> [--auto]` — artifact
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

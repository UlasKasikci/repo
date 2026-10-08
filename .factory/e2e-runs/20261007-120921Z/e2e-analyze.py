#!/usr/bin/env python3
"""E2E write/hata oranı + handoff read disiplini analizi (opencode.db, salt-okunur).

Kullanım: python3 e2e-analyze.py <db> <dir-substring> [...]
Çıktı: session basina write denemesi/hatasi, read hedefleri, token/step ozeti.
"""
import json
import os
import sqlite3
import sys

DB = os.path.expanduser("~/.local/share/opencode/opencode.db")


def sess_ids(con, pat):
    rows = con.execute(
        "SELECT id, title FROM session WHERE directory LIKE ? ORDER BY id",
        ("%" + pat + "%",),
    ).fetchall()
    return rows


def analyze(con, sid):
    tools_w, w_err, reads, tok, steps, text_parts = [], 0, [], 0, 0, 0
    for (data,) in con.execute(
        "SELECT data FROM part WHERE session_id = ? ORDER BY id", (sid,)
    ):
        try:
            p = json.loads(data)
        except Exception:
            continue
        t = p.get("type")
        if t == "tool":
            st = p.get("state") or {}
            name = p.get("tool") or (st.get("input") or {}).get("tool") or "?"
            inp = st.get("input") or {}
            if name in ("write", "edit"):
                tools_w.append(name)
                if st.get("status") == "error":
                    w_err += 1
            elif name == "read":
                fp = inp.get("filePath") or inp.get("file_path") or ""
                reads.append(fp)
        elif t == "step_finish":
            steps += 1
            tok += int((p.get("tokens") or {}).get("total") or 0)
        elif t == "text":
            text_parts += 1
    return tools_w, w_err, reads, tok, steps


def main():
    pats = sys.argv[1:] or []
    con = sqlite3.connect("file:%s?mode=ro" % DB, uri=True)
    tw = te = 0
    for pat in pats:
        print("== %s ==" % pat)
        for sid, title in sess_ids(con, pat):
            w, e, reads, tok, steps = analyze(con, sid)
            tw += len(w)
            te += e
            print("  session %s  %s" % (sid[:24], (title or "")[:60]))
            print("    write=%d (err=%d)  tokens=%d  steps=%d"
                  % (len(w), e, tok, steps))
            print("    reads: %s" % (", ".join(os.path.basename(r) for r in reads) or "-"))
    if len(pats) > 1:
        print("TOPLAM write=%d err=%d ratio=%.1f%%" % (tw, te, 100.0 * te / tw if tw else 0))


main()

// nim-stall-retry.js — F5 remedy (Tur 2-7; K1a fix Tur 2-8 A).
// Kök neden (FINDINGS-TUR2-7): NIM mid-turn HTTP stall — stream sessizce ölüyor.
//
// Tur 2-8 A.1 kanıtı (opencode.db part sorgusu): plugin eski hali --format json
// stdout'unda reasoning part event'leri GÖRÜNMEDİĞİ için dolu reasoning'i "boş
// stream" sanıyor ve 61.2s'de abort ediyordu — WITH-PLUGIN turn 2'de reasoning
// part 61.2s boyunca aktif akıyordu (len=5447, updated=abort anı). Bu K1a
// İHLALİ: "dolu stream'de kill yasak". NO-PLUGIN kontrolü: 197.6s reasoning
// sonrası text+tool ile başarılı kapanış — uzun reasoning meşru.
//
// FIX (reasoning-aware): active session'lar için opencode.db'de son
// part.time_updated okunur (bun:sqlite, readonly); reasoning/text/tool güncellemesi
// active map'ini tazeler. Gerçek stall = stdout event YOK + DB'de update YOK →
// 90s'te abort (K1b ile hizalı). DB erişilemezse stdout-only eski davranış.
// MAX_RETRY sonrası devre dışı — son söz K1b-2'nin (false-kill yasağı, K1).
// Env: NIM_STALL_MS (default 90000), NIM_STALL_RETRIES (default 3).

const checkStalls = (now, active, retries, maxRetries, stallMs) => {
  const fired = [];
  for (const [sid, ts] of active) {
    if (now - ts >= stallMs) {
      active.delete(sid);
      const n = (retries.get(sid) || 0) + 1;
      retries.set(sid, n);
      if (n > maxRetries) continue;
      fired.push({ sid, silentMs: now - ts, retry: n });
    }
  }
  return fired;
};

export const NimStallRetry = async ({ client }) => {
  const STALL_MS = Number(process.env.NIM_STALL_MS || 90000);
  const MAX_RETRIES = Number(process.env.NIM_STALL_RETRIES || 3);
  const DEBUG = process.env.NIM_STALL_DEBUG === "1";
  const active = new Map();
  const retries = new Map();

  const log = async (level, message) => {
    try {
      await client.app.log({ body: { service: "nim-stall-retry", level, message } });
    } catch {
      /* log best-effort */
    }
  };

  // DB kanalı (K1a fix): reasoning part'lar stdout event'ine düşmez; bun:sqlite ile
  // readonly okuma. Bulunamazsa stdout-only (eski davranış) — fail-open, asla crash.
  let db = null;
  const dbPath = process.env.OPENCODE_DB || `${process.env.HOME}/.local/share/opencode/opencode.db`;
  try {
    const { Database } = await import("bun:sqlite");
    db = new Database(dbPath, { readonly: true });
    db.exec("PRAGMA busy_timeout = 50");
  } catch {
    db = null;
  }

  const dbLastPartUpdate = (sid) => {
    if (!db) return 0;
    try {
      const row = db
        .query("SELECT MAX(time_updated) AS m FROM part WHERE session_id = ?")
        .get(sid);
      return Number(row?.m || 0);
    } catch {
      return 0;
    }
  };

  await log(
    "info",
    `nim-stall-retry loaded (stall=${STALL_MS}ms retries=${MAX_RETRIES} db=${db ? "yes" : "no"})`,
  );

  const timer = setInterval(async () => {
    const now = Date.now();
    // K1a kanalı: DB'de part güncellemesi varsa active tazelenir (reasoning akıyor demektir)
    if (db) {
      for (const sid of active.keys()) {
        const mu = dbLastPartUpdate(sid);
        if (mu > 0 && mu > now - STALL_MS * 2) {
          // son güncelleme stall penceresi içindeyse stream dolu sayılır
          active.set(sid, now);
          if (DEBUG) await log("info", `db-refresh session=${sid} last_part_update_age=${now - mu}ms`);
        }
      }
    }
    const fired = checkStalls(Date.now(), active, retries, MAX_RETRIES, STALL_MS);
    for (const { sid, silentMs, retry } of fired) {
      try {
        await client.session.abort({ path: { id: sid } });
        const msg =
          `F5 stall ${silentMs}ms ≥ ${STALL_MS}ms → session.abort (retry ${retry}/${MAX_RETRIES}) session=${sid}`;
        await log(db ? "warn" : "error", msg + (db ? "" : " [stdout-only: DB kanalı yok]"));
        if (DEBUG) await log("info", `abort fired sid=${sid}`);
      } catch (e) {
        await log("error", `abort failed session=${sid}: ${String(e)}`);
      }
    }
  }, 5000);
  if (typeof timer.unref === "function") timer.unref();

  return {
    event: async ({ event }) => {
      const t = event.type;
      const sid = event.properties?.sessionID;
      if (!sid) return;
      if (
        t === "message.part.updated" ||
        t === "message.updated" ||
        t === "tool.execute.before" ||
        t === "tool.execute.after"
      ) {
        active.set(sid, Date.now());
      } else if (t === "session.idle") {
        active.delete(sid);
      } else if (t === "session.deleted") {
        active.delete(sid);
        retries.delete(sid);
      }
    },
  };
};

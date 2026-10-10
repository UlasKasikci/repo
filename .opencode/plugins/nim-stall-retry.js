// nim-stall-retry.js — F5 remedy (Tur 2-7): NIM mid-turn HTTP stall.
// Kök neden (FINDINGS-TUR2-5d/2-6): reasoning stream'i 60-180s sessizlikte
// opencode timeout'u olmadan asılı kalıyor; K1b-2 420s'de tüm oturumu kesiyor.
// Plugin: son stream olayından NIM_STALL_MS (default 60000) sessizlikte
// client.session.abort() ile turn'ü sonlandırır → opencode run hata ile çıkar →
// orchestrate/driver retry (A2'' continuation) devreye girer. Session GEÇMİŞİ
// korunur (abort = mevcut message'ı keser); model DEĞİŞMEZ (K7).
// MAX_RETRY sonrası devre dışı — son söz K1b-2'nin (false-kill yasağı, K1).
// Env: NIM_STALL_MS (default 60000), NIM_STALL_RETRIES (default 3).
// NOT: opencode modüldeki HER export'u plugin factory olarak dener — checkStalls
// bilinçli olarak export EDİLMEZ (Tur 2-7 kanıtı: export → "failed to load plugin").

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
  const STALL_MS = Number(process.env.NIM_STALL_MS || 60000);
  const MAX_RETRIES = Number(process.env.NIM_STALL_RETRIES || 3);
  const active = new Map();
  const retries = new Map();

  const log = async (level, message) => {
    try {
      await client.app.log({ body: { service: "nim-stall-retry", level, message } });
    } catch {
      /* log best-effort */
    }
  };

  await log("info", `nim-stall-retry loaded (stall=${STALL_MS}ms retries=${MAX_RETRIES})`);

  const timer = setInterval(async () => {
    const fired = checkStalls(Date.now(), active, retries, MAX_RETRIES, STALL_MS);
    for (const { sid, silentMs, retry } of fired) {
      try {
        await client.session.abort({ path: { id: sid } });
        await log(
          "warn",
          `F5 stall ${silentMs}ms ≥ ${STALL_MS}ms → session.abort (retry ${retry}/${MAX_RETRIES}) session=${sid}`,
        );
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

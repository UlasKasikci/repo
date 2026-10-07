-- ============================================================
-- App-Fabrika Web Edition — e2e-iletisim
-- 001_seed.sql — seed verisi: 3 rol + 1 örnek yönetici (dev)
-- Seed parola: Fabrika!2026 (PASSWORD_ARGON2ID özeti) — üretimde değiştirin
-- ============================================================

SET NAMES utf8mb4;

INSERT INTO roles (id, name) VALUES
    (1, 'admin'),
    (2, 'moderator'),
    (3, 'user');

INSERT INTO users (id, role_id, email, password_hash, full_name, is_active) VALUES
    (1, 1, 'admin@e2e-iletisim.local',
     '$argon2id$v=19$m=65536,t=4,p=1$S2lkVm5qVVF2WUttcVNPTw$JdoLgkNPgntu+z7oqKLUqExdk+BuC882PPya5WxyVR4',
     'Site Yöneticisi', 1);

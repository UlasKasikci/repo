-- App-Fabrika Web Edition — veritabani.sql (sql-dump.sh ile üretildi)
-- Kaynak: SQL/migrations/schema (2 dosya) + SQL/migrations/seed (1 dosya)
-- Sürüm Tarihi: 2026-10-07 · Kaynak Hash: 77aea4567e64
-- Deterministik: saat damgası yok — aynı kaynak = byte-identical çıktı
-- Elle DÜZENLEMEYİN: kaynakları SQL/migrations/ altında değiştirin, sonra:
--   bash scripts/web/sql-dump.sh <proje>


-- ============ SCHEMA ============
-- source: SQL/migrations/schema/001_core_schema.sql
-- App-Fabrika Web Edition — çekirdek şema (roles, users, messages)
-- Motor: InnoDB · Karakter seti: utf8mb4 · Index: B-Tree (InnoDB varsayılanı)
-- Sıra: roles → users → messages (FK bağımlılık sırasına göre)

CREATE TABLE roles (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  name VARCHAR(32) NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_roles_name (name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE users (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  role_id INT UNSIGNED NOT NULL,
  name VARCHAR(120) NOT NULL,
  email VARCHAR(190) NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  is_active TINYINT(1) UNSIGNED NOT NULL DEFAULT 1,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_users_email (email),
  KEY idx_users_role_id (role_id),
  KEY idx_users_created_at (created_at),
  CONSTRAINT fk_users_role FOREIGN KEY (role_id) REFERENCES roles (id)
    ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE messages (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  name VARCHAR(120) NOT NULL,
  email VARCHAR(190) NOT NULL,
  phone VARCHAR(32) NULL DEFAULT NULL,
  subject VARCHAR(190) NOT NULL,
  body TEXT NOT NULL,
  ip_hash CHAR(64) NULL DEFAULT NULL,
  status ENUM('new','read','replied') NOT NULL DEFAULT 'new',
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_messages_status (status),
  KEY idx_messages_created_at (created_at),
  KEY idx_messages_email (email),
  CONSTRAINT chk_messages_status CHECK (status IN ('new','read','replied'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- source: SQL/migrations/schema/002_kvkk.sql
-- App-Fabrika Web Edition — KVKK bloğu (compliance=kvkk)
-- user_consents: açık rıza kaydı — P1 consent_type karşılığı `purpose`;
--   user_id FK cascade (rıza verilen kullanıcı silindiğinde rıza kaydı da silinir);
--   kullanıcı hesabı olmayan ziyaretçiler (iletişim formu) için user_id NULL kalır.
-- anonymization_log: anonimleştirme/küçültme izi — denetim amaçlı kayıt,
--   user_id FK SET NULL (kaydıt silinmez; kullanıcı referansı temizlenir).

CREATE TABLE user_consents (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  user_id INT UNSIGNED NULL DEFAULT NULL,
  email VARCHAR(190) NOT NULL,
  purpose VARCHAR(64) NOT NULL,
  consent_version VARCHAR(16) NOT NULL DEFAULT '1.0',
  granted TINYINT(1) UNSIGNED NOT NULL DEFAULT 1,
  granted_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  revoked_at TIMESTAMP NULL DEFAULT NULL,
  ip_hash CHAR(64) NULL DEFAULT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_user_consents_user_id (user_id),
  KEY idx_user_consents_email (email),
  KEY idx_user_consents_purpose (purpose),
  CONSTRAINT fk_user_consents_user FOREIGN KEY (user_id) REFERENCES users (id)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE anonymization_log (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  user_id INT UNSIGNED NULL DEFAULT NULL,
  subject_type VARCHAR(64) NOT NULL DEFAULT 'user',
  subject_key VARCHAR(190) NOT NULL,
  action VARCHAR(64) NOT NULL,
  basis VARCHAR(190) NOT NULL,
  performed_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_anonymization_log_user_id (user_id),
  KEY idx_anonymization_log_performed_at (performed_at),
  CONSTRAINT fk_anonymization_log_user FOREIGN KEY (user_id) REFERENCES users (id)
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============ SEED ============
-- source: SQL/migrations/seed/100_seed.sql
-- App-Fabrika Web Edition — seed verileri
-- Rollere Admin/Moderatör/Kullanıcı katmanı (RBAC, P1 domain-report enjeksiyonu).
-- Seed parola: Fabrika!2026 (PASSWORD_ARGON2ID ile üretilmiş tek yönlü hash —
--   düz metin parola dump'ta asla bulunmaz; canlıya alınmadan değiştirilmelidir).

INSERT INTO roles (id, name) VALUES
  (1, 'Admin'),
  (2, 'Moderatör'),
  (3, 'Kullanıcı');

INSERT INTO users (role_id, name, email, password_hash, is_active) VALUES
  (1, 'Site Yöneticisi', 'admin@example.com', '$argon2id$v=19$m=65536,t=4,p=1$ZktLNnFtRXJQaUVFSHp5Yw$YQ4i7X1xTuR75UTeu4wObhfrMoCUY6qD5Yg69HBVcHM', 1),
  (2, 'İçerik Moderatörü', 'moderator@example.com', '$argon2id$v=19$m=65536,t=4,p=1$ZktLNnFtRXJQaUVFSHp5Yw$YQ4i7X1xTuR75UTeu4wObhfrMoCUY6qD5Yg69HBVcHM', 1),
  (3, 'Demo Kullanıcı', 'kullanici@example.com', '$argon2id$v=19$m=65536,t=4,p=1$ZktLNnFtRXJQaUVFSHp5Yw$YQ4i7X1xTuR75UTeu4wObhfrMoCUY6qD5Yg69HBVcHM', 1);

INSERT INTO messages (name, email, phone, subject, body, ip_hash, status) VALUES
  ('Ayşe Yılmaz', 'ayse@example.com', '+90 532 000 00 00', 'Kurumsal web sitesi teklifi', 'Merhaba, kurumsal web sitemizin yenilenmesi için teklif rica ediyorum. İletişime geçebilir misiniz?', NULL, 'new'),
  ('Mehmet Kaya', 'mehmet@example.com', NULL, 'İş birliği görüşmesi', 'Ortak bir proje hakkında görüşmek istiyoruz. Uygun olduğunuzda dönüş yapmanızı rica ederim.', NULL, 'read');

INSERT INTO user_consents (email, purpose, consent_version, granted, ip_hash) VALUES
  ('ayse@example.com', 'contact_form', '1.0', 1, NULL);

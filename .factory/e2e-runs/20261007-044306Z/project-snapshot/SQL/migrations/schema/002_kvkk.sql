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

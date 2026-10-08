-- App-Fabrika Web Edition — e2e-iletisim KVKK/GDPR uyum şeması (Agent 2, P2)
-- 6698 sayılı KVKK m.5/1 (açık rıza) + m.11 (ilgili kişinin hakları) kapsamında:
--   user_consents     → açık rıza kaydı (çerez onay banner'ı + yasal metin onayları)
--   anonymization_log → anonimleştirme izi (users fiziksel silinmez; iz bırakılır)
-- Boş şema (seed yok) · users FK'ları ON DELETE SET NULL · InnoDB · utf8mb4

SET NAMES utf8mb4;

CREATE TABLE user_consents (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    user_id INT UNSIGNED NULL DEFAULT NULL,
    email VARCHAR(190) NULL DEFAULT NULL,
    purpose VARCHAR(255) NOT NULL,
    consent_type VARCHAR(50) NOT NULL,
    consent_text_version VARCHAR(20) NOT NULL,
    granted TINYINT(1) NOT NULL DEFAULT 1,
    ip_address VARCHAR(45) NOT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    KEY idx_consents_email (email) USING BTREE,
    KEY idx_consents_user (user_id) USING BTREE,
    CONSTRAINT fk_consents_user FOREIGN KEY (user_id) REFERENCES users (id)
        ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE anonymization_log (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    entity VARCHAR(50) NOT NULL,
    entity_id INT UNSIGNED NOT NULL,
    user_id INT UNSIGNED NULL DEFAULT NULL,
    action VARCHAR(50) NOT NULL,
    basis VARCHAR(255) NOT NULL,
    performed_by INT UNSIGNED NULL DEFAULT NULL,
    reason VARCHAR(255) NOT NULL,
    performed_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    KEY idx_anonym_entity (entity, entity_id) USING BTREE,
    KEY idx_anonym_user (user_id) USING BTREE,
    KEY idx_anonym_performer (performed_by) USING BTREE,
    CONSTRAINT fk_anonym_user FOREIGN KEY (user_id) REFERENCES users (id)
        ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT fk_anonym_performer FOREIGN KEY (performed_by) REFERENCES users (id)
        ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

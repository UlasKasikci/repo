-- App-Fabrika Web Edition — e2e-iletisim seed verisi (Agent 2, P2)
-- 4 satır: 3 rol (RBAC katmanı) + 1 admin hesabı (PASSWORD_ARGON2ID hash).
-- NOT: admin@example.com / Fabrika!2026 bir DEMO hesabıdır — canlıya almadan önce
-- parola mutlaka değiştirilmelidir (Argon2id hash, password_verify ile doğrulanır).
-- messages / user_consents / anonymization_log boş şema olarak teslim edilir.

SET NAMES utf8mb4;

INSERT INTO roles (id, name) VALUES
    (1, 'Admin'),
    (2, 'Moderator'),
    (3, 'User');

INSERT INTO users (role_id, name, email, password_hash, is_active) VALUES
    (1, 'Site Yöneticisi', 'admin@example.com', '$argon2id$v=19$m=65536,t=4,p=1$bklzbEhxTjBVMlZFL2lsNw$EEsoTW/US+4ijyNvNaMlcCOZyexkx4ahZBZHlZ3mIlg', 1);

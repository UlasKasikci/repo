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

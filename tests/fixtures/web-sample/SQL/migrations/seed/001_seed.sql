INSERT INTO `roles` (`id`, `code`, `name`) VALUES
  (1, 'admin', 'Yönetici'),
  (2, 'editor', 'Editör'),
  (3, 'user', 'Kullanıcı');

INSERT INTO `users` (`id`, `role_id`, `email`, `password_hash`) VALUES
  (1, 1, 'admin@example.com', '$argon2id$v=19$m=65536,t=4,p=1$c2FsdHNhbHQ$placeholderplaceholderplaceholder'),
  (2, 3, 'kullanici@example.com', '$argon2id$v=19$m=65536,t=4,p=1$c2FsdHNhbHQ$placeholderplaceholderplaceholder');

INSERT INTO `products` (`id`, `title`, `price`) VALUES
  (1, 'Örnek Ürün A', 199.90),
  (2, 'Örnek Ürün B', 89.50);

INSERT INTO `orders` (`id`, `user_id`, `product_id`, `quantity`, `total`) VALUES
  (1, 2, 1, 1, 199.90);

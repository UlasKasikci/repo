<?php
declare(strict_types=1);

// Tur 2-16 negatif fixture (ChatGPT 2.3): session_set_cookie_params EKSİK —
// Secure ve SameSite parametreleri verilmemiş. qa-gate security_policy
// "HttpOnly + Secure + SameSite zorunlu" hatasıyla reddetmeli.
session_set_cookie_params([
    'lifetime' => 0,
    'path' => '/',
    'httponly' => true,
]);
session_start();

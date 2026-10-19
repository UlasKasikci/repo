<?php
declare(strict_types=1);

// v1.4.1 negatif: ara değişken taint — gate FAIL etmeli (doğrudan $_GET satırda yok).
$pdo = new PDO('sqlite::memory:');
$q = $_GET['q'] ?? '';
$pdo->query('SELECT * FROM products WHERE title LIKE "%' . $q . '%"');

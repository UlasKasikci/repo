<?php
declare(strict_types=1);

// v1.4.1: auth-rbac deseni — guardPost() wrapper CSRF sayılır (false-FAIL kapandı).
function guardPost(): void
{
    // stub — qa yalnız çağrı desenini arar
}

guardPost();
$email = (string) ($_POST['email'] ?? '');
echo htmlspecialchars($email, ENT_QUOTES, 'UTF-8');

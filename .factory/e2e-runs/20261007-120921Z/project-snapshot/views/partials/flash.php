<?php
/**
 * Tek seferlik bildirim (flash) bloğu.
 *
 * @var array{type: string, message: string}|null $flash
 */
if (isset($flash) && is_array($flash)) {
    $type = $flash['type'] ?? 'info';
    $message = $flash['message'] ?? '';
    if ($message !== '') {
        ?>
        <div class="flash flash--<?= e($type) ?>" role="status" data-auto-dismiss="true"><?= e($message) ?></div>
        <?php
    }
}

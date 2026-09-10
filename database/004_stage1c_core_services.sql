-- HimotheeCore v0.4.0 - Stage 1C core framework services
-- Adds auditable player sessions. Runtime duplicate-session authority remains
-- in-memory per server instance so stale database rows never lock players out.

SET NAMES utf8mb4;

CREATE TABLE IF NOT EXISTS `himo_player_sessions` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `account_id` BIGINT UNSIGNED NOT NULL,
    `character_id` BIGINT UNSIGNED NULL,
    `server_instance` VARCHAR(80) NOT NULL DEFAULT 'main',
    `server_id` INT NULL,
    `session_token` VARCHAR(64) NOT NULL,
    `started_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `last_seen_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `ended_at` TIMESTAMP NULL DEFAULT NULL,
    `end_reason` VARCHAR(120) NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_himo_player_sessions_token` (`session_token`),
    KEY `idx_himo_player_sessions_account_active` (`account_id`, `ended_at`),
    KEY `idx_himo_player_sessions_instance_active` (`server_instance`, `ended_at`),
    CONSTRAINT `fk_himo_player_sessions_account`
        FOREIGN KEY (`account_id`) REFERENCES `himo_accounts` (`id`)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT `fk_himo_player_sessions_character`
        FOREIGN KEY (`character_id`) REFERENCES `himo_characters` (`id`)
        ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `himo_schema_migrations` (`version`, `name`)
VALUES (3, '0003_stage1c_core_services')
ON DUPLICATE KEY UPDATE `name` = VALUES(`name`);

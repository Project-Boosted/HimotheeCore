-- HimotheeCore v0.4.0 - Stage 1C core framework services
-- Adds auditable player sessions and generic group/gang memberships.

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

CREATE TABLE IF NOT EXISTS `himo_groups` (
    `name` VARCHAR(50) NOT NULL,
    `label` VARCHAR(100) NOT NULL,
    `type` VARCHAR(40) NOT NULL DEFAULT 'group',
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`name`),
    KEY `idx_himo_groups_type_active` (`type`, `is_active`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `himo_group_grades` (
    `group_name` VARCHAR(50) NOT NULL,
    `grade` SMALLINT UNSIGNED NOT NULL,
    `name` VARCHAR(50) NOT NULL,
    `label` VARCHAR(100) NOT NULL,
    `is_boss` TINYINT(1) NOT NULL DEFAULT 0,
    `permissions` JSON NULL,
    PRIMARY KEY (`group_name`, `grade`),
    CONSTRAINT `fk_himo_group_grades_group`
        FOREIGN KEY (`group_name`) REFERENCES `himo_groups` (`name`)
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `himo_character_groups` (
    `character_id` BIGINT UNSIGNED NOT NULL,
    `group_name` VARCHAR(50) NOT NULL,
    `grade` SMALLINT UNSIGNED NOT NULL DEFAULT 0,
    `is_primary` TINYINT(1) NOT NULL DEFAULT 0,
    `joined_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`character_id`, `group_name`),
    KEY `idx_himo_character_groups_group` (`group_name`, `grade`),
    KEY `idx_himo_character_groups_primary` (`character_id`, `is_primary`),
    CONSTRAINT `fk_himo_character_groups_character`
        FOREIGN KEY (`character_id`) REFERENCES `himo_characters` (`id`)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT `fk_himo_character_groups_grade`
        FOREIGN KEY (`group_name`, `grade`) REFERENCES `himo_group_grades` (`group_name`, `grade`)
        ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `himo_groups` (`name`, `label`, `type`, `is_active`)
VALUES ('none', 'No Gang', 'gang', 1)
ON DUPLICATE KEY UPDATE `label` = VALUES(`label`), `type` = VALUES(`type`), `is_active` = VALUES(`is_active`);

INSERT INTO `himo_group_grades` (`group_name`, `grade`, `name`, `label`, `is_boss`, `permissions`)
VALUES ('none', 0, 'none', 'No Gang', 0, JSON_OBJECT())
ON DUPLICATE KEY UPDATE `name` = VALUES(`name`), `label` = VALUES(`label`), `is_boss` = VALUES(`is_boss`);

INSERT INTO `himo_schema_migrations` (`version`, `name`)
VALUES (3, '0003_stage1c_core_services')
ON DUPLICATE KEY UPDATE `name` = VALUES(`name`);

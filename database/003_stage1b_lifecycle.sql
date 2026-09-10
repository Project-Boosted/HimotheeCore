-- HimotheeCore v0.3.0 - Stage 1B lifecycle/appearance migration
-- Target: MySQL 8 / MariaDB 10.6+

SET NAMES utf8mb4;

CREATE TABLE IF NOT EXISTS `himo_character_appearance` (
    `character_id` BIGINT UNSIGNED NOT NULL,
    `model` VARCHAR(80) NOT NULL DEFAULT 'mp_m_freemode_01',
    `appearance` JSON NOT NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`character_id`),
    CONSTRAINT `fk_himo_character_appearance_character`
        FOREIGN KEY (`character_id`) REFERENCES `himo_characters` (`id`)
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `himo_schema_migrations` (`version`, `name`)
VALUES (2, '0002_stage1b_lifecycle_appearance')
ON DUPLICATE KEY UPDATE `name` = VALUES(`name`);

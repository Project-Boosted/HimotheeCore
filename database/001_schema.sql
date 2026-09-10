-- HimotheeCore v0.1.0 - Stage 1 schema
-- Target: MySQL 8 / MariaDB 10.6+

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

CREATE TABLE IF NOT EXISTS `himo_schema_migrations` (
    `version` INT UNSIGNED NOT NULL,
    `name` VARCHAR(120) NOT NULL,
    `applied_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`version`),
    UNIQUE KEY `uq_himo_schema_migrations_name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `himo_accounts` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `display_name` VARCHAR(100) NULL,
    `last_seen_name` VARCHAR(100) NULL,
    `is_banned` TINYINT(1) NOT NULL DEFAULT 0,
    `ban_reason` VARCHAR(500) NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `last_seen_at` TIMESTAMP NULL DEFAULT NULL,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_himo_accounts_last_seen` (`last_seen_at`),
    KEY `idx_himo_accounts_banned` (`is_banned`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `himo_identifiers` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `account_id` BIGINT UNSIGNED NOT NULL,
    `provider` VARCHAR(24) NOT NULL,
    `identifier` VARCHAR(100) NOT NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `last_seen_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_himo_identifier_provider_value` (`provider`, `identifier`),
    KEY `idx_himo_identifiers_account` (`account_id`),
    CONSTRAINT `fk_himo_identifiers_account`
        FOREIGN KEY (`account_id`) REFERENCES `himo_accounts` (`id`)
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `himo_characters` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `account_id` BIGINT UNSIGNED NOT NULL,
    `citizen_id` VARCHAR(20) NOT NULL,
    `slot` TINYINT UNSIGNED NOT NULL DEFAULT 1,
    `first_name` VARCHAR(50) NOT NULL,
    `last_name` VARCHAR(50) NOT NULL,
    `date_of_birth` DATE NULL,
    `gender` VARCHAR(16) NULL,
    `nationality` VARCHAR(60) NULL,
    `phone_number` VARCHAR(32) NULL,
    `is_deleted` TINYINT(1) NOT NULL DEFAULT 0,
    `last_played_at` TIMESTAMP NULL DEFAULT NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_himo_characters_citizen_id` (`citizen_id`),
    UNIQUE KEY `uq_himo_characters_account_slot` (`account_id`, `slot`),
    KEY `idx_himo_characters_account` (`account_id`),
    KEY `idx_himo_characters_name` (`last_name`, `first_name`),
    CONSTRAINT `fk_himo_characters_account`
        FOREIGN KEY (`account_id`) REFERENCES `himo_accounts` (`id`)
        ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `himo_character_metadata` (
    `character_id` BIGINT UNSIGNED NOT NULL,
    `metadata` JSON NULL,
    `position_x` DECIMAL(10,4) NULL,
    `position_y` DECIMAL(10,4) NULL,
    `position_z` DECIMAL(10,4) NULL,
    `heading` DECIMAL(8,4) NULL,
    `health` SMALLINT UNSIGNED NOT NULL DEFAULT 200,
    `armour` SMALLINT UNSIGNED NOT NULL DEFAULT 0,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`character_id`),
    CONSTRAINT `fk_himo_character_metadata_character`
        FOREIGN KEY (`character_id`) REFERENCES `himo_characters` (`id`)
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `himo_account_balances` (
    `character_id` BIGINT UNSIGNED NOT NULL,
    `account_type` VARCHAR(24) NOT NULL,
    `balance` BIGINT NOT NULL DEFAULT 0,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`character_id`, `account_type`),
    CONSTRAINT `fk_himo_balances_character`
        FOREIGN KEY (`character_id`) REFERENCES `himo_characters` (`id`)
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `himo_transactions` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `character_id` BIGINT UNSIGNED NULL,
    `account_type` VARCHAR(24) NOT NULL,
    `amount` BIGINT NOT NULL,
    `balance_after` BIGINT NULL,
    `transaction_type` VARCHAR(40) NOT NULL,
    `reference` VARCHAR(100) NULL,
    `description` VARCHAR(255) NULL,
    `metadata` JSON NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_himo_transactions_character_created` (`character_id`, `created_at`),
    KEY `idx_himo_transactions_reference` (`reference`),
    CONSTRAINT `fk_himo_transactions_character`
        FOREIGN KEY (`character_id`) REFERENCES `himo_characters` (`id`)
        ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `himo_jobs` (
    `name` VARCHAR(50) NOT NULL,
    `label` VARCHAR(100) NOT NULL,
    `type` VARCHAR(40) NULL,
    `default_duty` TINYINT(1) NOT NULL DEFAULT 0,
    `off_duty_pay` TINYINT(1) NOT NULL DEFAULT 0,
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `himo_job_grades` (
    `job_name` VARCHAR(50) NOT NULL,
    `grade` SMALLINT UNSIGNED NOT NULL,
    `name` VARCHAR(50) NOT NULL,
    `label` VARCHAR(100) NOT NULL,
    `salary` INT UNSIGNED NOT NULL DEFAULT 0,
    `is_boss` TINYINT(1) NOT NULL DEFAULT 0,
    `permissions` JSON NULL,
    PRIMARY KEY (`job_name`, `grade`),
    CONSTRAINT `fk_himo_job_grades_job`
        FOREIGN KEY (`job_name`) REFERENCES `himo_jobs` (`name`)
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `himo_character_jobs` (
    `character_id` BIGINT UNSIGNED NOT NULL,
    `job_name` VARCHAR(50) NOT NULL,
    `grade` SMALLINT UNSIGNED NOT NULL DEFAULT 0,
    `is_primary` TINYINT(1) NOT NULL DEFAULT 0,
    `on_duty` TINYINT(1) NOT NULL DEFAULT 0,
    `hired_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`character_id`, `job_name`),
    KEY `idx_himo_character_jobs_job` (`job_name`, `grade`),
    KEY `idx_himo_character_jobs_primary` (`character_id`, `is_primary`),
    CONSTRAINT `fk_himo_character_jobs_character`
        FOREIGN KEY (`character_id`) REFERENCES `himo_characters` (`id`)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT `fk_himo_character_jobs_grade`
        FOREIGN KEY (`job_name`, `grade`) REFERENCES `himo_job_grades` (`job_name`, `grade`)
        ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `himo_organisations` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `name` VARCHAR(80) NOT NULL,
    `label` VARCHAR(120) NOT NULL,
    `type` VARCHAR(40) NOT NULL DEFAULT 'business',
    `owner_character_id` BIGINT UNSIGNED NULL,
    `bank_balance` BIGINT NOT NULL DEFAULT 0,
    `metadata` JSON NULL,
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_himo_organisations_name` (`name`),
    KEY `idx_himo_organisations_type_active` (`type`, `is_active`),
    CONSTRAINT `fk_himo_organisations_owner`
        FOREIGN KEY (`owner_character_id`) REFERENCES `himo_characters` (`id`)
        ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `himo_organisation_roles` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `organisation_id` BIGINT UNSIGNED NOT NULL,
    `name` VARCHAR(60) NOT NULL,
    `label` VARCHAR(100) NOT NULL,
    `rank` SMALLINT UNSIGNED NOT NULL DEFAULT 0,
    `permissions` JSON NULL,
    `is_owner_role` TINYINT(1) NOT NULL DEFAULT 0,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_himo_org_role_name` (`organisation_id`, `name`),
    KEY `idx_himo_org_role_rank` (`organisation_id`, `rank`),
    CONSTRAINT `fk_himo_org_roles_org`
        FOREIGN KEY (`organisation_id`) REFERENCES `himo_organisations` (`id`)
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `himo_organisation_members` (
    `organisation_id` BIGINT UNSIGNED NOT NULL,
    `character_id` BIGINT UNSIGNED NOT NULL,
    `role_id` BIGINT UNSIGNED NOT NULL,
    `joined_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`organisation_id`, `character_id`),
    KEY `idx_himo_org_members_character` (`character_id`),
    KEY `idx_himo_org_members_role` (`role_id`),
    CONSTRAINT `fk_himo_org_members_org`
        FOREIGN KEY (`organisation_id`) REFERENCES `himo_organisations` (`id`)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT `fk_himo_org_members_character`
        FOREIGN KEY (`character_id`) REFERENCES `himo_characters` (`id`)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT `fk_himo_org_members_role`
        FOREIGN KEY (`role_id`) REFERENCES `himo_organisation_roles` (`id`)
        ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `himo_vehicles` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `owner_character_id` BIGINT UNSIGNED NULL,
    `organisation_id` BIGINT UNSIGNED NULL,
    `plate` VARCHAR(16) NOT NULL,
    `model` VARCHAR(80) NOT NULL,
    `vehicle_type` VARCHAR(24) NOT NULL DEFAULT 'automobile',
    `garage` VARCHAR(80) NULL,
    `state` VARCHAR(24) NOT NULL DEFAULT 'stored',
    `fuel` DECIMAL(5,2) NOT NULL DEFAULT 100.00,
    `engine_health` DECIMAL(8,2) NOT NULL DEFAULT 1000.00,
    `body_health` DECIMAL(8,2) NOT NULL DEFAULT 1000.00,
    `properties` JSON NULL,
    `metadata` JSON NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_himo_vehicles_plate` (`plate`),
    KEY `idx_himo_vehicles_owner` (`owner_character_id`),
    KEY `idx_himo_vehicles_org` (`organisation_id`),
    KEY `idx_himo_vehicles_garage_state` (`garage`, `state`),
    CONSTRAINT `fk_himo_vehicles_owner`
        FOREIGN KEY (`owner_character_id`) REFERENCES `himo_characters` (`id`)
        ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT `fk_himo_vehicles_org`
        FOREIGN KEY (`organisation_id`) REFERENCES `himo_organisations` (`id`)
        ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `himo_audit_log` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `account_id` BIGINT UNSIGNED NULL,
    `character_id` BIGINT UNSIGNED NULL,
    `source` INT NULL,
    `action` VARCHAR(80) NOT NULL,
    `target_type` VARCHAR(40) NULL,
    `target_id` VARCHAR(80) NULL,
    `data` JSON NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_himo_audit_action_created` (`action`, `created_at`),
    KEY `idx_himo_audit_account_created` (`account_id`, `created_at`),
    KEY `idx_himo_audit_character_created` (`character_id`, `created_at`),
    CONSTRAINT `fk_himo_audit_account`
        FOREIGN KEY (`account_id`) REFERENCES `himo_accounts` (`id`)
        ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT `fk_himo_audit_character`
        FOREIGN KEY (`character_id`) REFERENCES `himo_characters` (`id`)
        ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `himo_schema_migrations` (`version`, `name`)
VALUES (1, '0001_stage1_foundation')
ON DUPLICATE KEY UPDATE `name` = VALUES(`name`);

SET FOREIGN_KEY_CHECKS = 1;

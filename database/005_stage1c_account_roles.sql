-- HimotheeCore v0.4.2 - native account roles and permissions
-- ACE remains supported; these tables provide framework-owned persistent roles.

SET NAMES utf8mb4;

CREATE TABLE IF NOT EXISTS `himo_roles` (
    `name` VARCHAR(50) NOT NULL,
    `label` VARCHAR(100) NOT NULL,
    `priority` SMALLINT NOT NULL DEFAULT 0,
    `is_system` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `himo_role_permissions` (
    `role_name` VARCHAR(50) NOT NULL,
    `permission` VARCHAR(100) NOT NULL,
    PRIMARY KEY (`role_name`, `permission`),
    CONSTRAINT `fk_himo_role_permissions_role`
        FOREIGN KEY (`role_name`) REFERENCES `himo_roles` (`name`)
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `himo_account_roles` (
    `account_id` BIGINT UNSIGNED NOT NULL,
    `role_name` VARCHAR(50) NOT NULL,
    `granted_by_account_id` BIGINT UNSIGNED NULL,
    `granted_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`account_id`, `role_name`),
    KEY `idx_himo_account_roles_role` (`role_name`, `account_id`),
    CONSTRAINT `fk_himo_account_roles_account`
        FOREIGN KEY (`account_id`) REFERENCES `himo_accounts` (`id`)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT `fk_himo_account_roles_role`
        FOREIGN KEY (`role_name`) REFERENCES `himo_roles` (`name`)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT `fk_himo_account_roles_granted_by`
        FOREIGN KEY (`granted_by_account_id`) REFERENCES `himo_accounts` (`id`)
        ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `himo_roles` (`name`, `label`, `priority`, `is_system`) VALUES
    ('owner', 'Owner', 1000, 1),
    ('admin', 'Administrator', 800, 1),
    ('staff', 'Staff', 500, 1),
    ('dev', 'Developer', 400, 1)
ON DUPLICATE KEY UPDATE
    `label` = VALUES(`label`),
    `priority` = VALUES(`priority`),
    `is_system` = VALUES(`is_system`);

INSERT IGNORE INTO `himo_role_permissions` (`role_name`, `permission`) VALUES
    ('owner', 'himo.*'),
    ('admin', 'himo.admin'),
    ('admin', 'himo.staff'),
    ('admin', 'himo.dev'),
    ('staff', 'himo.staff'),
    ('dev', 'himo.dev');

-- Upgrade bootstrap: if an existing development install already has accounts but
-- no Himothee owner, promote the earliest account exactly once.
INSERT IGNORE INTO `himo_account_roles` (`account_id`, `role_name`, `granted_by_account_id`)
SELECT MIN(a.`id`), 'owner', NULL
FROM `himo_accounts` a
HAVING MIN(a.`id`) IS NOT NULL
   AND NOT EXISTS (
       SELECT 1 FROM `himo_account_roles` ar WHERE ar.`role_name` = 'owner'
   );

INSERT INTO `himo_schema_migrations` (`version`, `name`)
VALUES (4, '0004_stage1c_account_roles')
ON DUPLICATE KEY UPDATE `name` = VALUES(`name`);

-- HimotheeCore v0.6.0 - Stage 1E Project Sloth compatibility
-- Provides QBCore-style persistence surfaces for Project Sloth resources while
-- keeping HimotheeCore's native character, job and vehicle tables authoritative.

SET NAMES utf8mb4;

-- Baseline public-service / property jobs used by ps-housing, ps-realtor,
-- ps-dispatch and ps-mdt. Servers can extend these definitions later.
INSERT INTO `himo_jobs` (`name`, `label`, `type`, `default_duty`, `off_duty_pay`, `is_active`) VALUES
    ('police', 'Police', 'leo', 1, 0, 1),
    ('ambulance', 'Ambulance', 'ems', 1, 0, 1),
    ('realestate', 'Real Estate', 'realestate', 1, 0, 1)
ON DUPLICATE KEY UPDATE
    `label` = VALUES(`label`),
    `type` = VALUES(`type`),
    `is_active` = 1;

INSERT INTO `himo_job_grades` (`job_name`, `grade`, `name`, `label`, `salary`, `is_boss`, `permissions`) VALUES
    ('police', 0, 'recruit', 'Recruit', 500, 0, JSON_OBJECT()),
    ('police', 1, 'officer', 'Officer', 650, 0, JSON_OBJECT()),
    ('police', 2, 'sergeant', 'Sergeant', 800, 0, JSON_OBJECT()),
    ('police', 3, 'lieutenant', 'Lieutenant', 950, 0, JSON_OBJECT()),
    ('police', 4, 'chief', 'Chief', 1200, 1, JSON_OBJECT()),
    ('ambulance', 0, 'trainee', 'Trainee', 500, 0, JSON_OBJECT()),
    ('ambulance', 1, 'paramedic', 'Paramedic', 650, 0, JSON_OBJECT()),
    ('ambulance', 2, 'doctor', 'Doctor', 850, 0, JSON_OBJECT()),
    ('ambulance', 3, 'supervisor', 'Supervisor', 1000, 0, JSON_OBJECT()),
    ('ambulance', 4, 'chief', 'Chief', 1200, 1, JSON_OBJECT()),
    ('realestate', 0, 'agent', 'Agent', 450, 0, JSON_OBJECT()),
    ('realestate', 1, 'senior_agent', 'Senior Agent', 600, 0, JSON_OBJECT()),
    ('realestate', 2, 'manager', 'Manager', 800, 1, JSON_OBJECT())
ON DUPLICATE KEY UPDATE
    `name` = VALUES(`name`),
    `label` = VALUES(`label`),
    `salary` = VALUES(`salary`),
    `is_boss` = VALUES(`is_boss`);

-- Native MDT extensions. The public player_vehicles compatibility table below
-- mirrors these fields so changes made by ps-mdt can be written back safely.
ALTER TABLE `himo_vehicles`
    ADD COLUMN IF NOT EXISTS `mdt_vehicle_information` TEXT NULL AFTER `trunk`,
    ADD COLUMN IF NOT EXISTS `mdt_vehicle_points` INT NOT NULL DEFAULT 0 AFTER `mdt_vehicle_information`,
    ADD COLUMN IF NOT EXISTS `mdt_vehicle_status` VARCHAR(500) NOT NULL DEFAULT 'valid' AFTER `mdt_vehicle_points`,
    ADD COLUMN IF NOT EXISTS `mdt_vehicle_stolen` TINYINT(1) NOT NULL DEFAULT 0 AFTER `mdt_vehicle_status`,
    ADD COLUMN IF NOT EXISTS `mdt_vehicle_boloactive` TINYINT(1) NOT NULL DEFAULT 0 AFTER `mdt_vehicle_stolen`,
    ADD COLUMN IF NOT EXISTS `mdt_vehicle_image` VARCHAR(255) NULL AFTER `mdt_vehicle_boloactive`;

-- QBCore-compatible character mirror. Project Sloth uses this for offline
-- lookups and metadata updates. Runtime refresh is owned by himo_qb_bridge.
CREATE TABLE IF NOT EXISTS `players` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `citizenid` VARCHAR(50) NOT NULL,
    `cid` INT NOT NULL DEFAULT 1,
    `license` VARCHAR(255) NULL,
    `name` VARCHAR(255) NULL,
    `money` LONGTEXT NULL,
    `charinfo` LONGTEXT NULL,
    `job` LONGTEXT NULL,
    `gang` LONGTEXT NULL,
    `position` LONGTEXT NULL,
    `metadata` LONGTEXT NULL,
    `inventory` LONGTEXT NULL,
    `last_updated` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_players_citizenid` (`citizenid`),
    KEY `idx_players_name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- QBCore-compatible vehicle mirror. ps-mdt adds its own columns to this table
-- as part of its upstream SQL; they are also included here so first boot is safe.
CREATE TABLE IF NOT EXISTS `player_vehicles` (
    `id` BIGINT UNSIGNED NOT NULL,
    `license` VARCHAR(255) NULL,
    `citizenid` VARCHAR(50) NULL,
    `vehicle` VARCHAR(80) NOT NULL,
    `hash` VARCHAR(80) NULL,
    `mods` LONGTEXT NULL,
    `plate` VARCHAR(16) NOT NULL,
    `fakeplate` VARCHAR(16) NULL,
    `garage` VARCHAR(80) NULL,
    `fuel` INT NOT NULL DEFAULT 100,
    `engine` FLOAT NOT NULL DEFAULT 1000,
    `body` FLOAT NOT NULL DEFAULT 1000,
    `state` INT NOT NULL DEFAULT 1,
    `depotprice` INT NOT NULL DEFAULT 0,
    `drivingdistance` INT NULL,
    `status` TEXT NULL,
    `balance` INT NOT NULL DEFAULT 0,
    `paymentamount` INT NOT NULL DEFAULT 0,
    `paymentsleft` INT NOT NULL DEFAULT 0,
    `financetime` INT NOT NULL DEFAULT 0,
    `glovebox` LONGTEXT NULL,
    `trunk` LONGTEXT NULL,
    `mdt_vehicle_information` TEXT NULL,
    `mdt_vehicle_points` INT NOT NULL DEFAULT 0,
    `mdt_vehicle_status` VARCHAR(500) NOT NULL DEFAULT 'valid',
    `mdt_vehicle_stolen` TINYINT(1) NOT NULL DEFAULT 0,
    `mdt_vehicle_boloactive` TINYINT(1) NOT NULL DEFAULT 0,
    `mdt_vehicle_image` VARCHAR(255) NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_player_vehicles_plate` (`plate`),
    KEY `idx_player_vehicles_citizenid` (`citizenid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Seed compatibility rows for every existing character.
INSERT INTO `players` (`citizenid`, `cid`, `license`, `name`, `money`, `charinfo`, `job`, `gang`, `position`, `metadata`, `inventory`)
SELECT
    c.`citizen_id`,
    c.`slot`,
    (SELECT i.`identifier` FROM `himo_identifiers` i WHERE i.`account_id` = c.`account_id` AND i.`provider` = 'license' ORDER BY i.`id` LIMIT 1),
    CONCAT(c.`first_name`, ' ', c.`last_name`),
    JSON_OBJECT(
        'cash', COALESCE((SELECT b.`balance` FROM `himo_account_balances` b WHERE b.`character_id` = c.`id` AND b.`account_type` = 'cash' LIMIT 1), 0),
        'bank', COALESCE((SELECT b.`balance` FROM `himo_account_balances` b WHERE b.`character_id` = c.`id` AND b.`account_type` = 'bank' LIMIT 1), 0)
    ),
    JSON_OBJECT(
        'firstname', c.`first_name`, 'lastname', c.`last_name`,
        'birthdate', COALESCE(DATE_FORMAT(c.`date_of_birth`, '%Y-%m-%d'), ''),
        'gender', COALESCE(c.`gender`, ''), 'nationality', COALESCE(c.`nationality`, ''),
        'phone', COALESCE(c.`phone_number`, ''), 'account', c.`citizen_id`
    ),
    COALESCE((
        SELECT JSON_OBJECT(
            'name', cj.`job_name`, 'label', j.`label`, 'type', COALESCE(j.`type`, 'none'),
            'onduty', cj.`on_duty`, 'isboss', g.`is_boss`, 'payment', g.`salary`,
            'grade', JSON_OBJECT('name', g.`name`, 'level', cj.`grade`)
        )
        FROM `himo_character_jobs` cj
        JOIN `himo_jobs` j ON j.`name` = cj.`job_name`
        JOIN `himo_job_grades` g ON g.`job_name` = cj.`job_name` AND g.`grade` = cj.`grade`
        WHERE cj.`character_id` = c.`id` AND cj.`is_primary` = 1
        LIMIT 1
    ), JSON_OBJECT('name', 'unemployed', 'label', 'Unemployed', 'type', 'civilian', 'onduty', 0, 'isboss', 0, 'payment', 0, 'grade', JSON_OBJECT('name', 'unemployed', 'level', 0))),
    JSON_OBJECT('name', 'none', 'label', 'No Gang', 'isboss', 0, 'grade', JSON_OBJECT('name', 'none', 'level', 0)),
    JSON_OBJECT(
        'x', COALESCE(m.`position_x`, 0), 'y', COALESCE(m.`position_y`, 0),
        'z', COALESCE(m.`position_z`, 0), 'w', COALESCE(m.`heading`, 0)
    ),
    COALESCE(m.`metadata`, JSON_OBJECT()),
    c.`inventory`
FROM `himo_characters` c
LEFT JOIN `himo_character_metadata` m ON m.`character_id` = c.`id`
WHERE c.`is_deleted` = 0
ON DUPLICATE KEY UPDATE
    `cid` = VALUES(`cid`), `license` = VALUES(`license`), `name` = VALUES(`name`),
    `money` = VALUES(`money`), `charinfo` = VALUES(`charinfo`), `job` = VALUES(`job`),
    `position` = VALUES(`position`), `metadata` = VALUES(`metadata`), `inventory` = VALUES(`inventory`);

-- Seed compatibility rows for every native vehicle.
INSERT INTO `player_vehicles` (`id`, `citizenid`, `vehicle`, `hash`, `mods`, `plate`, `garage`, `fuel`, `engine`, `body`, `state`, `glovebox`, `trunk`, `mdt_vehicle_information`, `mdt_vehicle_points`, `mdt_vehicle_status`, `mdt_vehicle_stolen`, `mdt_vehicle_boloactive`, `mdt_vehicle_image`)
SELECT
    v.`id`, c.`citizen_id`, v.`model`, v.`model`, v.`properties`, v.`plate`, v.`garage`,
    ROUND(v.`fuel`), v.`engine_health`, v.`body_health`,
    CASE WHEN v.`state` = 'stored' THEN 1 WHEN v.`state` = 'impound' THEN 2 ELSE 0 END,
    v.`glovebox`, v.`trunk`, v.`mdt_vehicle_information`, v.`mdt_vehicle_points`,
    v.`mdt_vehicle_status`, v.`mdt_vehicle_stolen`, v.`mdt_vehicle_boloactive`, v.`mdt_vehicle_image`
FROM `himo_vehicles` v
LEFT JOIN `himo_characters` c ON c.`id` = v.`owner_character_id`
ON DUPLICATE KEY UPDATE
    `citizenid` = VALUES(`citizenid`), `vehicle` = VALUES(`vehicle`), `hash` = VALUES(`hash`),
    `mods` = VALUES(`mods`), `garage` = VALUES(`garage`), `fuel` = VALUES(`fuel`),
    `engine` = VALUES(`engine`), `body` = VALUES(`body`), `state` = VALUES(`state`),
    `glovebox` = VALUES(`glovebox`), `trunk` = VALUES(`trunk`),
    `mdt_vehicle_information` = VALUES(`mdt_vehicle_information`),
    `mdt_vehicle_points` = VALUES(`mdt_vehicle_points`),
    `mdt_vehicle_status` = VALUES(`mdt_vehicle_status`),
    `mdt_vehicle_stolen` = VALUES(`mdt_vehicle_stolen`),
    `mdt_vehicle_boloactive` = VALUES(`mdt_vehicle_boloactive`),
    `mdt_vehicle_image` = VALUES(`mdt_vehicle_image`);

-- MDT changes to compatibility character metadata/inventory are written back to
-- native HimotheeCore storage immediately. These are deliberately single-statement
-- triggers: txAdmin sends SQL through the MySQL protocol, where DELIMITER is not
-- valid SQL and BEGIN/END trigger bodies cannot be passed as CLI-style scripts.
DROP TRIGGER IF EXISTS `trg_himo_players_writeback`;
DROP TRIGGER IF EXISTS `trg_himo_players_metadata_writeback`;
DROP TRIGGER IF EXISTS `trg_himo_players_inventory_writeback`;
CREATE TRIGGER `trg_himo_players_metadata_writeback`
AFTER UPDATE ON `players`
FOR EACH ROW
UPDATE `himo_character_metadata` m
JOIN `himo_characters` c ON c.`id` = m.`character_id`
SET m.`metadata` = NEW.`metadata`
WHERE c.`citizen_id` = NEW.`citizenid`
  AND NOT (NEW.`metadata` <=> OLD.`metadata`);

CREATE TRIGGER `trg_himo_players_inventory_writeback`
AFTER UPDATE ON `players`
FOR EACH ROW
UPDATE `himo_characters`
SET `inventory` = NEW.`inventory`
WHERE `citizen_id` = NEW.`citizenid`
  AND NOT (NEW.`inventory` <=> OLD.`inventory`);

DROP TRIGGER IF EXISTS `trg_himo_player_vehicles_writeback`;
CREATE TRIGGER `trg_himo_player_vehicles_writeback`
AFTER UPDATE ON `player_vehicles`
FOR EACH ROW
UPDATE `himo_vehicles`
SET
    `mdt_vehicle_information` = NEW.`mdt_vehicle_information`,
    `mdt_vehicle_points` = NEW.`mdt_vehicle_points`,
    `mdt_vehicle_status` = NEW.`mdt_vehicle_status`,
    `mdt_vehicle_stolen` = NEW.`mdt_vehicle_stolen`,
    `mdt_vehicle_boloactive` = NEW.`mdt_vehicle_boloactive`,
    `mdt_vehicle_image` = NEW.`mdt_vehicle_image`
WHERE `plate` = NEW.`plate`;

INSERT INTO `himo_schema_migrations` (`version`, `name`)
VALUES (6, '0006_stage1e_project_sloth')
ON DUPLICATE KEY UPDATE `name` = VALUES(`name`);

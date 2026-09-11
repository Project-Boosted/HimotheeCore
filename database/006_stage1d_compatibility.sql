-- HimotheeCore v0.5.0 - Stage 1D compatibility storage
-- Adds the persistence columns used by ox_inventory's Qbox bridge while keeping
-- HimotheeCore's native character and vehicle tables authoritative.

SET NAMES utf8mb4;

ALTER TABLE `himo_characters`
    ADD COLUMN IF NOT EXISTS `inventory` LONGTEXT NULL AFTER `phone_number`;

ALTER TABLE `himo_vehicles`
    ADD COLUMN IF NOT EXISTS `glovebox` LONGTEXT NULL AFTER `metadata`,
    ADD COLUMN IF NOT EXISTS `trunk` LONGTEXT NULL AFTER `glovebox`;

INSERT INTO `himo_schema_migrations` (`version`, `name`)
VALUES (5, '0005_stage1d_compatibility')
ON DUPLICATE KEY UPDATE `name` = VALUES(`name`);

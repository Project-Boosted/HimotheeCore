-- HimotheeCore Stage 1E - ps-adminmenu persistence/runtime compatibility.
-- ps-adminmenu assumes QBCore's admin tables and AUTO_INCREMENT vehicle ids.
-- Keep these surfaces available without making Project Sloth own native storage.

local schemaStatements = {
    [[
CREATE TABLE IF NOT EXISTS `bans` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `name` VARCHAR(50) NULL,
    `license` VARCHAR(50) NULL,
    `discord` VARCHAR(50) NULL,
    `ip` VARCHAR(50) NULL,
    `reason` TEXT NULL,
    `expire` INT NULL,
    `bannedby` VARCHAR(255) NOT NULL DEFAULT 'LeBanhammer',
    PRIMARY KEY (`id`),
    KEY `idx_bans_license` (`license`),
    KEY `idx_bans_discord` (`discord`),
    KEY `idx_bans_ip` (`ip`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci
    ]],
    [[
CREATE TABLE IF NOT EXISTS `player_warns` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `senderIdentifier` VARCHAR(50) NULL,
    `targetIdentifier` VARCHAR(50) NULL,
    `reason` TEXT NULL,
    `warnId` VARCHAR(50) NULL,
    PRIMARY KEY (`id`),
    KEY `idx_player_warns_target` (`targetIdentifier`),
    KEY `idx_player_warns_warnid` (`warnId`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci
    ]],
    [[ALTER TABLE `player_vehicles` MODIFY COLUMN `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT]],
    [[DROP TRIGGER IF EXISTS `trg_himo_player_vehicles_insert_writeback`]],
    [[
CREATE TRIGGER `trg_himo_player_vehicles_insert_writeback`
AFTER INSERT ON `player_vehicles`
FOR EACH ROW
INSERT INTO `himo_vehicles`
    (`id`, `owner_character_id`, `plate`, `model`, `garage`, `state`, `fuel`, `engine_health`, `body_health`,
     `properties`, `glovebox`, `trunk`, `mdt_vehicle_information`, `mdt_vehicle_points`, `mdt_vehicle_status`,
     `mdt_vehicle_stolen`, `mdt_vehicle_boloactive`, `mdt_vehicle_image`)
SELECT
    NEW.`id`, c.`id`, NEW.`plate`, NEW.`vehicle`, NEW.`garage`,
    CASE WHEN NEW.`state` = 1 THEN 'stored' WHEN NEW.`state` = 2 THEN 'impound' ELSE 'out' END,
    COALESCE(NEW.`fuel`, 100), COALESCE(NEW.`engine`, 1000), COALESCE(NEW.`body`, 1000),
    CASE WHEN JSON_VALID(NEW.`mods`) THEN NEW.`mods` ELSE JSON_OBJECT() END,
    NEW.`glovebox`, NEW.`trunk`, NEW.`mdt_vehicle_information`, NEW.`mdt_vehicle_points`, NEW.`mdt_vehicle_status`,
    NEW.`mdt_vehicle_stolen`, NEW.`mdt_vehicle_boloactive`, NEW.`mdt_vehicle_image`
FROM `himo_characters` c
WHERE c.`citizen_id` COLLATE utf8mb4_general_ci = NEW.`citizenid`
ON DUPLICATE KEY UPDATE
    `owner_character_id` = VALUES(`owner_character_id`),
    `plate` = VALUES(`plate`),
    `model` = VALUES(`model`),
    `garage` = VALUES(`garage`),
    `state` = VALUES(`state`),
    `fuel` = VALUES(`fuel`),
    `engine_health` = VALUES(`engine_health`),
    `body_health` = VALUES(`body_health`),
    `properties` = VALUES(`properties`),
    `glovebox` = VALUES(`glovebox`),
    `trunk` = VALUES(`trunk`),
    `mdt_vehicle_information` = VALUES(`mdt_vehicle_information`),
    `mdt_vehicle_points` = VALUES(`mdt_vehicle_points`),
    `mdt_vehicle_status` = VALUES(`mdt_vehicle_status`),
    `mdt_vehicle_stolen` = VALUES(`mdt_vehicle_stolen`),
    `mdt_vehicle_boloactive` = VALUES(`mdt_vehicle_boloactive`),
    `mdt_vehicle_image` = VALUES(`mdt_vehicle_image`)
    ]],
    [[DROP TRIGGER IF EXISTS `trg_himo_player_vehicles_writeback`]],
    [[
CREATE TRIGGER `trg_himo_player_vehicles_writeback`
AFTER UPDATE ON `player_vehicles`
FOR EACH ROW
UPDATE `himo_vehicles`
SET
    `plate` = NEW.`plate`,
    `model` = NEW.`vehicle`,
    `garage` = NEW.`garage`,
    `state` = CASE WHEN NEW.`state` = 1 THEN 'stored' WHEN NEW.`state` = 2 THEN 'impound' ELSE 'out' END,
    `fuel` = COALESCE(NEW.`fuel`, 100),
    `engine_health` = COALESCE(NEW.`engine`, 1000),
    `body_health` = COALESCE(NEW.`body`, 1000),
    `properties` = CASE WHEN JSON_VALID(NEW.`mods`) THEN NEW.`mods` ELSE `properties` END,
    `glovebox` = NEW.`glovebox`,
    `trunk` = NEW.`trunk`,
    `mdt_vehicle_information` = NEW.`mdt_vehicle_information`,
    `mdt_vehicle_points` = NEW.`mdt_vehicle_points`,
    `mdt_vehicle_status` = NEW.`mdt_vehicle_status`,
    `mdt_vehicle_stolen` = NEW.`mdt_vehicle_stolen`,
    `mdt_vehicle_boloactive` = NEW.`mdt_vehicle_boloactive`,
    `mdt_vehicle_image` = NEW.`mdt_vehicle_image`
WHERE `id` = NEW.`id`
  AND (
      NOT (NEW.`plate` <=> OLD.`plate`)
      OR NOT (NEW.`vehicle` <=> OLD.`vehicle`)
      OR NOT (NEW.`garage` <=> OLD.`garage`)
      OR NOT (NEW.`state` <=> OLD.`state`)
      OR NOT (NEW.`fuel` <=> OLD.`fuel`)
      OR NOT (NEW.`engine` <=> OLD.`engine`)
      OR NOT (NEW.`body` <=> OLD.`body`)
      OR NOT (NEW.`mods` <=> OLD.`mods`)
      OR NOT (NEW.`glovebox` <=> OLD.`glovebox`)
      OR NOT (NEW.`trunk` <=> OLD.`trunk`)
      OR NOT (NEW.`mdt_vehicle_information` <=> OLD.`mdt_vehicle_information`)
      OR NOT (NEW.`mdt_vehicle_points` <=> OLD.`mdt_vehicle_points`)
      OR NOT (NEW.`mdt_vehicle_status` <=> OLD.`mdt_vehicle_status`)
      OR NOT (NEW.`mdt_vehicle_stolen` <=> OLD.`mdt_vehicle_stolen`)
      OR NOT (NEW.`mdt_vehicle_boloactive` <=> OLD.`mdt_vehicle_boloactive`)
      OR NOT (NEW.`mdt_vehicle_image` <=> OLD.`mdt_vehicle_image`)
  )
    ]],
}

local ready = false

local function provisionAdminCompatibility()
    if ready then return true end

    for index, sql in ipairs(schemaStatements) do
        local ok, err = pcall(MySQL.query.await, sql)
        if not ok then
            print(('[himo_qb_bridge] ps-adminmenu schema step %d failed: %s'):format(index, tostring(err)))
            return false
        end
    end

    ready = true
    print('[himo_qb_bridge] ps-adminmenu compatibility schema ready')
    return true
end

CreateThread(function()
    while GetResourceState('oxmysql') ~= 'started' do Wait(250) end
    Wait(250)
    provisionAdminCompatibility()
end)

exports('EnsureAdminCompatibility', provisionAdminCompatibility)

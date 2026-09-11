-- HimotheeCore qb-inventory compatibility configuration.
-- Jim Bridge loads this file directly to discover inventory limits.
Config = Config or {}

Config.MaxInventoryWeight = GetConvar('inventory:weight', '120000') * 1
Config.MaxInventorySlots = GetConvar('inventory:slots', '50') * 1

-- Also expose the newer qb-inventory key names for resources that read this file directly.
Config.MaxWeight = Config.MaxInventoryWeight
Config.MaxSlots = Config.MaxInventorySlots

return Config

-- New-layout qb-inventory compatibility configuration.
Config = Config or {}

Config.MaxWeight = GetConvar('inventory:weight', '120000') * 1
Config.MaxSlots = GetConvar('inventory:slots', '50') * 1

return Config

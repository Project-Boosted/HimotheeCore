Config = {}

Config.Debug = false
Config.MaxLevel = 50
Config.Command = 'miningskill'

-- Total XP required for a level is calculated as:
-- floor(BaseXp * ((level - 1) ^ Exponent))
Config.Curve = {
    BaseXp = 50,
    Exponent = 1.50,
}

Config.XpPerAction = {
    mine = 10,
    crack = 8,
    wash = 7,
    pan = 6,
}

-- Progression-side anti-spam only. This does not replace jim-mining's own
-- gameplay checks; it prevents repeated reward-event calls from farming skill XP.
Config.MinimumActionIntervalMs = {
    mine = 2500,
    crack = 2000,
    wash = 2000,
    pan = 2000,
}

Config.NotifyEveryAction = false
Config.NotifyBonus = true

-- Mining gets a chance to produce one additional whitelisted reward item.
-- At the defaults the chance rises by 0.6 percentage points per level and caps
-- at 30%. Only items in ItemWhitelist can ever be duplicated by progression.
Config.BonusYield = {
    Enabled = true,
    Amount = 1,
    PerLevelChance = 0.006,
    MaxChance = 0.30,
    ItemWhitelist = {
        stone = true,
    }
}

Config.Ranks = {
    { level = 1,  label = 'New Starter' },
    { level = 5,  label = 'Apprentice Miner' },
    { level = 10, label = 'Miner' },
    { level = 20, label = 'Skilled Miner' },
    { level = 30, label = 'Senior Miner' },
    { level = 40, label = 'Master Miner' },
    { level = 50, label = 'Mining Legend' },
}

Config.ActionLabels = {
    mine = 'Mining',
    crack = 'Stone Cracking',
    wash = 'Stone Washing',
    pan = 'Gold Panning',
}

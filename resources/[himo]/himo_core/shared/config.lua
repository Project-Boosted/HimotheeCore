HimoConfig = HimoConfig or {}

HimoConfig.FrameworkName = 'HimotheeCore'
HimoConfig.Version = '0.5.8'
HimoConfig.RequiredSchemaVersion = 5
HimoConfig.Stage = '1D'
HimoConfig.Build = 'qb-function-ref-fix'

HimoConfig.Debug = GetConvarInt('himo:debug', 0) == 1
HimoConfig.MaxCharacters = math.max(1, GetConvarInt('himo:maxCharacters', 4))
HimoConfig.StartingCash = math.max(0, GetConvarInt('himo:startingCash', 500))
HimoConfig.StartingBank = math.max(0, GetConvarInt('himo:startingBank', 5000))
HimoConfig.AutoSaveMs = math.max(15000, GetConvarInt('himo:autoSaveMs', 60000))
HimoConfig.ServerInstance = GetConvar('himo:serverInstance', 'main')

HimoConfig.DefaultMetadata = {
    hunger = 100,
    thirst = 100,
    stress = 0,
    isdead = false,
    inlaststand = false,
    ishandcuffed = false,
    tracker = false,
    licences = {}
}

-- Only explicitly safe gameplay state is replicated to clients/statebags.
-- Server-only metadata can still be stored through the same metadata API.
HimoConfig.ReplicatedMetadata = {
    hunger = true,
    thirst = true,
    stress = true,
    isdead = true,
    inlaststand = true,
    ishandcuffed = true,
    tracker = true
}

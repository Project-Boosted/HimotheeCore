HimoConfig = HimoConfig or {}

HimoConfig.FrameworkName = 'HimotheeCore'
HimoConfig.Version = '0.2.1'
HimoConfig.RequiredSchemaVersion = 1
HimoConfig.Debug = GetConvarInt('himo:debug', 0) == 1
HimoConfig.MaxCharacters = math.max(1, GetConvarInt('himo:maxCharacters', 4))
HimoConfig.StartingCash = math.max(0, GetConvarInt('himo:startingCash', 500))
HimoConfig.StartingBank = math.max(0, GetConvarInt('himo:startingBank', 5000))
HimoConfig.AutoSaveMs = math.max(15000, GetConvarInt('himo:autoSaveMs', 60000))

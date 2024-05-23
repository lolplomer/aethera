local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Mobs = require(ReplicatedStorage.GameModules.Mobs)

local MobService = Knit.CreateService {
    Name = "MobService",
    Client = {},
}

function MobService:Spawn(MobName, Level, CF)
    local Mob = Mobs[MobName]

    if Mob then
        local StatService = Knit.GetService('StatService')

        
    end
end


function MobService:KnitStart()
    
end


function MobService:KnitInit()
    
end


return MobService

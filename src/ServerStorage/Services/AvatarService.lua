local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)

local AvatarService = Knit.CreateService {
    Name = "AvatarService",
    Client = {},
}

local PlayerDataService

function AvatarService:KnitInit()
    PlayerDataService = Knit.GetService('PlayerDataService')

    PlayerDataService:RegisterDataIndex('Avatar', {})
end

function AvatarService:ApplyCustomization(Player: Player)
    
end

return AvatarService

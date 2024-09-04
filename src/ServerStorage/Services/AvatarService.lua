local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)

local Avatar = require(ReplicatedStorage.GameModules.Avatar)

local AvatarService = Knit.CreateService {
    Name = "AvatarService",
    Client = {},
}

local PlayerDataService

local function IsJSONAble(value)
    return pcall(HttpService.JSONEncode, HttpService, value)
end

function AvatarService:KnitInit()
    PlayerDataService = Knit.GetService('PlayerDataService')

    PlayerDataService:RegisterDataIndex('Avatar', {
        Customized = false,
        Data = table.clone(Avatar.Default)
    })
end

function AvatarService.Client:SaveAvatar(Player, DataEdit)
    local PlayerData = PlayerDataService:GetPlayerData(Player)
    assert(PlayerData.Avatar.Customized == false, "You have already customized your avatar")

    for category, value in DataEdit do
        local Module = Avatar.Category[category]
        if Module then
            if Module.IsValid and not Module.IsValid(value) and not IsJSONAble(value) then
                error(`Category {category} cannot be saved because it's invalid`)
            end
        elseif not IsJSONAble(value) then
            error('Data cannot be saved')
        end
    end

    PlayerData.Replica:SetValues({'Avatar'}, {
        Customized = true,
        Data = DataEdit
    })
end

return AvatarService

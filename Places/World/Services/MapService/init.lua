local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)

local MapService = Knit.CreateService {
    Name = "MapService",
    Client = {},
}

local PlayerDataService, CharacterService


local function getAvailableId(t)
    local id = 0
    while t[tostring(id)] do
        id += 1
    end
    return tostring(id)
end

function MapService:KnitStart()
    
end


function MapService:KnitInit()
    PlayerDataService = Knit.GetService"PlayerDataService"
    CharacterService = Knit.GetService"CharacterService"

    self.Waypoints = require(script.Waypoints)

    PlayerDataService:RegisterDataIndex("Map", {
        Markers = {},
        LastPosition = {0,0},
    })

    PlayerDataService.PlayerAdded:Connect(function(player: Player, playerData)
        self.Waypoints.PlayerAdded(player, playerData)
    end)

    -- CharacterService.CharacterLoaded:Connect(function(character: Model)
    --     character.PrimaryPart:AddTag('MapMarker')
    -- end)

    local KeybindService = Knit.GetService("KeybindService")
    KeybindService:SetDefaultKeybind('Map', Enum.KeyCode.M)

end

function MapService.Client:AddMarker(player:Player, worldPosition:Vector3, Name:string)
    local Replica = PlayerDataService:GetPlayerData(player).Replica

    if not typeof(worldPosition) == "Vector3" then
        error('Position must be Vector3', 2)
    end
    if not typeof(Name) == "string" then
        error('Name must be a string', 2)
    end
    if #Name >= 32 then
        error('Characters in Name must not exceed 32 characters')
    end

    Replica:SetValue({'Map','Markers',getAvailableId(Replica.Data.Map.Markers)}, {
        {worldPosition.X,worldPosition.Y,worldPosition.Z},
        Name
    })
end


return MapService

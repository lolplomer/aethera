
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)

local EffectService = Knit.CreateService {
    Name = "EffectService",
    Client = {},
}

local packet = require(ReplicatedStorage.Packets.Effect)

local function sendPacket(data, excludedPlayer)
    local position = data.Position
    if data.Parent then
        position = data.Parent.Position
    end
    
    for _, _player: Player in Players:GetPlayers() do
        local char = _player.Character
        if excludedPlayer ~= _player and char and (position - char:GetPivot().Position).Magnitude < 200 then
            packet.Spawn.sendTo(data, _player)
        end    
    end

    
end

function EffectService:SpawnEffect(name, props)
    props.Effect = name

    if props.CFrame then
        props.Position = props.CFrame.Position
        props.Orientation = {props.CFrame:ToOrientation()}
    end

    sendPacket(props)
end

function EffectService:KnitInit()
    
    packet.Spawn.listen(function(data, player)
        sendPacket(data, player)
    end)

end


return EffectService

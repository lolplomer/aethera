local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)
local packet = require(ReplicatedStorage.Packets.Effect)


local Effect = require(ReplicatedStorage.GameModules.Effect)
local Util = require(ReplicatedStorage.Utilities.Util)

local EffectClient = Knit.CreateController { Name = "EffectClient" }


function EffectClient:SpawnEffect(name, props)
    props = props or {}
    props.Effect = name

    Effect.SpawnEffect(name, props)

    if props.CFrame then
        local serverProps = table.clone(props)
        serverProps.CFrame = nil    

        serverProps.Position = props.CFrame.Position
        serverProps.Orientation = {props.CFrame:ToOrientation()}

        packet.Spawn.send(serverProps)
        return
    end
    

    packet.Spawn.send(props)
end

function EffectClient:KnitInit()
    packet.Spawn.listen(function(data)

        if data.Position and data.Orientation then
            local angle = data.Orientation
            data.CFrame = CFrame.new(data.Position) * CFrame.Angles(angle[1],angle[2],angle[3])
        end


        Effect.SpawnEffect(data.Effect, data)
    end)

    Util.command('effect', function(player: Player, args: {string})
        print(args, args[1])
        EffectClient:SpawnEffect(args[1], {
            CFrame = player.Character:GetPivot() * CFrame.Angles(0,0,math.rad(45)),-- * CFrame.new(0,0,-(tonumber(args[2] or 5)))
            Flipped = false,
                
        })
    end)
end


return EffectClient

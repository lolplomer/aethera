local Trove = require(game.ReplicatedStorage.Packages.Trove)
local RunService = game:GetService"RunService"

local Passive = {}

Passive.Hidden = false
Passive.Icon = "rbxassetid://18439438906"

local REGEN_INTENSITY = 0.01
local COOLDOWN_TIME = 1

function Passive.Description(PassiveLevel)
    return `Regenerates {math.floor((REGEN_INTENSITY * PassiveLevel)*100 * 100)/100}% HP every {COOLDOWN_TIME} seconds`
end

function Passive.Name()
    return `HP Regeneration`
end

function Passive.Activate(player, level, attribute, data)
    local Stats = attribute.Stats

    local LastRegen = data.LastRegen or os.clock()
    data.LastRegen = LastRegen

    local RegenTrove = Trove.new()

    RegenTrove:Connect(RunService.Heartbeat, function()
        if os.clock() - LastRegen > COOLDOWN_TIME then
            LastRegen = os.clock()
            data.LastRegen = LastRegen

            local MaxHP = Stats.FullStats.HP
            local HPRecover = MaxHP * (level * REGEN_INTENSITY)

            if player.Character then
                player.Character.Humanoid.Health += HPRecover
            end
        end
    end)

    return RegenTrove:WrapClean()
end

return Passive
local Trove = require(game.ReplicatedStorage.Packages.Trove)
local RunService = game:GetService"RunService"

local Passive = {}

Passive.Hidden = false
Passive.Icon = "rbxassetid://18427812946"

local REGEN_INTENSITY = 0.01
local COOLDOWN_TIME = 1

function Passive.Description(PassiveLevel)
    return `Regenerates {math.floor((REGEN_INTENSITY * PassiveLevel)*100)}% MP every {COOLDOWN_TIME} seconds`
end

function Passive.Name()
    return `MP Regeneration`
end


function Passive.Activate(player, level, attribute, data)
    local Stats = attribute.Stats
    local States = attribute.State

    local LastRegen = data.LastRegen or os.clock()
    data.LastRegen = LastRegen

    local RegenTrove = Trove.new()

    RegenTrove:Connect(RunService.Heartbeat, function()
        if os.clock() - LastRegen > COOLDOWN_TIME then
            LastRegen = os.clock()
            data.LastRegen = LastRegen

            local MaxMP = Stats.FullStats.MP
            local MPRecover = MaxMP * (level * 0.05)

            States:Set('MP', MPRecover + States.MP)
        end
    end)
    RegenTrove:Add(function()
        print('removing mp regen')
    end)

    return RegenTrove:WrapClean()
end

return Passive
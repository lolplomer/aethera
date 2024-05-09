local Trove = require(game.ReplicatedStorage.Packages.Trove)
local RunService = game:GetService"RunService"

local Passive = {}

Passive.Hidden = true
Passive.Icon = ""

local REGEN_INTENSITY = 0.05
local COOLDOWN_TIME = 1

function Passive.Description(_, _, PassiveLevel)
    return `Regenerates {(REGEN_INTENSITY * PassiveLevel)*100}% MP every {COOLDOWN_TIME} seconds`
end

function Passive.Activate(_, Stats, States, PassiveLevel)
    local LastRegen = 0

    local RegenTrove = Trove.new()
    RegenTrove:Connect(RunService.Heartbeat, function()
        if os.clock() - LastRegen > COOLDOWN_TIME then
            LastRegen = os.clock()

            local MaxMP = Stats.FullStats.MP
            local MPRecover = MaxMP * (PassiveLevel * 0.05)

            States:Set('MP', MPRecover + States.MP)
        end
    end)

    return RegenTrove
end

function Passive.Deactivate(_, ActivePassive)
    ActivePassive:Destroy()
end

return Passive
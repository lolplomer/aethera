local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Trove = require(game.ReplicatedStorage.Packages.Trove)
local Formula = require(ReplicatedStorage.Utilities.Misc.StatFormula)
local Stat = require(ReplicatedStorage.GameModules.Stats)
local Util = require(ReplicatedStorage.Utilities.Util)

local highlight = Util.Highlight
local percent = Formula.Percentage
local name = Stat.Name

local Passive = {
    Hidden = false,
    Icon = ""
}

local INTENSITY = 0.1
local STACK = 3
local COOLDOWN = 10
local DURATION = 15

function Passive.Description(level)
    return `Hitting an enemy raises {name('CRITRATE')} by {highlight(percent(level * INTENSITY))} for {highlight(DURATION)} seconds. This can stack up to {highlight(STACK)} times. There is a {highlight(COOLDOWN)} second cooldown after the last stack.`
end

function Passive.Name()
    return `Critical Edge`
end

function Passive.Activate(player: Player, level: number, attribute: {}, data)
    
    data.Times = data.Times or 0
    data.LastStack = data.LastStack or 0

    local _Trove = Trove.new()

    _Trove:Connect(attribute.Combat.DamageDealt, function()

        if os.clock() - data.LastStack > 10 then
            
            data.Times += 1
            local stack = data.Times % STACK

            if stack == 0 then
                data.LastStack = os.clock()
                data.Times = 0
            end

            attribute.Stats:SetModifier(`Critical Edge Stack {stack + 1}`, {
                CRITRATE = {Flat = INTENSITY * level},
            }, DURATION)

        end
    end)

    return _Trove:WrapClean()

end

return Passive
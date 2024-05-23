
local Formula = {}

local EXP_CONSTANT = 0.5
local EXP_POWER = 3
local FLOAT_POINT_FIX = 2.2e-5

local function root(x, n)
    return x ^ (1/n)
end

function Formula.GetLevel(Exp)
    return EXP_CONSTANT * root(Exp+FLOAT_POINT_FIX, EXP_POWER)
end

function Formula.GetExp(Level)
    return (Level/EXP_CONSTANT)^EXP_POWER
end

function Formula.GetBaseStat(Level, BaseValue, Multiplier)
    return BaseValue + (BaseValue * (math.max(Level, 1) - 1) * Multiplier)
  -- return BaseValue + (Level - 1) * Multiplier
end

function Formula.ApplyModifier(Stat, Multiplier, Flat)
    return math.max(Stat + Formula.GetModifierValue(Stat, Multiplier, Flat),0)
end

function Formula.GetModifierValue(Stat, Multiplier, Flat)
    return Stat * Multiplier + Flat
end

function Formula.Percentage(value)
    return math.floor((value * 100) * 100)/100 .. "%"
end

function Formula.GetLabel(value, IsPercentage)
    if IsPercentage then
        return Formula.Percentage(value)
    else
        return math.floor(value)
    end
end

function Formula.GetExpMinMax(Exp, Level)
    Level = math.floor(Level)

    local Now = Formula.GetExp(Level)
    local Current = Exp - Now
    local Next = Formula.GetExp(Level + 1) - Now
    
    return math.round(Current), math.round(Next)
end

return Formula
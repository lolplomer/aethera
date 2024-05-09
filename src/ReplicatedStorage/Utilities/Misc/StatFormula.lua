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
    return (Stat + Stat * Multiplier) + Flat
end

function Formula.Percentage(value)
    return (value * 100) .. "%"
end

return Formula
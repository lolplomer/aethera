local Random = Random.new()


local Formula = {}

local EXP_CONSTANT = 0.5
local EXP_POWER = 3
local FLOAT_POINT_FIX = 2.2e-5
local REWARD_EXP_POWER = 1.16

local function root(x, n)
    return x ^ (1/n)
end

function Formula.GetLevel(Exp)
    return EXP_CONSTANT * root(Exp+FLOAT_POINT_FIX, EXP_POWER)
end

function Formula.GetExp(Level)
    return (Level/EXP_CONSTANT)^EXP_POWER
end

function Formula.GetRewardEXP(mobLevel, baseEXP)
	return baseEXP * (mobLevel ^ REWARD_EXP_POWER)
end

function Formula.GetBaseStat(Level, BaseValue, Multiplier)
    return BaseValue + (BaseValue * (math.max(Level, 1) - 1) * Multiplier)
  -- return BaseValue + (Level - 1) * Multiplier
end

function Formula.ApplyModifier(BaseStat, Multiplier, Flat)
    return math.max(BaseStat + Formula.GetModifierValue(BaseStat, Multiplier, Flat),0)
end

function Formula.GetBaseDamage(ATK, DEF)
    return (ATK ^ 2) / (ATK + DEF)
end

function Formula.RandomizeDamage(DMG, Factor)
    return DMG * (1 + Random:NextNumber(-Factor, Factor))
end

function Formula.RollCriticalChance(baseDamage, critRate, critDamageMultiplier)
    local roll = math.random()

    -- Check if the roll is within the critical rate
    if roll < critRate then
        -- Critical hit
        local critDamage = baseDamage * (1 + math.min(critRate, 1) * critDamageMultiplier)
        return true, critDamage
    else
        -- Normal hit
        return false, baseDamage
    end
end

function Formula.GetModifierValue(Stat, Multiplier, Flat)
    return Stat * Multiplier + Flat
end

function Formula.Percentage(value, richText)
    local str = math.floor((value * 100) * 100)/100 .. "%"
    if richText then
        local color = Color3.new(1,1,1):ToHex()
        return `<font color="#{color:upper()}">{str}</font>`
    end
    return str
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
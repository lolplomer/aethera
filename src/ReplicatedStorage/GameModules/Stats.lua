local StatClass = {}
StatClass.__index = StatClass

function StatClass:Default(value)
    self.DefaultValue = value
    return self
end

function StatClass:LevelMult(value)
    self.LevelMultiplier = value or 1
    return self
end

local layoutOrder = 0
local function New(IsPercentage: boolean, Label: string, Visible: boolean)
    if Visible == nil then
        Visible = true
    end
    layoutOrder += 1
    return setmetatable({
        IsPercentage = IsPercentage,
        LayoutOrder = layoutOrder,
        Label = Label,
        Visible = Visible,
        DefaultValue = 1,
        LevelMultiplier = 0,
    }, StatClass)
end

local Stats = {
    ATK = New(false):Default(10):LevelMult(0.5),
    DEF = New(false):Default(10):LevelMult(0.5),
    HP = New(false):Default(100):LevelMult(2),
    MP = New(false):Default(100):LevelMult(2),
    CRITDMG = New(true, "CRIT DMG"),
    CRITRATE = New(true, "CRIT RATE"):Default(.05),
    ATKSPD = New(true, "ATK SPD"),
    MOVSPD = New(true, "Movement SPD"),
    TIMESPD = New(true, "Time SPD", false),
}

local function Init()
    for statName, metadata in Stats do
        metadata.Key = statName
        metadata.Label = metadata.Label or statName
    end
end

Init()

local Misc = game.ReplicatedStorage.Utilities.Misc

local ModuleClass = {}
ModuleClass.Formula = require(Misc:WaitForChild"StatFormula")


ModuleClass.__index = ModuleClass

return setmetatable(Stats, ModuleClass)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage:WaitForChild('Packages'):WaitForChild('Knit'))
local PlayerDataService = Knit.GetService("PlayerDataService")

local Misc = game.ReplicatedStorage.Utilities.Misc
local Formula = require(Misc.StatFormula)

local StatModule = require(ReplicatedStorage.GameModules.Stats)

local ReplicaService = require(game.ServerScriptService.ReplicaService)

local ReplicaToken = ReplicaService.NewClassToken("PlayerStats")
local MobReplicaToken = ReplicaService.NewClassToken("MobStats")

local Signal = require(ReplicatedStorage.Packages.Signal)

local WriteLib = ReplicatedStorage.Utilities.WriteLibs.Stats

local function BuildEmptySummationModifiers()
    local EmptySummationModifiers = {}
    for stat, _ in StatModule do
        EmptySummationModifiers[stat] = {Multiplier = 0, Flat = 0}
    end
    return EmptySummationModifiers
end

local function CreateSignalForEveryStat()
    local signals = {}
    for stat, _ in StatModule do
        signals[stat] = Signal.new()
    end
    return signals
end



local ReplicaClass = require(Misc.ReplicaClass)

local StatsModifier = {}
StatsModifier.__index = function(self, index)
    return StatsModifier[index] or ReplicaClass.__index(self, index)
end

function StatsModifier.newForMob(Data: {RawStats: {[string] : number},Level:number} )
    local self = setmetatable({
        Data = {
            Modifiers = {},
            BaseModifiers = {},
            FullStats = {},
            Level = Data.Level,
            RawStats = Data.RawStats,
            Exp = Formula.GetExp(Data.Level)
        },
        ExpChanged = Signal.new(),
        Changed = CreateSignalForEveryStat()
        
    }, StatsModifier)

    local FullStats, BaseStats, Level = self:CalculateFullStats()
    self.Data.FullStats = FullStats
    self.Data.BaseStats = BaseStats
    self.Data.Level = Level

    
    self.Replica = ReplicaService.NewReplica({
        ClassToken = MobReplicaToken,
        Data = self.Data,
        WriteLib = WriteLib,
    })

    
    self.Replica:AddCleanupTask(function()
        self.ExpChanged:Destroy()
        for _, signal in self.Changed do
            signal:Destroy()
        end
    end)

    self.ExpChanged:Connect(function(_, NewLevel)
        print(NewLevel, math.floor(NewLevel), self.Data.Level)
        if math.floor(NewLevel) ~= self.Data.Level then
            self:CalculateFullStats()
        end
    end)

    return self

end

function StatsModifier.new(player)
    local PlayerData = PlayerDataService:GetPlayerData(player)

    local self = setmetatable({
        Player = player,
        PlayerData = PlayerData,
        Data = {
            Modifiers = {},
            BaseModifiers = {},
            FullStats = {}
        },
        ExpChanged = Signal.new(),
        Changed = CreateSignalForEveryStat(),
    }, StatsModifier)


    local FullStats, BaseStats, Level = self:CalculateFullStats()
    self.Data.FullStats = FullStats
    self.Data.BaseStats = BaseStats
    self.Data.Level = Level

    self.Replica = ReplicaService.NewReplica({
        ClassToken = ReplicaToken,
        Tags = {
            Player = player
        },
        Data = self.Data,
        WriteLib = WriteLib,
        Parent = PlayerData.Replica,
    })

    self.Replica:AddCleanupTask(function()
        self.ExpChanged:Destroy()
        for _, signal in self.Changed do
            signal:Destroy()
        end
    end)

    self.ExpChanged:Connect(function(_, NewLevel)
        print(NewLevel, math.floor(NewLevel), self.Data.Level)
        if math.floor(NewLevel) ~= self.Data.Level then
            self:CalculateFullStats()
        end
    end)

    return self
end

function StatsModifier:GetModifiersSummation()
    local Key = `ModifiersSummation`
    if not self[Key] then
        self:SumModifiers()
    end
    return self[Key]
end

function StatsModifier:SumModifiers()
    local summations = BuildEmptySummationModifiers()
    for _, modifier in self.Data.Modifiers do
        for stat, parameters in modifier do
            summations[stat].Multiplier += parameters.Multiplier
            summations[stat].Flat += parameters.Flat
        end
    end
    self.ModifiersSummation = summations
    return summations
end

function StatsModifier:SetModifier(id: string, modifier: {[string]: {Multiplier: number, Flat: number}})
    self.Replica:Write("SetModifier", id, modifier)
    self:SumModifiers()
    local _,_,_,ChangedStats = self:CalculateFullStats()


end

function StatsModifier:SetModifiers(modifiers)
    self.Replica:Write("SetModifiers", modifiers)
    self:SumModifiers()
    local _,_,_,ChangedStats = self:CalculateFullStats()
    
    for stat, value in ChangedStats do
        self.Changed[stat]:Fire(value)
    end
end

function StatsModifier:RemoveModifier(id)
    local modifier = self:GetModifier(id)
    if modifier then
        self.Replica:Write("RemoveModifier", id)
        self:SumModifiers() 
        self:CalculateFullStats()

        -- for stat, _ in modifier do
        --     self.Changed[stat]:Fire(self:Get(stat))
        -- end
    end
end 

function StatsModifier:IsPlayer()
    return self.Player ~= nil
end

function StatsModifier:CalculateBaseStats()
    
    local Level, RawStats
    if self:IsPlayer() then
        local PlayerStats = self.PlayerData.Stats
        RawStats = PlayerStats.RawStats
        Level = math.floor(PlayerStats.Level)    
    else
        Level, RawStats = self.Data.Level, self.Data.RawStats
    end
    

    self.Level = Level

    local BaseStats = {}
    for stat, value in RawStats do
        local metadata = StatModule[stat]
        local BaseStat = Formula.GetBaseStat(Level, value, metadata.LevelMultiplier)
        BaseStats[stat] = BaseStat
    end

    return BaseStats, Level
end

function StatsModifier:Get(stat)
    if self.Level ~= (self:IsPlayer() and self.PlayerData.Stats.Level or self.Data.Level) then
        self:CalculateFullStats()
    end
    return self.Data.FullStats[stat]
end

function StatsModifier:GetModifier(id)
    return self.Data.Modifiers[id]
end

function StatsModifier:CalculateFullStats()
    local BaseStats, Level = self:CalculateBaseStats()
    local ModifiersSummation = self:GetModifiersSummation()

    local FullStats = {}
    local ChangedStats = {}
    for stat, value in BaseStats do
        local StatModifier = ModifiersSummation[stat]
        local newValue = Formula.ApplyModifier(value, StatModifier.Multiplier, StatModifier.Flat)

        if newValue ~= self.Data.FullStats[stat] then
           -- print(`{stat} Changed. New: {newValue} Old: {self.Data.FullStats[stat]}`)
            ChangedStats[stat] = newValue
        end

        FullStats[stat] = newValue
    end

    if self.Replica then
        self.Replica:Write('SetStats', Level, BaseStats, FullStats)
    end
    for stat, value in ChangedStats do
        self.Changed[stat]:Fire(value)
    end
    
    return FullStats, BaseStats, Level, ChangedStats
end


function StatsModifier:Destroy()
    self.Replica:Destroy()
end


return StatsModifier

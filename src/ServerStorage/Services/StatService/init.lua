local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)

local GameModules = game.ReplicatedStorage.GameModules
local Stats = require(GameModules.Stats)

local Util = require(ReplicatedStorage.Utilities.Util)

local StatsModifier

local PlayerDataService

local StatService = Knit.CreateService {
    Name = "StatService",
    Client = {},
}

StatService.Formula = Stats.Formula

local MaxLevel = 50

local MaxExp = StatService.Formula.GetExp(MaxLevel)

local PlayerStats = {}

local function BuildDataTemplate()
    local Template = {
        RawStats = {},
        Exp = Stats.Formula.GetExp(1),
        Level = 1,
    }
    for name, metadata in Stats do
        Template.RawStats[name] = metadata.DefaultValue
    end

    return Template
end

local function OnPlayerAdded(player, data)

    local PlayerStatsModifier = StatsModifier.new(player)
    PlayerStats[player] = PlayerStatsModifier

    player.Chatted:Connect(function(msg)
        local arg = msg:split(" ")
        if arg[1] == "addexp" then
            local value = tonumber(arg[2]) or 0
            local exp, level = StatService:AddExp(player, value)

            local nextLevel = math.floor(level + 1)
            local nextExpLevel = Stats.Formula.GetExp(nextLevel)-exp

            print(`Added {value} of exp to {player} stat`)
            print(`{player} | New exp={exp} level={level} exp left to level up={nextExpLevel}`)
            print(`nextLevel: {nextLevel} {level} {nextExpLevel}`)
        elseif arg[1] == 'exp' then
            local exp, level = StatService:GetExpAndLevel(player)
            print(`{player} | exp={exp} level={level}`)
        elseif arg[1] == "modifier" then
            print(PlayerStatsModifier.Data)
        elseif arg[1] == "setmodifier" then
            
            local id = arg[2]
            local stat = arg[3]
            local mult = math.clamp(tonumber(arg[4]) or 0, 0, 100)
            local flat = math.clamp(tonumber(arg[5]) or 0 ,0, 100000000)

            if Stats[stat] then
                
                PlayerStatsModifier:SetModifier(id, {
                    [stat] = {
                        Multiplier = mult,
                        Flat = flat
                    }
                })

                
                print(`Added modifier named {id} | Stat:{stat} Mult:{mult*100}% Flat:{flat}`)
                local newStat = PlayerStatsModifier:Get(stat)
                print(`New {stat} value : {newStat}`)
            end


        elseif arg[1] == "removemodifier" then
            local id = arg[2]
            PlayerStatsModifier:RemoveModifier(id)
        elseif arg[1] == 'getstat' then
            local stat = arg[2]
            print(`{stat} value : {PlayerStatsModifier:Get(stat)}`)
        elseif arg[1] == 'readstats' then
            print(PlayerStatsModifier)
        end
    end)

    Util.CharacterAdded(player, function(char: Model)
        local _, level = StatService:GetExpAndLevel(player)
        char:SetAttribute('Level', math.floor(level))
    end, false)
end


function StatService:GetStats(player)
   return Util.GetAsync(PlayerStats, player, "Stats")
end

function StatService:GetExpAndLevel(player)
    local StatsData = PlayerDataService:GetPlayerData(player).Stats
    return StatsData.Exp, StatsData.Level
end

function StatService:CreateMobStats(RawStats, Level, Model)
    for stat, metadata in Stats do
        if not RawStats[stat] then
            RawStats[stat] = metadata.DefaultValue
        end
    end
    return StatsModifier.newForMob ({
        RawStats = RawStats,
        Level = Level
    }, Model)
end

function StatService:AddExp(player:Player, value)
    local PlayerData = PlayerDataService:GetPlayerData(player)

    local NewExp = math.clamp(PlayerData.Stats.Exp + value, 1, MaxExp)
    local NewLevel = self.Formula.GetLevel(NewExp)

    PlayerData.Replica:SetValues({"Stats"}, {
        Exp = NewExp,
        Level = NewLevel
    })

    local Modifier = self:GetStats(player)
    Modifier.ExpChanged:Fire(NewExp, NewLevel)

    player.Character:SetAttribute('Level', math.floor(NewLevel))

    return NewExp, NewLevel
end

function StatService:KnitInit()
    StatsModifier = require(script.StatsModifier)
    PlayerDataService = Knit.GetService "PlayerDataService"
    PlayerDataService:RegisterDataIndex("Stats", BuildDataTemplate())
    PlayerDataService.PlayerAdded:Connect(OnPlayerAdded)
end


return StatService

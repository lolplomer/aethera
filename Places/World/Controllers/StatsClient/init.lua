local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)
local Signal = require(ReplicatedStorage.Packages.Signal)

local Wrapper = require(script.Wrapper)

local StatsClient = Knit.CreateController { Name = "StatsClient" }
StatsClient.LevelChanged = Signal.new()

local Replica

local Changed = {}
local Wrappers = {}

local function stat()
    if Replica then
        return Replica
    end
    Replica = Knit.GetController('PlayerReplicaController'):GetReplica("PlayerStats")
    return Replica
end

function StatsClient.GetWrapper(_stats)
    if stat() == _stats then return StatsClient end

    if not Wrappers[_stats] then
        Wrappers[_stats] = Wrapper.new(_stats)

        Wrappers[_stats]._trove:Add(function()
            Wrappers[_stats] = nil
        end)
    end

    return Wrappers[_stats]
end

function StatsClient:Get(Stat)
    return stat().FullStats[Stat]
end

function StatsClient:GetStatChanged(Stat)
    if not Changed[Stat] then
        Changed[Stat] = Signal.new()
    end
    return Changed[Stat]
end

function StatsClient:KnitStart()
    local clientStats = stat()
    for name in clientStats.FullStats do
        clientStats.Replica:ListenToChange({'FullStats',name}, function(value, old)
            --print(name, 'changed', value)
            self:GetStatChanged(name):Fire(value, old)
        end)
    end
    clientStats.Replica:ListenToChange('Level', function(value, old)
        StatsClient.LevelChanged:Fire(value, old)
    end)
end



return StatsClient

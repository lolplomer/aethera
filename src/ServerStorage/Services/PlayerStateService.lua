local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicaService = require(game.ServerScriptService.ReplicaService)

local StateClassToken = ReplicaService.NewClassToken("PlayerState")

local Knit = require(ReplicatedStorage.Packages.Knit)
local TableUtil = require(ReplicatedStorage.Packages.TableUtil)

local PlayerDataService, StatService

local PlayerStateService = Knit.CreateService {
    Name = "PlayerStateService",
    Client = {},
}

local StateModule = require(game.ReplicatedStorage.GameModules.States)
local misc = game.ReplicatedStorage:WaitForChild('Utilities'):WaitForChild('Misc')
local util = require(ReplicatedStorage.Utilities.Util)
local ReplicaClass = require(misc.ReplicaClass)

local DefaultState = StateModule.States
local States = {}

local StateClass = {}
StateClass.__index = function(self, index)
    return StateClass[index] or ReplicaClass.__index(self, index)
end

function StateClass:Set(index, value)
    if StateModule.__set[index] then
        local Stats = StatService:GetStats(self.Player)
        value = StateModule.__set[index](value, self.Player, Stats, self)
    end
    self.Replica:SetValue({index}, value)
end

local function OnPlayerAdded(player: Player, data)
    local StateReplica = ReplicaService.NewReplica{
        ClassToken = StateClassToken,
        Tags = {Player = player},
        Data = table.clone(DefaultState),
        Parent = data.Replica,
    }

    StateReplica:AddCleanupTask(function()
        States[player] = nil
    end)

    States[player] = setmetatable({     
        Replica = StateReplica,
        Player = player,
    }, StateClass)
 

    player.Chatted:Connect(function(message)
        local args = message:split(" ") 
        
        if args[1] == "setstate" then
            local PlayerState = PlayerStateService:GetPlayerState(player)

            local state = args[2]
            local value = tonumber(args[3]) or args[3]

            PlayerState:Set(state, value)
        end
    end)
end

local function OnPlayerRemoving(player)
    local StateReplica = States[player]
    if StateReplica then
        StateReplica:Destroy()
    end
end

function PlayerStateService:GetPlayerState(player)
    return util.GetAsync(States, player, "States")
end

function PlayerStateService:SetDefaultState(state)
    DefaultState = TableUtil.Reconcile(DefaultState, state)
end

function PlayerStateService:KnitInit()
    PlayerDataService = Knit.GetService("PlayerDataService")
    StatService = Knit.GetService("StatService")

    game.Players.PlayerRemoving:Connect(OnPlayerRemoving)
    PlayerDataService.PlayerAdded:Connect(OnPlayerAdded)
end


return PlayerStateService

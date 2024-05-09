local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)

local PassiveService = Knit.CreateService {
    Name = "PassiveService",
    Client = {},
}

local PlayerDataService, StatService, PlayerStateService

local misc = game.ReplicatedStorage:WaitForChild('Utilities'):WaitForChild('Misc')
local ReplicaService = require(game.ServerScriptService.ReplicaService)
local PassiveReplicaToken = ReplicaService.NewClassToken("Passive")
local WriteLib = ReplicatedStorage.Utilities.WriteLibs.Passive

local Util = require(game.ReplicatedStorage.Utilities.Util)

local PassiveModule = require(ReplicatedStorage.GameModules.Passives)

local ReplicaClass = require(misc.ReplicaClass)

local Passives = {}

local PassiveClass = {} do
    PassiveClass.__index = function(self, index)
        return PassiveClass[index] or ReplicaClass.__index(self, index)
    end
    function PassiveClass.new(Replica)
        return setmetatable({
            Replica = Replica,
            ActivePassives = {},
            Player = Replica.Tags.Player
        }, PassiveClass)
    end
    function PassiveClass:Activate(passiveName, level)
        local player = self.Player
    
        level = level or 1
        local Passive = PassiveModule.Passives[passiveName]
    
        if not Passive then
            return
        end
    
        local playerState = PlayerStateService:GetPlayerState(player)
        local playerStats = StatService:GetStats(player)
        
        local activePassive = self.ActivePassives[passiveName] 
        if activePassive then
            Passive.Deactivate(player, activePassive)
        end
    
        activePassive = Passive.Activate(player, playerStats, playerState, level)
        self.ActivePassives[passiveName] = activePassive
    
        self.Replica:Write("SetPassive", passiveName, level)
    end
    function PassiveClass:Deactivate(passiveName)
        local activePassive = self.ActivePassives[passiveName] 
        if activePassive then
            local Passive = PassiveModule.Passives[passiveName]
            Passive.Deactivate(self.Player, activePassive)
        end
    
        self.ActivePassives[passiveName] = nil
        self.Replica:Write("RemovePassive", passiveName)
    end
end


local function ActivateDefaultPassives(Player: Player)
    for PassiveName, Info in PassiveModule.DefaultPassives do
        local PlayerPassive = PassiveService:GetPlayerPassives(Player)
        PlayerPassive:Activate(PassiveName, Info.Level)
    end
end

local function OnPlayerAdded(player: Player, data)
    local PassiveReplica = ReplicaService.NewReplica({
        ClassToken = PassiveReplicaToken,
        Tags = {Player = player},
        Data = {
            Passives = {}
        },
        Parent = data.Replica,
        WriteLib = WriteLib,
    })
    local PassiveController = PassiveClass.new(PassiveReplica)

    PassiveReplica:AddCleanupTask(function()
        for Name, _ in PassiveController.ActivePassives do
            PassiveController:Deactivate(Name)
        end
    end)

    PassiveReplica:AddCleanupTask(function()
        Passives[player] = nil
    end)

    player.Chatted:Connect(function(message)
        local args = message:split(" ")
        local passive = args[2]
        if args[1] == 'activatepassive' then
            local level = tonumber(args[3]) or 1
            PassiveController:Activate(passive, level)
        elseif args[1] == 'deactivatepassive' then
            PassiveController:Deactivate(passive)
        end
    end)

    Passives[player] = PassiveController
    ActivateDefaultPassives(player)
end

function PassiveService:GetPlayerPassives(player)
    return Util.GetAsync(Passives, player, "Passives")
end

function PassiveService:KnitInit()
    PlayerDataService = Knit.GetService('PlayerDataService')
    StatService =  Knit.GetService("StatService")
    PlayerStateService =  Knit.GetService("PlayerStateService")

    PlayerDataService.PlayerAdded:Connect(OnPlayerAdded)
end


return PassiveService

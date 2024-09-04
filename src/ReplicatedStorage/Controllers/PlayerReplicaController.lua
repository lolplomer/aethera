
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Promise = require(ReplicatedStorage.Utilities.Promise)

local Knit = require(ReplicatedStorage.Packages.Knit)

local PlayerReplicaController = Knit.CreateController { Name = "PlayerReplicaController" }
local ReplicaController = require(game.ReplicatedStorage:WaitForChild"Madwork":WaitForChild"ReplicaController")
local Player = game.Players.LocalPlayer

local util = require(game.ReplicatedStorage:WaitForChild('Utilities'):WaitForChild"Util")

local Replicas = {}
 
local replicaClass = {}
replicaClass.__index = function(self, index)
    return rawget(self,index) or self.Replica.Data[index]
end

PlayerReplicaController.ReplicaClass = replicaClass

function PlayerReplicaController:GetReplica(class, player, timeout)
    player = player or Player
    local dir = util.GetAsync(Replicas, class, "Client Replica")
   return util.GetAsync(dir, player, 'Player Replica', timeout)
end

function PlayerReplicaController:GetReplicaAsPromise(class,player,timeout)
    return Promise.new(function(resolve)
        resolve(self:GetReplica(class, player, timeout))
    end)
end

ReplicaController.NewReplicaSignal:Connect(function(replica)
    --print('new replica:',replica.Class, replica.Tags.Player)

    if not Replicas[replica.Class] then
        Replicas[replica.Class] = {}
    end

    if replica.Tags.Player then
        Replicas[replica.Class][replica.Tags.Player] =  setmetatable({
            Replica = replica
        }, replicaClass)
    end
end)

return PlayerReplicaController

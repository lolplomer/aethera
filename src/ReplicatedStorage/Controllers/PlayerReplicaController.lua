local ReplicatedStorage = game:GetService("ReplicatedStorage")


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

function PlayerReplicaController:KnitInit()
    ReplicaController.NewReplicaSignal:Connect(function(replica)
        if replica.Tags.Player == Player then
            Replicas[replica.Class] = setmetatable({
                Replica = replica
            }, replicaClass)
        end
    end)
end

function PlayerReplicaController:GetReplica(class)
   return util.GetAsync(Replicas, class, "Client Replica")
end

return PlayerReplicaController

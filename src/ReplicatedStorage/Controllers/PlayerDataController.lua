
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicaController = require(ReplicatedStorage:WaitForChild("Madwork"):WaitForChild"ReplicaController")

local Knit = require(ReplicatedStorage.Packages.Knit)

local PlayerDataClass = require(game.ReplicatedStorage:WaitForChild"Utilities":WaitForChild"Misc":WaitForChild"PlayerDataClass")
local PlayerDataController = Knit.CreateController { Name = "PlayerDataController" }
local PlayerDataReplica

local player = game.Players.LocalPlayer

function PlayerDataController:GetPlayerData()
    if not PlayerDataReplica then
        --warn(`PlayerData has yet to be acquired and will yield the thread`)
        while not PlayerDataReplica do
            task.wait()
        end
    end
    return PlayerDataReplica
end

function PlayerDataController:KnitInit()
    print("Waiting for a replica of player's data... ")
    ReplicaController.ReplicaOfClassCreated("PlayerData", function(replica)
        if replica.Tags.Player == player then
            PlayerDataReplica = setmetatable({
                Replica = replica
            }, PlayerDataClass)
            print(`Acquired a replica of {player}'s PlayerData:`,replica)
        end
    end)
end


return PlayerDataController

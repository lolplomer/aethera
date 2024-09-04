
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicaController = require(ReplicatedStorage:WaitForChild("Madwork"):WaitForChild"ReplicaController")

local Knit = require(ReplicatedStorage.Packages.Knit)

local PlayerDataClass = require(game.ReplicatedStorage:WaitForChild"Utilities":WaitForChild"Misc":WaitForChild"PlayerDataClass")
local PlayerDataController = Knit.CreateController { Name = "PlayerDataController" }
local PlayerDataReplica

local player = game.Players.LocalPlayer
local Promise = require(ReplicatedStorage.Utilities.Promise)



function PlayerDataController:GetPlayerData()
    if not PlayerDataReplica then
        --warn(`PlayerData has yet to be acquired and will yield the thread`)
        print('source:',debug.traceback())
        while not PlayerDataReplica do
            task.wait()
        end
    end
    return PlayerDataReplica
end

local Get = Promise.promisify(function()
    return PlayerDataController:GetPlayerData()
end)

function PlayerDataController:GetDataAsync()
    return Get()
end

function PlayerDataController:KnitInit()
    print("Waiting for a replica of player's data... ")
    ReplicaController.ReplicaOfClassCreated("PlayerData", function(replica)
        if replica.Tags.Player == player then
            PlayerDataReplica = setmetatable({
                Replica = replica
            }, PlayerDataClass)
            PlayerDataController.PlayerData = PlayerDataReplica
            warn(`[PlayerDataController] Acquired a replica of {player}'s PlayerData:`,replica)

            local LoadingService = Knit.GetService('LoadingService')
            LoadingService.LoadingDone:Fire()
        end
    end)
end


return PlayerDataController

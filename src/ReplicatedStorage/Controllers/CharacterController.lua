local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)

local GameModules = ReplicatedStorage:WaitForChild"GameModules"
local CombatFolder = GameModules:WaitForChild("Combat")
local CharacterModule = require(CombatFolder:WaitForChild"Character")

local Util = require(ReplicatedStorage.Utilities.Util)
local Player = game.Players.LocalPlayer

local CharacterController = Knit.CreateController { Name = "CharacterController" }


function CharacterController:KnitStart()
    Util.CharacterAdded(Player, function(Character: Model)
        CharacterModule:Initialize(Character)
    end)
end


function CharacterController:KnitInit()
    
end


return CharacterController

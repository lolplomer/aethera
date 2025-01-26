local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Signal = require(ReplicatedStorage.Packages.Signal)

local LoadingController = Knit.CreateController { Name = "LoadingController" }

LoadingController.Enabled = true

LoadingController.Changed = Signal.new()

local Character, GUI

function LoadingController:SetEnabled(enabled)


    if enabled then
        Character:DisableStates()
        GUI:DisableAllExcept({"LoadingScreen"})
    else
        Character:EnableStates()
        GUI:EnableAll()
    end

    self.Enabled = enabled
    self.Changed:Fire()
end

function LoadingController:Enable()
    self:SetEnabled(true)
end

function LoadingController:Disable()
    self:SetEnabled(false)
end

function LoadingController:KnitStart()
    Character = Knit.GetController('CharacterController')
    GUI = Knit.GetController('GUI')
    
    GUI:LoadInterface(script.Screen, 'LoadingScreen')

    task.spawn(function()
        Character:AwaitCharacter()
        self:SetEnabled(self.Enabled)
    end)
end

return LoadingController

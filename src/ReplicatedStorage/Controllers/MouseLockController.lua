local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerModule = require(game.Players.LocalPlayer.PlayerScripts.PlayerModule)
local Cameras = PlayerModule:GetCameras()

local Knit = require(ReplicatedStorage.Packages.Knit)

local MouseLockController = Knit.CreateController { Name = "MouseLockController" }

local LastMouseLockState = nil

function MouseLockController:GetIsMouseLocked()
    return Cameras.activeMouseLockController:GetIsMouseLocked()
end

function MouseLockController:DisableMouseLock()
    if LastMouseLockState == nil then    
        LastMouseLockState = self:GetIsMouseLocked()
        
        self:SetIsMouseLocked(false)
    end
end

function MouseLockController:RestoreMouseLock()
    self:SetIsMouseLocked(LastMouseLockState)
    LastMouseLockState = nil
end

function MouseLockController:SetIsMouseLocked(bool: boolean)
    Cameras.activeMouseLockController.isMouseLocked = bool
    Cameras.activeMouseLockController:SetMouseLockCursor()
    if Cameras.activeCameraController then
         Cameras:OnMouseLockToggled(bool)
         return true;
    end
    return false;
    
end

function MouseLockController:KnitStart()
    local InputController = Knit.GetController('InputController')

    InputController:OnKeybindTrigger("MouseLock", function()
        print('Toggling mouse')
        self:SetIsMouseLocked(not self:GetIsMouseLocked())
    end)
end


return MouseLockController

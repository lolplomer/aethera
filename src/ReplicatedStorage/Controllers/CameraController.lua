local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Knit = require(ReplicatedStorage.Packages.Knit)

local CameraController = Knit.CreateController { Name = "CameraController" }

CameraController.MouseLockEnabled = false
local utility = ReplicatedStorage:WaitForChild'Utilities'
local util = require(utility:WaitForChild"Util")

local character

function CameraController:ToggleMouseLock()
    if self.MouseLockEnabled then
        self:DisableMouseLock()
    else
        self:EnableMouseLock()
    end
end

function CameraController:DisableMouseLock()
    self.MouseLockEnabled = false
    RunService:UnbindFromRenderStep('MouseLock')
    UserInputService.MouseBehavior = Enum.MouseBehavior.Default
end

function CameraController:EnableMouseLock()
    if self.MouseLockEnabled then
        self:DisableMouseLock()
    end

    local camera = workspace.CurrentCamera

    local function getSphereSurfacePoint(center, radius, theta, phi)
        -- Calculate the x, y, z coordinates on the sphere's surface
        local x = center.X + radius * math.sin(phi) * math.cos(theta)
        local y = center.Y + radius * math.sin(phi) * math.sin(theta)
        local z = center.Z + radius * math.cos(phi)

        local position = Vector3.new(x, y, z)

        -- Calculate the direction vector (normalized)
        local direction = (position - center).Unit
    
        -- Create the CFrame with position and look direction
        local cframe = CFrame.new(position, position + direction)
    
        return cframe
    end

    local init = character:WaitForChild('HumanoidRootPart').CFrame
    init -= init.Position
    local theta, phi = 0,0

    UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter

    RunService:BindToRenderStep('Mouselock', Enum.RenderPriority.Camera.Value, function(dt)
        print('running')

        camera.CameraType = Enum.CameraType.Scriptable

        local delta = UserInputService:GetMouseDelta()
        theta += delta.X/1000
        phi += delta.Y/1000

        local cf = getSphereSurfacePoint(init.Position, 10, theta, phi)

        camera.CFrame = character.HumanoidRootPart.CFrame * init * cf
    end)
end
 
function CameraController:KnitStart()
   -- self:EnableMouseLock()
   --UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter

end


function CameraController:KnitInit()    
    util.CharacterAdded(game.Players.LocalPlayer, function(c)
        character = c
    end)
    
end


return CameraController

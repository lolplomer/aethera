local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Knit = require(ReplicatedStorage.Packages.Knit)

local MainMenuController = Knit.CreateController { Name = "MainMenuController" }

local rad = math.rad

MainMenuController.Cameras = {
    Default = {CFrame = CFrame.new(0,50,0)}
}

function MainMenuController:GetCameraPart(Name)
    local Camera = self.Cameras[Name]
    if not Camera then
        warn(`[MainMenu] Missing CameraPart "{Name}"`)
        Camera = self.Cameras.Default
    end
    return Camera
end

function MainMenuController:SwitchCamera(Name)


    local CameraPart = self:GetCameraPart(Name)

    self.Camera = CameraPart


    print('Switching to Camera',Name)
end

function MainMenuController:UpdateCamera(immediate)
    local CameraPart = self.Camera
    if not CameraPart then
        CameraPart = self.Cameras.Default
    end
    
    local Camera: Camera = workspace:WaitForChild'Camera'
    Camera.CameraType = Enum.CameraType.Scriptable

    local MouseLoc = UserInputService:GetMouseLocation()
    local Center = Camera.ViewportSize/2

    local Scale = (MouseLoc - Center)/Center

    local MouseMovement = CFrame.Angles(-rad(Scale.Y * 5),-rad(Scale.X * 5),0)
    local Shake = CFrame.Angles(rad(math.sin(os.clock()) * 1), rad(math.cos(os.clock()) * 1), 0)

    local Goal = CameraPart.CFrame * MouseMovement * Shake

    Camera.CFrame = Camera.CFrame:Lerp(Goal, immediate and 1 or 0.05)
    Camera.FieldOfView = 55
end

function MainMenuController:StartCamera()
    self:UpdateCamera(true)
    RunService:BindToRenderStep('CameraMenu', 1, function()
        self:UpdateCamera()
    end)
end

function MainMenuController:KnitInit()
    local CameraFolder = workspace:FindFirstChild('Cameras')
    if not CameraFolder then
        warn(`[MainMenu] Missing "Cameras" Folder in Workspace`)
    else
        for _, part in CameraFolder:GetChildren() do
            if part:IsA('BasePart') then
                self.Cameras[part.Name] = part
            end
        end
    end

    self:StartCamera()
end

function MainMenuController:KnitStart()
    self:SwitchCamera('MainCameraPart')
end


return MainMenuController

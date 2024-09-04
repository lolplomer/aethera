local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Util = require(ReplicatedStorage.Utilities.Util)

local MainMenuController = Knit.CreateController { Name = "MainMenuController" }


local rad = math.rad

local RigFocusedCamera = 'Customization'

local CustomizationTrove = Trove.new()
local CleanupCustomization = CustomizationTrove:WrapClean()

local RigPreview = workspace:FindFirstChild('RigPreview')
local DefaultRigCFrame = RigPreview and RigPreview.HumanoidRootPart.CFrame or CFrame.new()

local IdleAnimationId = "http://www.roblox.com/asset/?id=507766388"

local RigRotation = 0
local FOV = 0
local Holding = false

MainMenuController.Cameras = {
    Default = {CFrame = CFrame.new(0,50,0), Name = 'Default'}
}

local function lerp(a, b, t)
	return a + (b - a) * t
end

function MainMenuController:GetCameraPart(Name)
    local Camera = self.Cameras[Name]
    if not Camera then
        warn(`[MainMenu] Missing CameraPart "{Name}"`)
        Camera = self.Cameras.Default
    end
    return Camera
end

function MainMenuController:InitiateAvatarCustomization()
    CleanupCustomization()

    if not RigPreview then return end

    print('Initiating avatar customization')

    local LastPosition = nil

    CustomizationTrove:Add(function()
        RigRotation = 0
        FOV = 0
        Holding = false
    end)

    CustomizationTrove:Connect(UserInputService.InputBegan, function(input: InputObject, gp)
        
        if input.UserInputType ==Enum.UserInputType.MouseButton1 and not gp then
            Holding = true        
        end
    end)

    CustomizationTrove:Connect(UserInputService.InputEnded, function(input: InputObject)
        if input.UserInputType ==Enum.UserInputType.MouseButton1 then
            Holding = false
        end
    end)

    CustomizationTrove:Connect(UserInputService.InputChanged, function(input: InputObject, gp)
        if not LastPosition then
            LastPosition = input.Position
        end
        local Delta = LastPosition - input.Position
        LastPosition = input.Position

        if input.UserInputType == Enum.UserInputType.MouseMovement and Holding then
            

            RigRotation -= Delta.X * 0.3

            
        elseif input.UserInputType ==Enum.UserInputType.MouseWheel and not gp then
            FOV = math.clamp(FOV - input.Position.Z * 10,-45,10)
        end
    end)

    
end

function MainMenuController:SwitchCamera(Name)
    local Previous = self.Camera and self.Camera.Name
    local CameraPart = self:GetCameraPart(Name)
    

    self.Camera = CameraPart

    --self:UpdateCamera(true)

    print(Previous,Name)
    if Previous ~= Name then
        if Name == RigFocusedCamera then
            self:InitiateAvatarCustomization()
        elseif Previous == RigFocusedCamera then
            CleanupCustomization()
        end
    end

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

    local Position = CameraPart.CFrame.Position
    local Direction = CameraPart.CFrame.LookVector

    local MouseMovement = CFrame.Angles(-rad(Scale.Y * 5),-rad(Scale.X * 5),0)
    local Shake = CFrame.Angles(rad(math.sin(os.clock()) * .8), rad(math.cos(os.clock()) * .8), 0)

    local Goal
    if CameraPart.Name == RigFocusedCamera and RigPreview then
        Goal = CFrame.lookAt(Position, RigPreview.Head.CFrame.Position) * Shake
    else
        Goal = CFrame.lookAlong(Position, Direction) * MouseMovement * Shake
    end
    
    Camera.CFrame = Camera.CFrame:Lerp(Goal, immediate and .98 or 0.05)
    Camera.FieldOfView = lerp(Camera.FieldOfView, 55 + FOV, 0.2)

    if RigPreview then
        local Root = RigPreview.HumanoidRootPart

        Root.CFrame = Root.CFrame:Lerp(DefaultRigCFrame * CFrame.Angles(0, math.rad(RigRotation), 0), 0.2)
    end
end

function MainMenuController:StartCamera()
    
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

    local AvatarController = Knit.GetController('AvatarController')

    
    if RigPreview then
        
        local Humanoid = RigPreview.Humanoid

        RigPreview.HumanoidRootPart.Anchored = true
        Humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
        Humanoid.HealthDisplayDistance = Enum.HumanoidHealthDisplayType.AlwaysOff

        local Track: AnimationTrack = Util.LoadAnimation(RigPreview, IdleAnimationId)
        Track:Play()
        Track.Looped = true

        AvatarController:AddRigPreview(RigPreview)    
    end
end


return MainMenuController

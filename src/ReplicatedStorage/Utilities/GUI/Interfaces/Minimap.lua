local ProximityPromptService = game:GetService("ProximityPromptService")
local replicatedStorage = game:GetService("ReplicatedStorage")

local roact = require(replicatedStorage:WaitForChild('Utilities'):WaitForChild('Roact'))
local mapSettings = require(replicatedStorage:WaitForChild'GameModules':WaitForChild'MapSettings')
local GUIUtil = require(replicatedStorage:WaitForChild"Utilities":WaitForChild"GUI":WaitForChild"GUIUtil")
local IconManager = require(replicatedStorage:WaitForChild"Utilities":WaitForChild"GUI":WaitForChild"IconManager")


local Knit = require(replicatedStorage:WaitForChild('Packages'):WaitForChild('Knit'))
local GUI = Knit.GetController('GUI')

local HUD = roact.PureComponent:extend('Minimap')
local InnerFrameSize = UDim2.new(1,0,1,0)--UDim2.fromScale(0.8,.75)

local trove = require(replicatedStorage:WaitForChild"Packages":WaitForChild"Trove")

local scale = 0.8
local mainFrameSize = UDim2.fromScale(0.248*scale, 0.31*scale)

GUIUtil.ImplementAnimatedOpenClose (HUD, {
    Size = mainFrameSize,
    CloseSizeScale = 1,
})


function HUD:init()
    self.MinimapFrame = roact.createRef()
    self.FrameRef = roact.createRef()
    self.Player = roact.createRef()
    self.Cleaner = trove.new()
    self.Pointer = roact.createRef()
end

function HUD:didMount()
    local RunService = game:GetService('RunService')

    local player = game.Players.LocalPlayer
    
    local Character = player.Character or player.CharacterAdded:Wait()
    self.Cleaner:Connect(player.CharacterAdded, function(_char)
        Character = _char
    end)

    self.Cleaner:Connect(RunService.Heartbeat, function()
        local CF = Character.PrimaryPart:GetPivot()
        local pos = Vector2.new( CF.Position.X,CF.Position.Z)

        local mapFrame = self.MinimapFrame:getValue()
        local abs = mapFrame.Parent.AbsoluteSize
        local init = mapSettings.InitialPosition

        local center = Vector2.new(abs.X/2,abs.Y/2)
        mapFrame.Position = UDim2.fromOffset(center.X-pos.X+init.X/2,center.Y-pos.Y+init.Y/2)
    end)
end

function HUD:willUnmount()
    self.Cleaner:Destroy()
end

function HUD:didUpdate(prevProps)
    GUIUtil.CheckDisabledProperty(self, prevProps)
end

function HUD:render()
    return roact.createElement('ScreenGui', {
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    }, {

        MainFrame = roact.createElement('CanvasGroup', {
           Size = mainFrameSize,
           AnchorPoint = Vector2.new(0,1),
           Position = UDim2.new(0,20,1,-20),
           BackgroundTransparency = 1,
           [roact.Ref] = self.FrameRef,
        }, {

            Aspect = roact.createElement('UIAspectRatioConstraint', {
                AspectRatio = 1.382
            }),

            Button = roact.createElement('ImageButton', {
                BackgroundTransparency = 1,
                ImageTransparency = 1,
                Size = UDim2.fromScale(1,1),
                Active = true,
                ZIndex = 6,
                [roact.Event.MouseButton1Click] = function()
                    IconManager('Map'):select()
                end
            }, {
                
            }),
            

            OuterFrame = roact.createElement('ImageLabel', {
                BackgroundTransparency = 1,
                Size = UDim2.fromScale(1,1),
                Image = "rbxassetid://17493523216",
                ZIndex = 1
            }),

            Frame = roact.createElement('ImageLabel', {
                BackgroundTransparency = 1,
                Size = UDim2.new(1,0,1,0),
                Image = "rbxassetid://17472232838",
                ZIndex = 4,
                AnchorPoint = Vector2.new(.5,.5),
                Position = UDim2.fromScale(.5,.5),
                --ScaleType = Enum.ScaleType.Fit
            }),

            InnerShadow = roact.createElement('ImageLabel', {
                BackgroundTransparency = 1,
                Size = UDim2.fromScale(1,1),
                Image = "rbxassetid://17493523574",
                ZIndex = 3
            }),

            KeybindLabel = GUI.newElement('KeybindLabel', {
                Position = UDim2.new(1,-12,1,-12),
                AnchorPoint = Vector2.new(1,1),
                Keybind = 'Map',
            }),

            InnerFrame = roact.createElement('Frame' , {
                ClipsDescendants = true,
                Size = InnerFrameSize,
                AnchorPoint = Vector2.new(.5,.5),
                Position = UDim2.fromScale(.5,.5),
                BackgroundTransparency = 1,
                ZIndex = 2
            }, {    
                Map = GUI.newElement('Map', {
                    [roact.Ref] = self.MinimapFrame,
                    DisableMarkerAnimation = true,
                    Disabled = self.props.Disabled,
                    Name = 'Minimap',
                    Scale = 1
                }),
                Corner = roact.createElement('UICorner', {CornerRadius = UDim.new(0.1,0)})
            })

        }),

    })
end

return HUD
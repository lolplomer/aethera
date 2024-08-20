local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GUIUtil = game.ReplicatedStorage:WaitForChild"Utilities"
local GameModules = game.ReplicatedStorage:WaitForChild"GameModules"

local RatingModule = require(GameModules:WaitForChild"Rating")
local ItemsModule = require(GameModules:WaitForChild"Items")

local TextLabel = require(script.Parent:WaitForChild"TextLabel")
local roact = require(GUIUtil:WaitForChild"Roact")

local Models = game.ReplicatedStorage:WaitForChild"Models"

local function Corner()
    return roact.createElement("UICorner", {
        CornerRadius = UDim.new(0.2,0)
    })
end

local Slot = roact.PureComponent:extend("Slot")

local itemCategoryOffsets = {
    Weapons = CFrame.Angles(0,0,math.rad(45))
}
local zeroCF = CFrame.new() 

local Knit = require(ReplicatedStorage:WaitForChild('Packages'):WaitForChild('Knit'))
local GUI = Knit.GetController("GUI")

local BodyShotConfig = {
    Torso = CFrame.new(0,0.6,-5),
    Legs = CFrame.new(0,-1.2,-5)
}

function Slot:init()
   -- print("Initializing",self.props.itemName)
    self.viewportRef = roact.createRef()
    self.cameraRef = roact.createRef()
    self.innerFrameRef = roact.createRef()
    self.outerFrameRef = roact.createRef()
end

function Slot:render()
   -- print(`Rendering {self.props.itemName}`)
    local props = self.props 
    
    local item = ItemsModule[props.ItemData]
    local amount = props.ItemData and props.ItemData[3] or 1

    local rating = RatingModule[props.Rating or (item and item.Rating)] or RatingModule()
    local OuterFrameColor = rating.OuterColor
    if not OuterFrameColor then
        OuterFrameColor = GUI.Color.MultiplyValue(rating.Color, 0.7)
    end

    local iconProperty = {
        BackgroundTransparency = 1,
        
        AnchorPoint = Vector2.new(0.5,0.5),
        Position = UDim2.fromScale(0.5,0.5),
        Size = UDim2.fromScale(0.85,0.85),
        
    }

    local Model: Model, UseImageLabel: boolean, cameraCF: CFrame = nil, true, nil

    local EmptyIcon = nil
    if props.EquipType then
        local eq = props.EquipType
        EmptyIcon = ItemsModule.Type[eq.Type].Subtype[eq.Subtype].Icon
    end

    local function useImage()
        self.UsingViewport = false
        iconProperty.Image = item and item.Icon.ImageId or EmptyIcon
        if EmptyIcon then
            iconProperty.ImageColor3 = Color3.fromRGB(104, 104, 104)
            iconProperty.ImageTransparency = 0.5
        end
    end

    if item and item.Model then
        Model = Models:FindFirstChild(item.Model)
        if Model and not item.Icon.ImageId then
            self.UsingViewport = true
            UseImageLabel = false

            iconProperty["ref"] = self.viewportRef
            iconProperty.CurrentCamera = self.cameraRef
            iconProperty.Size = UDim2.fromScale(0.9,0.9)
            iconProperty.LightColor = Color3.new(1, 1, 1)
            iconProperty.Ambient = Color3.new(1, 1, 1)
            
            
            if item.Equipment.Type == 'Body' then

                iconProperty.LightDirection = Vector3.new(0,-1,0.2)
                local modelCF, _ = Models.Rig:GetBoundingBox()
                local offset = BodyShotConfig[item.Equipment.Subtype] or CFrame.new()

                cameraCF = CFrame.lookAt((modelCF * CFrame.new(-20,0,-20).Position),modelCF.Position) * offset
            else
                local modelCF, modelSize = Model:GetBoundingBox()

                local orientation = modelCF - modelCF.Position
                if Model.PrimaryPart then
                    orientation = Model.PrimaryPart.CFrame - Model.PrimaryPart.CFrame.Position
                end
                
                local baseCF = CFrame.new(modelCF.Position)
                local baseOffset = CFrame.new(0, 0.25, modelSize.Y * 4.3)
                local categoryOffset = itemCategoryOffsets[item.Category] or zeroCF
                local customOffset = item.Icon.ViewportOffset or zeroCF
    
                cameraCF = baseCF * orientation * baseOffset * categoryOffset * customOffset
            end
          
        else
           useImage()
        end
    else
        useImage()
    end

   return roact.createElement("CanvasGroup", {
       BackgroundColor3 = OuterFrameColor,
       BorderSizePixel = 0,
       LayoutOrder =  (self.props.LayoutOrder or -rating.Rank) - (props.Equipped and 1000 or 0),
       ["ref"] = self.outerFrameRef,
       Size = self.props.Size or UDim2.fromScale(1,1),
       Position = self.props.Position,
       AnchorPoint = self.props.AnchorPoint,
     --  GroupTransparency = self.transparency,
   }, {
       UICorner = roact.createElement(Corner),
       UIAspectRatioConstraint = roact.createElement("UIAspectRatioConstraint"),
    --    UIGradient = roact.createElement(Gradient,{
    --        Color = Color3.fromRGB(199,199,199)
    --    }),
       AmountLabel = amount > 1 and roact.createElement(TextLabel, {
           AnchorPoint = Vector2.new(0.5,1),
           BackgroundTransparency = 1,
           Position = UDim2.fromScale(0.5,1),
           Size = UDim2.fromScale(1,0.4),
           TextStrokeColor3 = Color3.fromRGB(47, 47, 47),
           TextStrokeTransparency = 0.5,
           TextColor3 = Color3.new(1,1,1),
           TextScaled = true,
           Text = amount,
           TextXAlignment = 'Center',
       }),
       ClickDetect = roact.createElement("ImageButton", {
           ImageTransparency = 1,
           BackgroundTransparency = 1,
           Size = UDim2.fromScale(1,1),
           Image = "",
           [roact.Event.Activated] = self.props.Callback,
           [roact.Event.MouseEnter] = function()
                GUI.Tween(self.innerFrameRef:getValue(), {BackgroundColor3 = GUI.Color.MultiplyValue(rating.Color, 0.85)})
           end,
           [roact.Event.MouseLeave] = function()
                task.wait()
                GUI.Tween(self.innerFrameRef:getValue(), {BackgroundColor3 = rating.Color})
           end
       }),
       Equipped = (props.Equipped or props.PositionEquipped) and roact.createElement("ImageLabel", {
            AnchorPoint = Vector2.new(1,1),
            Size = UDim2.fromScale(0.3,0.3),
            SizeConstraint = Enum.SizeConstraint.RelativeXX,
            BackgroundTransparency = 1,
            Position = UDim2.fromScale(0.95,0.95),
            Image = "rbxassetid://15109799529",
            ZIndex = 2,
       }),
       EquipPos = props.EquipPosition and roact.createElement("TextLabel", {
            AnchorPoint = Vector2.new(0,1),
            Size = UDim2.fromScale(0.3,0.3),
            SizeConstraint = Enum.SizeConstraint.RelativeXX,
            Position = UDim2.fromScale(0,0.95),
            Text = props.EquipPosition,
            TextScaled = true,
            Font = Enum.Font.SourceSansBold,
            TextColor3 = Color3.new(0.3, 0.3, 0.3)
       }, {
            Corner = roact.createElement("UICorner", {CornerRadius = UDim.new(0.4,0)})
       }),
       InnerFrame = roact.createElement("Frame", {
           AnchorPoint = Vector2.new(0.5,0.5),
           Position = UDim2.fromScale(0.5,0.5),
           BackgroundColor3 = rating.Color,
           Size = UDim2.fromScale(0.87,0.87),
           BorderSizePixel = 0,
           ["ref"] = self.innerFrameRef,
       }, {
           UICorner = roact.createElement(Corner),
        --    UIGradient = roact.createElement(Gradient,{
        --        Color = Color3.fromRGB(132, 132, 132)
        --    }),
           Icon = UseImageLabel and roact.createElement("ImageLabel", iconProperty) 
            or roact.createElement("ViewportFrame", iconProperty, {
                Camera = roact.createElement("Camera", {
                    
                    FieldOfView = 9,
                    CFrame = cameraCF,
                    ["ref"] = self.cameraRef,

                })
            }),
       }),
        --Equipped = props.Equipped and roact.createElement("ImageLabel", {
       
   })
end

function Slot:updateViewportModel()
    if self.PreviewModel then
        self.PreviewModel:Destroy()
    end

    if self.UsingViewport then
        local item = ItemsModule[self.props.ItemData]
        local previewModel = Models[item.Model]:Clone()

        if item.Equipment.Type == 'Body' then
            local worldModel = Instance.new('WorldModel')

            local rig = Models.Rig:Clone()
            local typeInfo = item:GetTypeInfo()
            
            rig.Parent = worldModel
            rig.HumanoidRootPart.Anchored = true

            worldModel.Parent = self.viewportRef:getValue()
            typeInfo.ApplyInstanceViewport(previewModel, rig)

            self.PreviewModel = rig
        else
            previewModel.Parent = self.viewportRef:getValue()
            self.PreviewModel = previewModel
        end
        
    end
end

function Slot:didUpdate(previousProps)
    if self.props.ItemData ~= previousProps.ItemData then
        self:updateViewportModel()
    end
end

function Slot:didMount()
    local outerFrame = self.outerFrameRef:getValue()
    outerFrame.GroupTransparency = 1
    GUI.Tween(outerFrame, {GroupTransparency = 0})
    self:updateViewportModel()
end

return Slot
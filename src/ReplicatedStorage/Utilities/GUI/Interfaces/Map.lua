
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local roact = require(game.ReplicatedStorage:WaitForChild('Utilities'):WaitForChild('Roact'))

local WindowManager = require(ReplicatedStorage:WaitForChild"Utilities":WaitForChild"GUI":WaitForChild"WindowManager")

local Map = WindowManager.new('Map', {
    FullSize = true, 
    DisableIcon = true, 
    CloseSizeScale = 1,
    Keybind = 'Map'
})
local Knit = require(ReplicatedStorage:WaitForChild('Packages'):WaitForChild('Knit'))
local GUI = Knit.GetController'GUI'

local MapSettings = require(game.ReplicatedStorage:WaitForChild"GameModules":WaitForChild"MapSettings")
local IconManager = require(game.ReplicatedStorage.Utilities.GUI:WaitForChild"IconManager")

local Component = Map.Component

local Frame = Map.Frame

local trove = require(game.ReplicatedStorage:WaitForChild"Packages":WaitForChild"Trove")
local util = require(ReplicatedStorage:WaitForChild"Utilities":WaitForChild"Util")
local tweenInfo = TweenInfo.new(.7,Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

local Window = require(ReplicatedStorage.Utilities.GUI:WaitForChild"WindowManager")

local mapComponent = GUI.GetComponent('Map')
local player = game.Players.LocalPlayer

function Map:init()
    self.MapFrame = roact.createRef()
    self._component:setState{MapScale = 3}

    -- local keybindController = Knit.GetController('InputController')
    
    -- keybindController:OnKeybindTrigger('Map', function()
    --     if util.Debounce('Map',1) then
    --         local icon = IconManager('Map')
    --         if self.state.selected then
    --             WindowManager:SwitchWindow()
    --             --icon:deselect()
    --         else
    --             icon:select()
    --         end
    --     end
    -- end)

    Map._component:setState{MapScale = 3}
end

function Map:didUpdate(_,prevState)
    --print('Checking property disabled:',self.state.selected)
    if not self.state.selected then
        if self.Cleaner then
           -- print('Removed cleaner')
            self.Cleaner:Destroy()
        end
    end
    GUI.DisableScroll = self.state.selected

    if prevState.selected ~= self.state.selected then
        
        if not self.state.selected then
            GUI:ClosePopup'AddMarker'
            Map._component:setState{MapScale = 3,SelectPosition = roact.None}
        else
            if not self.Cleaner then
                self.Cleaner = trove.new()    
            end
            
            
            self.Cleaner:Add(function()
                self.Cleaner = nil
            end)
    
            local char:Model = nil
            self.Cleaner:Add(util.CharacterAdded(game.Players.LocalPlayer, function(c)
                char = c
            end))
    
            local MapFrame = self.MapFrame:getValue()
            local ABS = MapFrame.Parent.AbsoluteSize
    
            local cf = char:GetPivot()
            local x,y = cf.Position.X, cf.Position.Z
    
           
            local Pos = Vector3.new(
                ABS.X/2 - x, 
                ABS.Y/2 - y,
                0
            )
            Map._component:setState{MapScale = 1}
    
            MapFrame.Position = UDim2.fromOffset(Pos.X,Pos.Y)      
    
            local UIS = game:GetService('UserInputService')
    
            local Holding
    
            local prevPos = nil
            self.Cleaner:Connect(UIS.InputBegan, function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    Holding = true
                end
            end)
    
            self.Cleaner:Connect(UIS.InputEnded, function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    prevPos = nil
                    Holding = false
                elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
                    self._component:setState {SelectPosition = input.Position}
                    
                    local mapFrame = self.MapFrame:getValue()
                    
                    local scale = self.state.MapScale
                    local mapPos = mapComponent:ToMapPosition(self.state.SelectPosition, scale, mapFrame)
                    local worldPos = mapComponent:ToWorldPosition(mapPos, scale)
                    
                    local function Done()
                        GUI:ClosePopup'AddMarker'
                        self._component:setState {SelectPosition = roact.None}
                      --  print(self.state.SelectPosition, 'DESELECTED')
                    end

                    GUI:CreatePopup(GUI.newElement('ButtonList', {
                        Buttons = {
                            {Text = 'Add Marker', Callback = function()
                                local MapService = Knit.GetService('MapService')
                                MapService:AddMarker(worldPos, 'Marker')
                                Done()
                            end},
                            {Text = 'Teleport to here', Callback = function()
                         

                                char:PivotTo(CFrame.new(worldPos))

                                Done()
                            end}
                        },
                        Padding = 10
                    }), 'AddMarker', {
                        Position = UDim2.fromOffset(input.Position.X, input.Position.Y),
                        AnchorPoint = Vector2.new(0,0),
                        Size = UDim2.fromScale(0.15,0.1),
                        CloseSizeScale = 1.05,
                        UseRatio = false,
                    }, Done)
                end
            end)
    
            local function UpdatePos(newPos)
                Pos = newPos
                TweenService:Create(MapFrame,tweenInfo, {Position = UDim2.fromOffset(Pos.X,Pos.Y)}):Play()
                --MapFrame.Position = UDim2.fromOffset(Pos.X,Pos.Y)
            end
    
           -- local prevScale = 1
            self.Cleaner:Connect(UIS.InputChanged, function(input:InputObject)
                if Holding and input.UserInputType == Enum.UserInputType.MouseMovement then
                    if not prevPos then
                        prevPos = input.Position
                    end
                    
                    --MapFrame.Position = UDim2.fromOffset(Pos.X,Pos.Y)
                    UpdatePos(Pos + input.Position - prevPos)
                    --TWS:Create(MapFrame, TWInfo, {Position = UDim2.fromOffset(Pos.X,Pos.Y)   }):Play()
                    --MapFrame.Position = UDim2.fromOffset(Pos.X,Pos.Y)      
    
                    prevPos = input.Position
                elseif input.UserInputType == Enum.UserInputType.MouseWheel then
                    local wheel = input.Position.Z
                    local prev = self.state.MapScale
                    Map._component:setState {
                        MapScale = math.clamp(self.state.MapScale + wheel/4,0.25,5)
                    }
    
                    if prev ~= self.state.MapScale then
                       -- local viewport = workspace.CurrentCamera.ViewportSize
                        local delta = (Pos - input.Position) * wheel/(4*(self.state.MapScale))
                        UpdatePos(Pos + delta)
                    end
                    
                
                end
            end)
           
        end
    end

   
end
 
function Map:didMount()
 
    

  
end

Frame
:disableListLayout()
:addElement(function()
    local state = Map._component.state
    return GUI.newElement('BlankFrame', {}, {
        Map = GUI.newElement('Map', {
            [roact.Ref] = Map.MapFrame,
            ShowMarkers = true,
            Scale = state.MapScale,
            Disabled = not state.selected,
            DisabledScale = state.MapScale,
            DisableMarkerAnimation = false,
            SelectPosition = state.SelectPosition == roact.None and nil or state.SelectPosition
        })
    })
    
end)


return Component
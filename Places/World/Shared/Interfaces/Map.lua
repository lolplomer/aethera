
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

local function GetViewBoundary(position: Vector2)
    local viewport = workspace.CurrentCamera.ViewportSize
    local scale = Vector2.new(position.X,position.Y)/viewport
    local sequence = Vector2.new(math.floor(scale.X), math.floor(scale.Y))
    local result = viewport * sequence
   -- print(result, "| sequence: ", sequence, "| scale: ", scale)
    return Vector3.new(result.X,result.Y)
end

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
            end,false))
    
            local MapFrame = self.MapFrame:getValue()
            local ABS = MapFrame.Parent.AbsoluteSize
            local init = MapSettings.InitialPosition
            local initVector3 = Vector3.new(init.X,init.Y,0)

            local cf = char:GetPivot() 
            local x,y = cf.Position.X, cf.Position.Z
            local Anchor = Vector2.new()
    
           
            -- local Pos = Vector3.new(
            --     ABS.X/2 - x, 
            --     ABS.Y/2 - y,
            --     0
            -- )

            local center = Vector3.new(ABS.X/2,ABS.Y/2)
            local Pos = Vector3.new(
                center.X-x+init.X/2,
                center.Y-y+init.Y/2,
                0
            )
            Map._component:setState{MapScale = 1}
    
            MapFrame.Position = UDim2.fromOffset(Pos.X,Pos.Y)      
    
            local UIS = game:GetService('UserInputService')
    
            local Holding
    
            local prevPos = nil


            local function UpdatePos(newPos)
                if newPos then
                    Pos = newPos                       
                end

                
                TweenService:Create(MapFrame,tweenInfo, {Position = UDim2.fromOffset(Pos.X,Pos.Y)}):Play()
                --MapFrame.Position = UDim2.fromOffset(Pos.X,Pos.Y)
            end

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
                   -- print(self._component)
                    local mapFrame = self.MapFrame:getValue()
                    
                    local scale = self.state.MapScale
                    local mapPos = mapComponent:ToMapPosition(input.Position, scale, mapFrame)
                    local worldPos = mapComponent:ToWorldPosition(mapPos, scale)

                    --UpdatePos(Vector3.new(mapPos.X,mapPos.Y))
                    
                    local function Done()
                        GUI:ClosePopup'AddMarker'
                        self._component:setState {SelectPosition = roact.None}
                        print('deselected')
                      --  print(self.state.SelectPosition, 'DESELECTED')
                    end

                    GUI:CreatePopup('AddMarker', GUI.newElement('ButtonList', {
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
                    }), {
                        Position = UDim2.fromOffset(input.Position.X, input.Position.Y),
                        AnchorPoint = Vector2.new(0,0),
                        Size = UDim2.fromScale(0.15,0.1),
                        CloseSizeScale = 1.05,
                        UseRatio = false,
                    }, Done)
                end
            end)
    
    
           -- local prevScale = 1
            self.Cleaner:Connect(UIS.InputChanged, function(input:InputObject)
             
                if Holding and input.UserInputType == Enum.UserInputType.MouseMovement then
                    if not prevPos then
                        prevPos = input.Position
                    end
                    
                    

                    --MapFrame.Position = UDim2.fromOffset(Pos.X,Pos.Y)
                    UpdatePos(Pos + input.Position - prevPos)



                    --GetViewBoundary(Pos)
                   -- print(GetViewBoundary(Pos))
                    --TWS:Create(MapFrame, TWInfo, {Position = UDim2.fromOffset(Pos.X,Pos.Y)   }):Play()
                    --MapFrame.Position = UDim2.fromOffset(Pos.X,Pos.Y)      
    
                    prevPos = input.Position
                elseif input.UserInputType == Enum.UserInputType.MouseWheel then
                    local wheel = input.Position.Z
                    local prev = self.state.MapScale
                    local new =math.clamp(self.state.MapScale + wheel/4,0.15,5)
                    
                    Map._component:setState {
                        MapScale = new
                    }
                    
                       
                       --local delta = (Pos - input.Position) * wheel/(4*(self.state.MapScale))
                       --print(prev,Map._component.state.MapScale   )
                     --print(self._component.props.MapScale, prev)
                        task.wait()
                        
                        local mapFrame = self.MapFrame:getValue()
                        local mousePos = self.MousePosition
                        local mapPos = mapFrame.Position
                    
                        -- Calculate the delta to maintain focus on the mouse position
                        local scaleFactor = new / prev
                        local delta = (input.Position - Pos) * (1 - scaleFactor)
                    
                        -- Apply the calculated delta to the map position
                        UpdatePos(Pos + delta)

                    --    if self.state.MapScale > 0.25 then
                    --     local viewport = GetViewBoundary(Pos)
                    --     local InitPos = Pos - viewport
                        
                    --     local delta = (input.Position - Pos) * wheel/((self.state.MapScale) * 4)

                    --     UpdatePos(Pos - delta)
                    --    end
                    
                    
                end
            end)
           
        end
    end

   
end
 
function Map:didMount()

end

Frame
:disableListLayout()
:addElement(function(...)

    local state = Map._component.state
    return GUI.newElement('BlankFrame', {}, {
        Map = GUI.newElement('Map', {
            ["_ref"] = Map.MapFrame,
            ShowMarkers = true,
            Scale = state.MapScale,
            Disabled = (not state.selected),
            DisabledScale = state.MapScale,
            DisableMarkerAnimation = false,
            SelectPosition = state.SelectPosition == roact.None and nil or state.SelectPosition,
            AnchorRelativeTo = "Mouse",
        })
    })
    
end)


return Component
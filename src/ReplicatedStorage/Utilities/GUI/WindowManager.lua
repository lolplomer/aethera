

local ReplicatedStorage = game.ReplicatedStorage
local knit = require(ReplicatedStorage:WaitForChild"Packages":WaitForChild"Knit")
local GUI = knit.GetController"GUI"

local roact = require(ReplicatedStorage:WaitForChild"Utilities":WaitForChild"Roact")

local windows = {}

local Frame = require(script.Parent:WaitForChild"FrameManager")
local TWS = game:GetService"TweenService"
local Tween = TweenInfo.new(0.15)

local IconManager = require(script.Parent:WaitForChild"IconManager")
local Promise = require(ReplicatedStorage.Utilities:WaitForChild"Promise")

local GuiUtil = require(script.Parent:WaitForChild"GUIUtil")

local coreGuis = {
    Backpack = true,
    Chat = true,
    PlayerList = true,
}

local function SetCoreGuiEnabled(enabled)
    for name in coreGuis do
        game.StarterGui:SetCoreGuiEnabled(name, enabled)
    end
end

local windowHandler = {}
windowHandler.__index = function(self, index)
    if index ~= "state" then
        return windowHandler[index] or rawget(self,index)
    else
        return self._component and self._component.state
    end
end

function windowHandler:setState(newStates)
    if self._component then
        self._component:setState(newStates)
    end
end

function windowHandler:setFrameTransparency(transparencyValue)
    self:setState{FrameTransparency = transparencyValue}
end

function windowHandler:getActiveComponent()
    return self._component
end

local windowManager = {}
windowManager.__index = windowManager

local selectedWindow, pendingWindow = nil, nil

function windowManager:SwitchWindow(WindowName)
    local window = windows[WindowName]
    local current = selectedWindow

    if not window and current then
        current.DisableBlur:Play()
        current._component:close()
        current._component:setState {selected = false}

        if not pendingWindow then
            GUI:EnableAll()
            SetCoreGuiEnabled(true)
            IconManager.Controller.setTopbarEnabled(true)
        end
        
    elseif window then 
        -- while pendingWindow do
        --     task.wait()
        -- end


        pendingWindow = window
        if current then
            --print(current, current.Name)
            -- current.DisableBlur:Play()
            -- --GUI:DisableUI(current.Name)
            -- current._component:setState {selected = false}
            IconManager(current.Name):deselect()
            
        end
        pendingWindow = nil
        
        GUI:DisableAllExcept ({WindowName})
        --GUI:EnableUI(WindowName)
        window.EnableBlur:Play()
        window._component:open()
        window._component:setState {selected = true}

        IconManager.Controller.setTopbarEnabled(false)
        SetCoreGuiEnabled(false) 
    end
    
    selectedWindow = window
end

function windowManager.new(WindowName, props)
    if windows[WindowName] then
        return windows[WindowName]
    end

    props = props or {}
    
    windows[WindowName] = setmetatable({}, windowHandler)

    local window = windows[WindowName]
    local component = roact.PureComponent:extend(`{WindowName}_Window`)

    local EnableBlur, DisableBlur
    local function InitializeBlur()
        local blur = Instance.new"BlurEffect"
        blur.Size = 0
        blur.Parent = game.Lighting
        blur.Name = `{WindowName}Blur`
    
        EnableBlur = TWS:Create(blur, Tween, {Size = 16})
        DisableBlur = TWS:Create(blur, Tween, {Size = 0})
    end
    
    InitializeBlur()

    GuiUtil.ImplementAnimatedOpenClose(component, {
        Size = UDim2.new(0.725, 0,0.725, 0),
        CloseSizeScale = 1.1
    })

    component.Name = WindowName
    component.IsWindow = true

    function component:init()
        self:setState{
            FrameTransparency = 1,
        }
        window._component = self

        self.FrameRef = roact.createRef()
        self.TopbarOffset = UDim2.fromScale(-0.04,0.03)
        if window.init then
            window:init()
        end
    end 


    function component:render()

        return roact.createElement("ScreenGui", {
            ZIndexBehavior = Enum.ZIndexBehavior.Sibling    
        }, {
            Frame = GUI.newElement("Frame", {
                Visible = true,
                [roact.Ref] = self.FrameRef,
                Size = self.Size
            }, {
                Topbar = GUI.newElement("FrameTopbar", {
                    Title = WindowName,
                    Position = self.TopbarOffset,
                }),
                CloseButton = GUI.newElement("CloseButton", {
                    Size = UDim2.fromScale(0.13,0.13),
                    AnchorPoint = Vector2.new(1,0),
                    Position = UDim2.fromScale(.98, self.TopbarOffset.Y.Scale-0.015),
                    Callback = function()
                        self.icon:deselect()
                    end
                }),
                MainFrame = roact.createElement("Frame", {
                    BackgroundTransparency = 1,
                    Position = UDim2.fromScale(0.5,0.17),
                    Size = UDim2.new(1,-10,0.82,0),
                    AnchorPoint = Vector2.new(0.5,0)
                }, {
                    Frame = window.Frame:render()
                })
            }),
        })
    end

    function component:didUpdate(prevProps)
      --  print('didUpdated', WindowName, window.onUpdated, window)
        GuiUtil.CheckDisabledProperty(self, prevProps)
       -- print('Didupdated 2', WindowName, window.onUpdated, window)
        if window.didUpdate then
           -- print('Calling in window onUpdated', WindowName)
            window:didUpdate(prevProps)
        end
    end

    function component:didMount(...)

        self:close()

        local icon = IconManager(WindowName)
        :setOrder(5)
        :setLabel(WindowName)
        :disableStateOverlay(true)
        :bindEvent("selected", function(_icon)
            -- EnableBlur:Play()
            -- GUI:DisableAllExcept {WindowName}
            -- IconManager.Controller.setTopbarEnabled(false)
            -- SetCoreGuiEnabled(false)
            -- self:open()
            -- self:setState {selected = true}

            windowManager:SwitchWindow(WindowName)
        end)
        :bindEvent("deselected", function()
            -- DisableBlur:Play()
            -- self:close()
            -- GUI:EnableAll()
            -- SetCoreGuiEnabled(true)
            -- IconManager.Controller.setTopbarEnabled(true)
            -- self:setState {selected = false}
            
            windowManager:SwitchWindow(nil, true)
        end)
        :autoDeselect(false)

        if props.DisableIcon then
            icon:setEnabled(false)
        end

        self.icon = icon

        if window.didMount then
            window:didMount(...)
        end
    end

    function component:willUnmount(...)
        if window.willUnmount then
            window:willUnmount(...)
        end
    end

    window.EnableBlur = EnableBlur
    window.DisableBlur = DisableBlur

    window.Component = component
    window.Frame = Frame.new(UDim2.fromScale(1,1), nil, window)
    window.Name = WindowName
    

    return windows[WindowName]
end


return windowManager
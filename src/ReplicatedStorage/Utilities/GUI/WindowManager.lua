

local ReplicatedStorage = game.ReplicatedStorage
local knit = require(ReplicatedStorage:WaitForChild"Packages":WaitForChild"Knit")
local GUI = knit.GetController"GUI"
local CharacterController = knit.GetController"CharacterController"

local roact = require(ReplicatedStorage:WaitForChild"Utilities":WaitForChild"Roact")

local windows = {}

local Frame = require(script.Parent:WaitForChild"FrameManager")
local StarterGui = game:GetService("StarterGui")
local TWS = game:GetService"TweenService"
local Tween = TweenInfo.new(0.15)

local IconManager = require(script.Parent:WaitForChild"IconManager")
--local Promise = require(ReplicatedStorage.Utilities:WaitForChild"Promise")

local GuiUtil = require(script.Parent:WaitForChild"GUIUtil")
local Util = require(ReplicatedStorage.Utilities:WaitForChild"Util")

local coreGuis = {
    Backpack = true,
    Chat = true,
    PlayerList = true,
    EmotesMenu = true,
}

local CoreGuiInfo = nil

local function RevertCoreGui()
    if CoreGuiInfo then
        for name in coreGuis do
            game.StarterGui:SetCoreGuiEnabled(name, CoreGuiInfo[name])
        end
        CoreGuiInfo = nil 
    end

end

local function SetCoreGuiDisabled()
    RevertCoreGui()
    CoreGuiInfo = {}
    for name in coreGuis do
        CoreGuiInfo[name] = StarterGui:GetCoreGuiEnabled(name)
        game.StarterGui:SetCoreGuiEnabled(name, false)
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

function windowManager:SwitchWindow(WindowName, BypassDebounce)
    local window = windows[WindowName]
    local current = selectedWindow

    --print('Switching window',WindowName)

    if not Util.Debounce('WindowSwitch', 1) and not BypassDebounce then
        return
    end
   -- print('Switching window 2')
    if (not window) and current then
   --     print('Disabling blur')
        current.DisableBlur:Play()
        current._component:close()
        current._component:setState {selected = false}

        if not pendingWindow then
            GUI:EnableAll()
            RevertCoreGui()
            --SetCoreGuiEnabled(true)
            IconManager.Controller.setTopbarEnabled(true)
        end
        
    elseif window then 
        -- while pendingWindow do
        --     task.wait()
        -- end


        pendingWindow = window
        if current then
      --      print('Has currently open window, closing:')
            --print(current, current.Name)
            -- current.DisableBlur:Play()
            -- --GUI:DisableUI(current.Name)
            -- current._component:setState {selected = false}
            --IconManager(current.Name):deselect()
            windowManager:SwitchWindow(nil, true)
        end
       -- print('Continuing enable new window')
        pendingWindow = nil
        
        GUI:DisableAllExcept ({WindowName})
        --GUI:EnableUI(WindowName)
        window.EnableBlur:Play()
        window._component:open()
        window._component:setState {selected = true}

        IconManager.Controller.setTopbarEnabled(false)
        SetCoreGuiDisabled()
        --SetCoreGuiEnabled(false) 
    end
    
    selectedWindow = window
    
    CharacterController:ChangeState(selectedWindow and 'Busy')
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

    local size = props.FullSize and UDim2.fromScale(1,1) or UDim2.fromScale(0.725,0.725)

    GuiUtil.ImplementAnimatedOpenClose(component, {
        Size = size,
        CloseSizeScale = props.CloseSizeScale or 1.1
    })

    component.Name = WindowName
    component.IsWindow = true

    function component:init()
        self:setState{
            FrameTransparency = 1,
        }
        window._component = self
        window.props = self.props

        self.MainFrame = roact.createRef()
        self.TopbarOffset = UDim2.fromScale(-0.04,0.03)
        if window.init then
            window:init()
        end
    end 

    function component:render()
        -- local Child
        -- if not props.FullSize then
            
        --     Child = {
        --         Frame = ,
        --     }

        -- else
            
        --     Child = {
        --         Frame = 
        --     }
        -- end

        -- return roact.createElement("ScreenGui", {
        --     ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        --     ResetOnSpawn = false,
        --     DisplayOrder = 99,
        --     IgnoreGuiInset = true
        -- }, Child)

        return 
        
        props.FullSize and 
        
        roact.createElement('CanvasGroup', {
            ["ref"] = self.MainFrame,
            Size = UDim2.fromScale(1,1),
            BackgroundColor3 = Color3.fromRGB(0,0,0),
            BackgroundTransparency = 0.6,
            AnchorPoint = Vector2.new(0.5,0.5),
            Position = UDim2.fromScale(0.5,0.5)
        }, {
            CloseButton = GUI.newElement("CloseButton", {
                Size = UDim2.fromScale(0.07,0.07),
                AnchorPoint = Vector2.new(1,0),
                Position = UDim2.fromScale(.98, self.TopbarOffset.Y.Scale-0.015),
                Callback = function()
                    --print('Callback')
                    windowManager:SwitchWindow(nil)
                    --self.icon:deselect()
                end
            }),
            MainFrame = roact.createElement("Frame", {
                BackgroundTransparency = 1,
                Position = UDim2.fromScale(0.5,0.11),
                Size = UDim2.new(0.95,0,0.82,0),
                AnchorPoint = Vector2.new(0.5,0),
                ClipsDescendants = true,
            }, {
                Frame = window.Frame:render()
            })
        }) 
        
        
        or 
        
        
        
        GUI.newElement("Frame", {
            Visible = true,
            ["ref"] = self.MainFrame,
            Size = self.Size,
            
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
                    windowManager:SwitchWindow(nil, true)
                    --self.icon:deselect()
                end
            }),
            MainFrame = roact.createElement("Frame", {
                BackgroundTransparency = 1,
                Position = UDim2.fromScale(0.5,0.17),
                Size = UDim2.new(1,-10,0.82,0),
                AnchorPoint = Vector2.new(0.5,0),
                
            }, {
                Frame = window.Frame:render()
            })
        })

    end


    function component:componentDidUpdate(prevProps,prevState)
      --  print('didUpdated', WindowName, window.onUpdated, window)
        GuiUtil.CheckDisabledProperty(self, prevProps)
       -- print('Didupdated 2', WindowName, window.onUpdated, window)
        if window.didUpdate then
           -- print('Calling in window onUpdated', WindowName)
            window:didUpdate(prevProps,prevState)
        end
    end

    function component:componentDidMount(...)
        --print(WindowName,'FrameRef:',self.MainFrame)
        local InputController = knit.GetController("InputController")
        self:close()    

        local icon = IconManager(WindowName)
        :setOrder(5)
        :setLabel(WindowName .. (props.Keybind and (" - " ..InputController:GetInputOfKeybind(props.Keybind).Name) or ""))
        :disableStateOverlay(true)
        :oneClick(true)
        :bindEvent("selected", function(_icon)
            -- EnableBlur:Play()
            -- GUI:DisableAllExcept {WindowName}
            -- IconManager.Controller.setTopbarEnabled(false)
            -- SetCoreGuiEnabled(false)
            -- self:open()
            -- self:setState {selected = true}
            windowManager:SwitchWindow(WindowName)    
        end)
        -- :bindEvent("deselected", function()
        --     -- DisableBlur:Play()
        --     -- self:close()
        --     -- GUI:EnableAll()
        --     -- SetCoreGuiEnabled(true)
        --     -- IconManager.Controller.setTopbarEnabled(true)
        --     -- self:setState {selected = false}
            
        --     windowManager:SwitchWindow(nil, true)
        -- end)
        :autoDeselect(false)

        if props.Keybind then

            InputController:OnKeybindTrigger(props.Keybind, function()
                if self.state.selected then
                    windowManager:SwitchWindow()
                    --icon:deselect()
                else
                    windowManager:SwitchWindow(WindowName)
                end
            end)
        end

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

    function component:willUpdate(...)
        if window.willUpdate then
            window:willUpdate(...)
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
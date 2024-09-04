local util = {}

local ReplicatedStorage = game:GetService('ReplicatedStorage')
local TWS = game:GetService'TweenService'
local Tween = TweenInfo.new(0.15)

local Promise = require(game.ReplicatedStorage:WaitForChild"Utilities":WaitForChild"Promise")

local roactSpring = require(ReplicatedStorage.Packages.ReactSpring)
local roact = require(ReplicatedStorage.Utilities.Roact)

function util.useFadeEffect(visibleProp)
    local visible, setVisible = roact.useBinding(visibleProp)

    local styles, api = roactSpring.useSpring(function()
        return {
            transparency = if visibleProp then 0 else 1,
            config = { tension = 170, friction = 26 },
        }
    end)

    -- Update the spring whenever 'Visible' changes
    roact.useEffect(function()
        if visibleProp then
            setVisible(true)
        end
        api.start({
            transparency = if visibleProp then 0 else 1,
        }):andThenCall(setVisible, visibleProp)
        
    end, {visibleProp})

    return styles.transparency, visible
end

function util.CheckDisabledProperty(selfcomponent)
    local self = selfcomponent
    if self.props.Disabled then
        self:close()
    else
        if not self.icon then
            self:open()
        end
    end
end

function util.Initiate(self)
    local mainFrame = self.MainFrame:getValue()
    if self.props.Disabled then
        mainFrame.Visible =false
        mainFrame.GroupTransparency = 1
    end
end

function util.ImplementAnimatedOpenClose(component, config)

    config.CloseSizeScale = config.CloseSizeScale or 1.1

    function component:cancelClose()
        if self._activeClose then
           self._activeClose:cancel()
           self._activeClose = nil 
        end
    end
    
    function component:open()
        task.wait()
        self:cancelClose()
        local MainFrame = self.MainFrame:getValue()
        MainFrame.Visible = true
        MainFrame.GroupTransparency = 1
        TWS:Create(MainFrame, Tween, {
            GroupTransparency = 0,
            Size = config.Size,
        }):Play()
        self.Visible = true
    end

    function component:close()
        self:cancelClose()
        local activeClose; activeClose = Promise.new(function(resolve)
            
            self.Visible = false
            local MainFrame = self.MainFrame:getValue()
            TWS:Create(MainFrame, Tween, {
                GroupTransparency = 1,
                Size = UDim2.fromScale(config.Size.X.Scale*config.CloseSizeScale,config.Size.Y.Scale*config.CloseSizeScale)
            }):Play()
            task.wait(Tween.Time)
            MainFrame.Visible = false
            if self._activeClose == activeClose then
                self._activeClose = nil
            end
            resolve()
        end)
        self._activeClose = activeClose
    end

end

util.Color = require(ReplicatedStorage.Utilities.Misc.ColorUtil)



return util

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

local Component = Map.Component

local Frame = Map.Frame

local trove = require(game.ReplicatedStorage:WaitForChild"Packages":WaitForChild"Trove")
local util = require(ReplicatedStorage:WaitForChild"Utilities":WaitForChild"Util")
local tweenInfo = TweenInfo.new(.7,Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

local Window = require(ReplicatedStorage.Utilities.GUI:WaitForChild"WindowManager")

local mapComponent = GUI.GetComponent('Map')
local player = game.Players.LocalPlayer

function Map:init()
    self:setState({enabled = false})
end

function Map:didUpdate(_,prevState)
    GUI.DisableScroll = self.state.selected
end
 
function Map:didMount()
    local handle: ScreenGui = self.props.Handle

    handle:GetPropertyChangedSignal('Enabled'):Connect(function()
        self:setState({enabled = handle.Enabled})
    end)
end

Frame
:disableListLayout()
:addElement(function(...)

    return GUI.newElement('BlankFrame', {}, {
        Map = Map.state.selected and GUI.newElement('Map', {           
            AllowMoving = true,
        })
    })
    
end)


return Component
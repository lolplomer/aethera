local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextLabel = require(script.Parent:WaitForChild"TextLabel")
local roact = require(game.ReplicatedStorage:WaitForChild('Utilities'):WaitForChild('Roact'))
local Stats = require(game.ReplicatedStorage:WaitForChild"GameModules":WaitForChild"Stats")
local scale = UDim2.fromScale

local Knit = require(ReplicatedStorage:WaitForChild('Packages'):WaitForChild('Knit'))
local GUI = Knit.GetController('GUI')

local popup = roact.PureComponent:extend('StatDetail')
local Formula = require(ReplicatedStorage:WaitForChild"Utilities":WaitForChild"Misc":WaitForChild"StatFormula")

function popup:createTextElement(text,color)
    local size = workspace.CurrentCamera.ViewportSize.Y * 0.03
    return GUI.newElement('TextLabel', {
        Text = `{text}`,
        TextXAlignment = 'Left',
        Size = UDim2.new(1,0,0,size),
        TextColor3 = color,
    })
end


function popup:render()
    local PlayerStats = Knit.GetController('PlayerReplicaController'):GetReplica(('PlayerStats'))

    local modifiers = {}

    local isPercentage = Stats[self.props.Stat].IsPercentage
    modifiers.BaseStats = self:createTextElement(`Base : {Formula.GetLabel(PlayerStats.BaseStats[self.props.Stat],isPercentage)}`)

    for modifierName, modifier in PlayerStats.Modifiers do
        local stat = modifier[self.props.Stat]
        if stat then
            local value = Formula.GetModifierValue(PlayerStats.BaseStats[self.props.Stat], stat.Multiplier, stat.Flat)
            local color = Color3.new(1,0,0)
            local sign = ""
            if value > 0 then
                sign ='+'
                color = Color3.new(0,1,0)
            end
            modifiers[modifierName] = self:createTextElement(`{modifierName} : {sign}{Formula.GetLabel(value,isPercentage)}`,color)
        end
    end

    local padding = UDim.new(0,10)
    modifiers.Padding = roact.createElement('UIPadding', {
        PaddingLeft = padding,
        PaddingBottom = padding,
        PaddingRight = padding,
        PaddingTop = padding
    })

    return roact.createFragment(modifiers)
end

return function(props)

    local statInfo = Stats[props.Stat]
    local stat = props.Stat
    if statInfo then
        stat = statInfo.Label
    end

    local value = props.Value
    if statInfo.IsPercentage then
        value = `{math.floor(value*100)}%`
    end

    return roact.createElement("Frame", {
        Size = props.Size or scale(1,0.09),
        BackgroundColor3 = Color3.new(),
        BackgroundTransparency = 0.9,
        LayoutOrder = statInfo.LayoutOrder,
        [roact.Event.MouseEnter] = function()
            GUI:CreatePopup(roact.createElement(popup,{Stat=props.Stat,}), "StatHover", {
                LayoutType = 'Follow', Size = UDim2.fromScale(0.15,0)
            })
        end,
        [roact.Event.MouseLeave] = function()
            GUI:ClosePopup('StatHover')
        end
    }, {
        Corner = roact.createElement("UICorner"),
        StatName = roact.createElement(TextLabel, {
            Size = scale(0.6,1),
            Text = `  {stat}`,
            TextXAlignment = 'Left'
        }),
        StatValue = roact.createElement(TextLabel, {
            Size = scale(0.4,1),
            Text = `{value}  `,
            TextXAlignment = 'Right',
            Position = scale(0.6,0)
        })
    })
end
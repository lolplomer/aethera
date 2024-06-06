local roact = require(game.ReplicatedStorage:WaitForChild('Utilities'):WaitForChild('Roact'))

local Level = roact.PureComponent:extend()
local Knit = require(game.ReplicatedStorage:WaitForChild('Packages'):WaitForChild('Knit'))

local PlayerStats = Knit.GetController('PlayerReplicaController'):GetReplica('PlayerStats')
local ReplicaData = Knit.GetController('PlayerDataController'):GetPlayerData()

local GUI = Knit.GetController('GUI')
local Formula = require(game.ReplicatedStorage:WaitForChild"Utilities":WaitForChild"Misc":WaitForChild"StatFormula")

local ratio = {0.7,0.3}

local trove = require(game.ReplicatedStorage:WaitForChild'Packages':WaitForChild'Trove')
local util = require(game.ReplicatedStorage:WaitForChild"Utilities":WaitForChild"Util")

function Level:init()
    self.Label = roact.createRef()
    self.Bar = roact.createRef()
    self.BarLabel = roact.createRef()

    self.cleaner = trove.new()
end

function Level:willUnmount()
    self.cleaner:Destroy()
end

function Level:update()
    local LevelLabel = self.Label:getValue()
    local Bar = self.Bar:getValue()
    local BarLabel = self.BarLabel:getValue()
    local Stats = ReplicaData.Stats

    local min,max = Formula.GetExpMinMax(Stats.Exp, Stats.Level)
    

    BarLabel.Visible = false
    LevelLabel.Text = `Level {math.floor(Stats.Level)} <font size="5" color="#9FA3A8">(Exp: {min}/{max})</font>`
    Bar.Size = UDim2.fromScale(min/max,1)

end

function Level:didMount()

    self.cleaner:Add(ReplicaData.Replica:ListenToRaw(function(_,path)
        if path[1]=='Stats' then
            self:update()
        end
    end))

    self:update()
end

function Level:didUpdate()
    self:update()
end

function Level:render()
    return GUI.newElement('BlankFrame', {}, {
        Level = GUI.newElement('TextLabel', {
            Text = 'Level',
            Size = UDim2.fromScale(1,ratio[1]),
            TextXAlignment = 'Left',
            ["ref"] = self.Label,
            RichText = true,
        }),
        Bar = GUI.newElement('Bar', {
            Position = UDim2.fromScale(0,1-ratio[2]),
            Size = UDim2.fromScale(1,ratio[2]),
            InnerBarColor = Color3.fromHex("D9D9D9"),
            BarColor = Color3.fromHex("E29B50"),
            StrokeSize = 0,
            BarRef = self.Bar,
            LabelRef = self.BarLabel,
            Progress = 0.5,
        })
    })
end

return Level
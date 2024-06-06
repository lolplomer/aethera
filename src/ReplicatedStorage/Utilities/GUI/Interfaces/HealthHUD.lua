local ReplicatedStorage = game:GetService("ReplicatedStorage")
local roact = require(game.ReplicatedStorage:WaitForChild('Utilities'):WaitForChild('Roact'))

local Knit = require(ReplicatedStorage:WaitForChild('Packages'):WaitForChild('Knit'))
local StatFormula = require(ReplicatedStorage.Utilities:WaitForChild"Misc":WaitForChild"StatFormula")

local player = game.Players.LocalPlayer

local PlayerReplica = Knit.GetController("PlayerReplicaController")
local GUI = Knit.GetController "GUI"

local HUD = roact.PureComponent:extend("HealthHUD")

local FrameManager = require(ReplicatedStorage.Utilities:WaitForChild("GUI"):WaitForChild"FrameManager")
local GUIUtil = require(script.Parent.Parent:WaitForChild"GUIUtil")

local scale = UDim2.fromScale 
local HUDFrame = FrameManager.new(scale(1,1))

local StateReplica = PlayerReplica:GetReplica("PlayerState")
local StatsReplica = PlayerReplica:GetReplica("PlayerStats")
local DataReplica = Knit.GetController("PlayerDataController"):GetPlayerData()

local Colors = {
    Base = Color3.fromHex("D9D9D9"),
    InnerHealth = Color3.fromHex("435950"),
    OuterHealth = Color3.fromHex("599B80"),
    InnerMP = Color3.fromHex("1C486F"),
    OuterMP = Color3.fromHex("3387D1"),
    Level = Color3.fromHex("A6AEC1"),
    InnerExp = Color3.fromHex("81592F"),
    OuterExp = Color3.fromHex("E29B50")
}

local function Ratio(Ratio)
    return roact.createElement("UIAspectRatioConstraint", {
        AspectRatio = Ratio
    })
end

local function GetHumanoid()
    local character = player.Character
    if character then
        return character:WaitForChild"Humanoid"
    end
end

HUDFrame
:setOffset(-2)
:vertical()
:center()
:addElement(function(i, component)
    return GUI.newElement("Bar", {
        layoutOrder = i,
        StrokeSizeY = 8,
        StrokeSizeX = 9,
        StrokeColor = Colors.Base,
        Size = scale(0.8,0.28),
        BarColor = Colors.OuterMP,
        InnerBarColor = Colors.InnerMP,
        Label = "MP",
        Progress = StateReplica.MP,
        MaxProgress = StatsReplica.FullStats.MP,
        CornerRadius = UDim.new(0,5),
        BarCornerRadius = UDim.new(0.5,0),
        Ref = component.MP,
    })
end)
:addFrame({0.4}, function(healthMainFrame)
    healthMainFrame
    :center()
    :horizontal()
    :setOffset(-1)
    :addElement(function(i)
        return roact.createElement("ImageLabel", {
            Image = "rbxassetid://13858834570",
            Size = scale(0.05,1.9),
            LayoutOrder = i,
            BackgroundTransparency = 1,
        }, {Ratio = Ratio(23.77/87)})
    end)
    :addElement(function(i, component)
        local humanoid = GetHumanoid()
        local health, max = 0,0
        if humanoid then
            health, max = humanoid.Health, humanoid.MaxHealth
        end
        return GUI.newElement("Bar", {
            LayoutOrder = i,
            StrokeSizeY = 6,
            StrokeSizeX = 0,
            StrokeColor = Colors.Base,
            Size = scale(0.9,1),
            BarColor = Colors.OuterHealth,
            InnerBarColor = Colors.InnerHealth,
            Label = "HP",
            Progress = health,
            MaxProgress = max,
            CornerRadius = UDim.new(),
            Ref = component.HP,
        }, {
            RightDecor = roact.createElement("ImageLabel", {
                Image = "rbxassetid://13859448227",
                Size = scale(0.02,1.7),
                Position = scale(0.99,0.5),
                AnchorPoint = Vector2.new(1,0.5),
                BackgroundTransparency = 1.
            }),--, {Ratio = Ratio(9/82)}),
            LeftDecor = roact.createElement("ImageLabel", {
                Image = "rbxassetid://13859448227",
                Size = scale(0.02,1.7),
                Rotation = 180,
                Position = scale(0.03,0.5),
                AnchorPoint = Vector2.new(1,0.5),
                BackgroundTransparency = 1.
            })--, {Ratio = Ratio(9/82)})
        })

    end)
    :addElement(function(i)
        return roact.createElement("ImageLabel", {
            Image = "rbxassetid://13858834348",
            Size = scale(0.05,1.9),
            LayoutOrder = i,
            BackgroundTransparency = 1,
        }, {Ratio = Ratio(23.77/87)})
    end)
end)

:div(0.1) 
:addFrame({0.2}, function(expMainFrame)

    expMainFrame
    :horizontal()
    :center()
    :split({0.11,0.71}, function(levelFrame, expFrame)
        levelFrame
        :addBackground{Padding=0, CornerRadius=UDim.new(0.5,0)}
        :addElement(function(i, component)
            return GUI.newElement("TextLabel", {
                Size = scale(1,1),
                Text = `Lv. {StatsReplica.Level}`,
                layoutOrder = i,
                ["ref"] = component.Lvl
            })
        end)

        expFrame
        :addElement(function(i, component)
            local Current, Next = component:GetExpMinMax()

            return GUI.newElement("Bar", {
                layoutOrder = i,
                StrokeSize = 5,
                StrokeColor = Colors.Base,
                Size = scale(1,1),
                BarColor = Colors.OuterExp,
                InnerBarColor = Colors.InnerExp,
                Label = "EXP",
                Progress = Current,
                MaxProgress = Next,
                CornerRadius = UDim.new(0.5,0),
                Ref = component.Exp
            })
        end)
    end)
end)

GUIUtil.ImplementAnimatedOpenClose(HUD, {
    CloseSizeScale = 1,
    Size = scale(0.4,0.4) 
})

function HUD:init()
    self.HP = roact.createRef()
    self.MP = roact.createRef()
    self.Exp = roact.createRef()
    self.Lvl = roact.createRef()
    self.MainFrame = roact.createRef()
end

function HUD:didUpdate(prevProps)
    GUIUtil.CheckDisabledProperty(self, prevProps)
end

function HUD:render()
    return roact.createElement('ScreenGui', {
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    }, {
        MainFrame = roact.createElement('CanvasGroup', {
            BackgroundTransparency = 1,
            Size = scale(0.4,0.4),
            AnchorPoint = Vector2.new(0.5,1),
            Position = scale(0.5,0.97),
            ["ref"] = self.MainFrame
        }, {
            Ratio = Ratio(666.77/90),
            Children = HUDFrame:render(1, self)
        })
    })
end

function HUD:GetExpMinMax()
    local Value = DataReplica.Stats.Exp
    local Level = math.floor(DataReplica.Stats.Level)

    local Now = StatFormula.GetExp(Level)
    local Current = Value - Now
    local Next = StatFormula.GetExp(Level + 1) - Now
    
    return math.round(Current), math.round(Next)
end

function HUD:EXPLevelChanged()
    local ExpBar = self.Exp:getValue()
    local Level = math.floor(DataReplica.Stats.Level)

    local Current, Next = self:GetExpMinMax()

    GUI.Tween(ExpBar.Bar, {Size = scale(math.min(Current/Next,1),1)}) 
    ExpBar.Label.Text = `EXP: {Current}/{Next}`

    local LvlBar = self.Lvl:getValue()
    LvlBar.Text = `Lv. {Level}`
end

function HUD:MPChanged()
    local MPBar = self.MP:getValue()
    local Value = math.round(StateReplica.MP)
    local Max = math.round(StatsReplica.FullStats.MP)

    GUI.Tween(MPBar.Bar, {Size = scale(math.min(Value/Max,1),1)}) 
    MPBar.Label.Text = `MP: {Value}/{Max}`
end

function HUD:HPChanged()
   local humanoid = GetHumanoid()
   local health = humanoid.Health
   local maxhealth = humanoid.MaxHealth

   local HPBar = self.HP:getValue()
   GUI.Tween(HPBar.Bar, {Size = scale(health/maxhealth,1)})
   HPBar.Label.Text = `HP: {health}/{maxhealth}`
end

function HUD:didMount()

    local function ExpLevelChanged()
        self:EXPLevelChanged()
    end
    local function MPChanged()
        self:MPChanged()    
    end
    local function onCharacterAdded(character: Model)
        local humanoid: Humanoid = character:WaitForChild("Humanoid")
        self.HealthChanged = humanoid.HealthChanged:Connect(function()
            self:HPChanged()
        end)
        self:HPChanged()
    end

    onCharacterAdded(player.Character or player.CharacterAdded:Wait())
    self.CharacterAdded = player.CharacterAdded:Connect(onCharacterAdded)

    self.EXPChange = DataReplica.Replica:ListenToChange({"Stats","Exp"}, ExpLevelChanged)
    self.LevelChange = DataReplica.Replica:ListenToChange({'Stats',"Level"}, ExpLevelChanged)
    self.MPChange = StateReplica.Replica:ListenToChange({"MP"}, MPChanged)
    self.MaxMPChange = StatsReplica.Replica:ListenToChange({'FullStats','MP'}, MPChanged)
end

return HUD
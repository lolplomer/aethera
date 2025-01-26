local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local GUI = Knit.GetController('GUI')
local MobClient = Knit.GetController('MobClient')
local StatsClient = Knit.GetController('StatsClient')

local PlayerReplicaController = Knit.GetController('PlayerReplicaController')

local Roact = require(ReplicatedStorage.Utilities.Roact)
local Trove = require(ReplicatedStorage.Packages.Trove)
local ReactSpring = require(ReplicatedStorage.Packages.ReactSpring)

local BarImage = 'rbxassetid://18104254397'



return function (props)


    local char = props.Character
    local humanoid: Humanoid = char:WaitForChild"Humanoid"

    local styles, api = ReactSpring.useTrail(2, function(index)
        return {
            health = humanoid.Health/humanoid.MaxHealth - ((index-1)*0.02),
            
            delay = 3,
            config = {
                tension = 250/index,
                friction = 30,
                damping = 0.7,
            }
        }
    end) 

    local transparency, transparencyApi = ReactSpring.useSpring(function()
        return {alpha = 0}
    end)

    -- local playerStats
    -- if CollectionService:HasTag(char.HumanoidRootPart, 'Mob') then
    --     playerStats = MobClient:GetMob(char):GetStats()
    -- else
    --     local player = game.Players:GetPlayerFromCharacter(char)
    --     if player then
    --         playerStats = PlayerReplicaController:GetReplica('PlayerStats', player, 1)
    --     end
    -- end

    --print(char,'stats:',playerStats)
    --local level, setLevel = Roact.useBinding(playerStats and playerStats.Level or 'N/A')

    local level, setLevel = Roact.useBinding(char:GetAttribute('Level') or 'N/A')

    Roact.useEffect(function()
        local conn = Trove.new()

        conn:Connect(humanoid.HealthChanged, function(health)
            if health <= 0 then
                transparencyApi.start {alpha = 1}
            end
            api.start (function()
                return {
                    from =  {transparency = 0},
                    to = {transparency = 1, health = health/humanoid.MaxHealth}
                }
            end)
        end)



        -- if playerStats then
        --     local wrapper = StatsClient.GetWrapper(playerStats)    

        --     conn:Connect(wrapper.LevelChanged, function(level)
        --         setLevel(level)
        --     end)
        -- end

        char:GetAttributeChangedSignal('Level'):Connect(function()
            setLevel(char:GetAttribute('Level'))
        end)
        

        return conn:WrapClean()
    end)

    return Roact.createElement('CanvasGroup', {
        Size = UDim2.fromScale(1,1),
        BackgroundTransparency = 1,
        GroupTransparency = transparency.alpha
    }, {

        Label = GUI.newElement('TextLabel', {
            Size = UDim2.fromScale(1,.5),
            Text = level:map(function(value)
                return `<b><font size="8">Lv.{value}</font></b>  {props.Character.Name}  <font size="6" color="rgb(230,230,230)">《 Newbie 》</font>`
            end),
            TextScaled = true,
            RichText = true,
            TextXAlignment = 'Left',
            TextStrokeTransparency = 0.6,
        }),

        Bar = Roact.createElement('ImageLabel', {
            Size = UDim2.fromScale(1,0.5),
            Position = UDim2.fromScale(0,0.5),
            BackgroundTransparency = 1,
            Image = BarImage,
        }, {
            Bar = GUI.newElement('ImageBar', {
                Value = styles[1].health,
                Size = UDim2.fromScale(1,1),
                Image = BarImage,
                ImageColor3 = Color3.fromHex('8AFF88'),
                ZIndex = 2,
            }),
            Label = GUI.newElement('TextLabel', {
                Text = styles[1].health:map(function(value)
                    return `{math.floor(value * humanoid.MaxHealth)}/{humanoid.MaxHealth}`
                end),
                Size = UDim2.fromScale(.5,1.05),
                Position = UDim2.fromScale(0.03,.5),
                AnchorPoint = Vector2.new(0,.5),
                TextStrokeTransparency = 0.6,
                ZIndex = 3,
               -- TextColor3 = Color3.new(),
                TextXAlignment = 'Left'
            }),
            DiffBar = GUI.newElement('ImageBar', {
                Value = styles[2].health,
                Size = UDim2.fromScale(1,1),
                ImageTransparency = styles[2].transparency,
                Image = BarImage,
                ImageColor3 = Color3.new(1, 0.278431, 0.278431)   ,
                ZIndex = 1,
            }),
            Ratio = Roact.createElement('UIAspectRatioConstraint', {AspectRatio = 230/20})
        }),
       
    })
end
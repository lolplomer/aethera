local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local roactStory = require(ReplicatedStorage.Utilities.RoactStory)
local roact = require(ReplicatedStorage.Utilities.Roact)
local roactSpring = require(ReplicatedStorage.Packages.ReactSpring)
local Util = require(ReplicatedStorage.Utilities.Util)

local create = roact.createElement

local Elements = ReplicatedStorage.Utilities.GUI.Theme.Default.Elements
local TextLabel = require(Elements.TextLabel)

local controller = require(script.Parent)

local component = function()

    local enabled = controller.Enabled

    local mainRef = roact.useRef()
    local transparency, t_api = roactSpring.useSpring(function()
        return {
            value = enabled and 1 or 0,
            config = {
                duration = 0.25
            }
        };
    end)

    local animation, api = roactSpring.useSpring(function()
        return {
            alpha = 0,

            config = {
                duration = 2
            }
        }
    end)

    local update = roact.useCallback(function()
        enabled = controller.Enabled

        if enabled then
            api.start{
                from = {alpha = 0},
                to = {alpha = 1},
                loop = true,
            }
            mainRef.current.Visible = true
            t_api.start{value = 0}
        else
            t_api.start({value = 1}):andThen(function()
                mainRef.current.Visible = false
                api.stop() 
            end)
        end

    end)

    roact.useEffect(function()

        update()

        local connection = controller.Changed:Connect(update)

        return function ()
            connection:Disconnect()
            api.stop()
        end
    end)

    return create("CanvasGroup", {
        Size = UDim2.fromScale(1,1),
        BackgroundColor3 = Color3.fromHex("E9EBF8"),
        GroupTransparency = transparency.value,
        ref = mainRef


    }, {

        Logo = create("ImageLabel", {
            AnchorPoint = Vector2.new(.5,.5),
            Position = UDim2.fromScale(0.5,0.5),
            Size = UDim2.fromScale(0.2,0.2),
            BackgroundTransparency = 1,
            Image = "rbxassetid://121181862099488",
            ImageColor3 = animation.alpha:map(function(alpha)
                return Color3.fromHex("C6CBDC"):Lerp(Color3.fromHex("B8C4E9"), math.sin(math.rad(alpha * 360)/2))
            end),
        }, {
            create("UIAspectRatioConstraint", {AspectRatio = 345/128})
        }),

        
        Div = create("ImageLabel", {
            AnchorPoint = Vector2.new(.5,1),
            Position = UDim2.fromScale(0.5,.77),
            Size = UDim2.fromScale(0.9,0.2),
            BackgroundTransparency = 1,
            Image = "rbxassetid://82394832713092",
            ImageColor3 = Color3.fromHex("B4B8C5"),
        }, {
            create("UIAspectRatioConstraint", {AspectRatio = 1606/23})
        }),

        Hint = create(TextLabel, {
            Size = UDim2.fromScale(0.65,0.16),
            AnchorPoint = Vector2.new(0.5,1),
            TextScaled = false,
            TextScale = .033,
            Position = UDim2.fromScale(0.5,0.95),
            TextColor3 = Color3.fromHex("587291"),
            Text = "Defeating mobs can earn you some exp"
        }),

        LoadingCircle = create("ImageLabel", {
            Rotation = animation.alpha:map(function(alpha)
                return alpha * 360
            end), 
            Size = UDim2.fromScale(0.1,0.1),
            AnchorPoint = Vector2.new(1,1),
            Position = UDim2.fromScale(0.96,1-0.23/4),
            Image = "rbxassetid://120970218662660",
            BackgroundTransparency = 1,
            ImageColor3 = Color3.fromHex("587291")
        }, {
            create('UIAspectRatioConstraint')
        })

    })



end

return {
    Component = component,
    Handle = function(name)
        return Util.new("ScreenGui", {
            IgnoreGuiInset = true,
            ResetOnSpawn = false,
            ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
            DisplayOrder = 10000,
            Name = name,
            Parent = Players.LocalPlayer.PlayerGui
        })
    end
}
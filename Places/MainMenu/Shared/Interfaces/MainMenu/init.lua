local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GroupService = game:GetService('GroupService')
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local roact = require(ReplicatedStorage.Utilities.Roact)
local roactSpring = require(ReplicatedStorage.Packages.ReactSpring)
local elements = ReplicatedStorage.Utilities.GUI.Theme.Default.Elements
local TextLabel = require(elements.TextLabel)
local promise = require(ReplicatedStorage.Utilities.Promise)
local Knit = require(ReplicatedStorage.Packages.Knit)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Util = require(ReplicatedStorage.Utilities.GUI.GUIUtil)

local MainMenuController = Knit.GetController("MainMenuController")
local GUI = Knit.GetController('GUI')

local sleep = promise.promisify(task.wait)

local Customization = require(script.Customization)

local group = {
    data = nil,
    emblem = nil,
    id = 7154107
}

local VisibleBackButton = {
    Customization = true
}

group.data = promise.new(function(resolve)
    local data = GroupService:GetGroupInfoAsync(group.id)
    group.emblem = data.EmblemUrl
    resolve(data)
end)


local function Notice(text, blink)
    GUI:CreatePopup('MainMenu', roact.createElement(TextLabel,{Text = text, Blinking = blink}))
end

local function Dismiss()
    GUI:ClosePopup('MainMenu')
end
local function Square(props)
    return roact.createElement('Frame', {
        Size = UDim2.fromScale(1,1),
        BackgroundColor3 = Color3.new(1,1,1),
        AnchorPoint = Vector2.new(0.5,0.5),
        Position = UDim2.fromScale(.5,.5),
        Transparency = 1
    }, {
        Aspect = roact.createElement('UIAspectRatioConstraint'),
        roact.createElement(roact.Fragment, nil, props.children)
    })
end

local function Background()
    local effect = roactSpring.useSpring(function()
        return {
            from = {gradient = 0},
            to = {gradient = 360},
            config = {
                
                duration = 25
            },
            loop = true
        }
    end)

    return roact.createElement('Frame', {
        Size = UDim2.fromScale(1,1),
        BackgroundColor3 = Color3.new(.2,.2,.2),
        AnchorPoint = Vector2.new(0.5,0.5),
        Position = UDim2.fromScale(0.5,0.5),
        ZIndex = 0
    }, {
        Gradient = roact.createElement('UIGradient', {
            Color = ColorSequence.new(Color3.new(.2,.2,.2)),
            Transparency = NumberSequence.new(0.4,1),
            Rotation = effect.gradient
        }),
    })

end

local function LoadingText(props)
  
    local dot, setDot = roact.useBinding('')

    local visible = roactSpring.useSpring({
        Transparency = props.Visible and 0 or 1
    })

    roact.useEffect(function()
        local done = false

        task.defer(function()
            local num = 0
            while not done do
                task.wait(.33)
                num = (num + 1) % 4
                setDot(string.rep('.',num))
            end
        end)

        if props.Visible then
            task.defer(function()
                group.data:await()
                task.wait(1)
    
                if props.doneLoading then
                    props.doneLoading()
                end
            end)
    
        end

        return function ()
            group.data:cancel()
            done = true
        end
        
    end)


    return roact.createElement(TextLabel, {
        Size = UDim2.fromScale(1,.05),
        TextScaled = true,
        TextTransparency = visible.Transparency,
        AnchorPoint = Vector2.new(0,0.5),
        Position = UDim2.fromScale(0,0.5),
        Text = dot:map(function(value)
            return "Loading" .. value
        end), 
    })
end


local function Logo(props)

    local visible = props.Visible
    
    local style = roactSpring.useSpring({
        transparency = visible and 0 or 1, 
        delay = visible and 1.4 or 0
    })


    roact.useEffect(function()
        if visible and props.doneLoading then
            local wait = sleep(3):andThenCall(props.doneLoading)

            return function ()
                wait:cancel()
            end
        end
    end)

    return  roact.createElement('ImageLabel', {
        Size =props.Size or UDim2.fromScale(0.3,0.3),
        AnchorPoint = Vector2.new(0.5,0.5),
        Position = UDim2.fromScale(0.5,0.5),
        BackgroundTransparency = 1,
        ScaleType = Enum.ScaleType.Fit,
        Image = props.Image or 'rbxasset://textures/ui/GuiImagePlaceholder.png',
        ImageTransparency = style.transparency
    }) 
end

local function MenuButton(props)
    --local Size = TextService:GetTextSize('Size')
    local current = workspace.CurrentCamera.ViewportSize
    local a = 1
    local scale = current/ Vector2.new(1619 * a, 815 * a)

    local size = {
        wing = Vector2.new(35.44,79) * scale,
        offset = Vector2.new(15,15) * scale,
        grad = Vector2.new(65,65) * scale,
        text = 40 * scale.Magnitude
    }

    props.Text = props.Text or 'Text'

    local style, api = roactSpring.useSpring(function()
        return {gradient = 1, offset = 0}
    end)

    return roact.createElement('Frame', {
        Size = props.Size or UDim2.new(.3,0,0.2,0),
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(0.5,0),
        Position = props.Position,
        
      --  AutomaticSize = Enum.AutomaticSize.X,
        [roact.Event.MouseEnter] = function()
            api.start{gradient = .5, offset = 0.3, config = {tension = 300}}
        end,
        [roact.Event.MouseLeave] = function()
            api.start{gradient = 1, offset = 0}
        end,
    }, {

        Button = roact.createElement('ImageButton', {
            Transparency = 1,
            Size = UDim2.fromScale(1,1),
            [roact.Event.MouseButton1Up] = function()
                api.start{gradient = .5}
            end,
            [roact.Event.MouseButton1Down] = function()
                api.start{gradient = 0,config = {tension = 300, mass = 0.5}}
            end,
            [roact.Event.Activated] = props.Callback
        }),

        LeftWing = roact.createElement('ImageLabel', {
            Image = 'rbxassetid://82356511994907',
            BackgroundTransparency = 1,
            Size = UDim2.new(0,size.wing.X,1,0),
            Position = style.offset:map(function(value)
                return UDim2.new(-value,-size.offset.X,0.5,0)
            end),
            ScaleType = Enum.ScaleType.Fit,
            AnchorPoint = Vector2.new(1,0.5),
            SizeConstraint = Enum.SizeConstraint.RelativeYY,
            ZIndex = 2
        }, {
            --roact.createElement('UIAspectRatioConstraint',{AspectRatio = 0.506285714})
        }),
        RightWing = roact.createElement('ImageLabel', {
            Image = 'rbxassetid://82467923791976',
            BackgroundTransparency = 1,
            Size = UDim2.new(0,size.wing.X,1,0),
            AnchorPoint = Vector2.new(0,0.5),
            ScaleType = Enum.ScaleType.Fit,
            Position = style.offset:map(function(value)
                return UDim2.new(1 + value,size.offset.X,0.5,0)
            end),
            ZIndex = 2
        }, {
            --roact.createElement('UIAspectRatioConstraint',{AspectRatio = 0.506285714})
        }),
        Grad = roact.createElement('ImageLabel', {
            Image = "rbxassetid://105505012353415",
            BackgroundTransparency = 1, 
            Size = style.offset:map(function(value)
                return UDim2.new(1.2 + value,size.wing.X*2+size.offset.X ,0,size.grad.Y)
            end),
            Position = UDim2.new(0.5,0,1,0),
            AnchorPoint = Vector2.new(0.5,1),   
            ImageTransparency = style.gradient,
        }), 

        Text = roact.createElement(TextLabel, {
            Text = props.Text,
            --TextSize = size.text,
            TextScaled = true,
            AutomaticSize = Enum.AutomaticSize.X,
            TextXAlignment = 'Center'
        })
        
    })
end

local function Back(props)

    local transparency, visible = Util.useFadeEffect(props.Visible)


    return roact.createElement('CanvasGroup', {
        Size = UDim2.fromScale(1,1),
        BackgroundTransparency = 1,
        GroupTransparency = transparency,
        Visible = visible
    }, {
        roact.createElement('UIPadding', {
            PaddingLeft = UDim.new(0,10),
            PaddingTop = UDim.new(0,10),
            PaddingRight = UDim.new(0,10),
            PaddingBottom = UDim.new(0,10),
        }),

        roact.createElement(TextLabel, {
            TextButton = true,

            Size = UDim2.fromScale(.2,.05),
            Position = UDim2.fromScale(0,0.07),

            Text = `Back to Main Menu`,

            [roact.Event.Activated] = function()
                props.Scene('End')
            end
        })
        
    })    
end

local function Menu(props)

    --local movement, setMovement = roact.useBinding(workspace.CurrentCamera.ViewportSize/2)

    local transparency, visible = Util.useFadeEffect(props.Visible)

    local style, api = roactSpring.useSpring(function()
        return {
            move = Vector2.zero,
        }
    end)

    local buttonProps = {}
    local length = 3
    for i = 1,length do
        table.insert(buttonProps, {
            from = {value = 1},
            to = {value = 0},
            delay = 2 + (0.5 * (i-1))
        })
    end


    local button = roactSpring.useSprings(length, buttonProps)

    roact.useEffect(function()

        local Conn = RunService.Heartbeat:Connect(function()
            local camera = workspace.CurrentCamera
            local viewport: Vector2 = camera.ViewportSize
            local center: Vector2 = viewport/2
            local mouse: Vector2 = UserInputService:GetMouseLocation()
            local unit = (mouse - center)/center

            local move = unit-- + Vector2.new(math.cos(os.clock()*3),math.sin(os.clock()*3)) * 3
           -- print(move)
            
           api.start {move = move}

        end)

        return function ()
            Conn:Disconnect()
        end
    end)
 
    return roact.createElement('CanvasGroup', {
        Size = UDim2.fromScale(1,1),
        BackgroundTransparency = 1,
        GroupTransparency = transparency,
        Visible = visible,
        AnchorPoint = Vector2.new(0.5,0.5),
        Position = UDim2.fromScale(.5,.5),    
        ZIndex = 1,
    }, {
        List = roact.createElement('Frame', {
            Size = UDim2.fromScale(0.4,0.4),
            ClipsDescendants = true,
            Position = style.move:map(function(v)
                return UDim2.new(0.5,-v.X * 15,1,-v.Y * 15)
            end),
            AnchorPoint = Vector2.new(0.5,1),
            Transparency = 1,
        }, {
            -- roact.createElement('UIListLayout', {
            --     Padding = UDim.new(0.1,0),
            --     HorizontalAlignment = Enum.HorizontalAlignment.Center,
            -- }),
            roact.createElement(MenuButton, {
                Text = 'Play',
                Position = button[2].value:map(function(value)
                    return UDim2.fromScale(0.5 + value, 0) 
                end),
                Callback = function()
                    props.Scene('Play')
                end
            }) ,

            roact.createElement(MenuButton, {
                Text = 'Options',
                Position = button[3].value:map(function(value)
                    return UDim2.fromScale(0.5 + value, 0.25) 
                end),
                Callback = function()
                    Notice('Coming soon!')
                end
            }) ,

            --roact.createElement(MenuButton, {Text = 'Options'})
        }),

        Logo = roact.createElement('ImageLabel', {
            Size = UDim2.fromScale(1,0.3),
            AnchorPoint = Vector2.new(0.5,0),
            Position =  roact.joinBindings({v = style.move, b = button[1].value}):map(function(bind)
                
                return UDim2.new(0.5,bind.v.X * 10,0.1 - bind.b * 0.5,bind.v.Y * 10)
            end),
            ScaleType = Enum.ScaleType.Fit,
            Image = "rbxassetid://102118295578077",
            BackgroundTransparency = 1
        })
    }) 
end


local function Main()

    local scene, setScene = roact.useState('Loading')

    local style, api = roactSpring.useSpring(function()
        return {loading = 0}
    end)

    warn('Scene:', scene)

    roact.useEffect(function()
        local trove = Trove.new()

        if scene == 'End' then
            api.start {loading = 1, delay = 1}

            MainMenuController:SwitchCamera('MainCameraPart')

        elseif scene == 'Customization' then

            local wait;wait = trove:AddPromise(sleep(.3)):andThen(function()
                trove:Remove(wait)
                MainMenuController:SwitchCamera('Customization')
            end)

        elseif scene == 'Play' then

            Notice("Checking Player Data...", true)
            
            trove:AddPromise(promise.new(function()
                task.wait(3)
                Dismiss()
                setScene('Customization')
            end))

        end

        return trove:WrapClean()
    end)



    return roact.createElement(roact.Fragment, nil, {
        loading = roact.createElement('CanvasGroup', {
            Size = UDim2.fromScale(1,1),
            BackgroundColor3 = Color3.new(.2,.2,.2),
            AnchorPoint = Vector2.new(0.5,0.5),
            Position = UDim2.fromScale(0.5,0.5),
            GroupTransparency = style.loading,
            ZIndex = 2
        }, { 

            Background = roact.createElement(Background),
           
            Area = roact.createElement(Square, {}, {
                roact.createElement(LoadingText, {
                    doneLoading = function()
                        setScene(RunService:IsStudio() and 'End' or 'Group')
                end,
                    Visible = scene == 'Loading'
                }),
 
                roact.createElement(Logo, {
                    Image = group.emblem,
                    Visible = scene == 'Group',
                    doneLoading = function()
                        setScene('GameIcon')
                    end
                }),

                roact.createElement(Logo, {
                    Image = 'rbxassetid://106849333406148',
                    Visible = scene == 'GameIcon',
                    doneLoading = function()
                        setScene('End')
                    end,
                    Size = UDim2.fromScale(0.3,0.3),
                })
               
            }) 
            --Aspect = roact.createElement('UIAspectRatioConstraint')
        }),

        menu = roact.createElement(Menu, {
            Scene = setScene,
            Visible = scene == 'End'
        }),

        back = roact.createElement(Back, {
            Scene = setScene,
            Visible = VisibleBackButton[scene],
        }),

        customization = roact.createElement(Customization, {
            Visible = scene == 'Customization'
        })
    })
    
end

return {
    Component = Main,
   -- Disabled = true
}
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local RunService = game:GetService('RunService')
local roact = require(ReplicatedStorage.Utilities.Roact)
local knit = require(ReplicatedStorage.Packages.Knit)
local GUI = knit.GetController('GUI')
local PassiveClient = knit.GetController('PassiveClient')
local PassiveModule = require(ReplicatedStorage.GameModules.Passives)
local util = require(ReplicatedStorage.Utilities.Util)

local function ComponentPassiveStack(props)

    local time, setTime = roact.useBinding(props.stack.TimeEnd - os.clock())
    
    roact.useEffect(function()
        local conn = RunService.RenderStepped:Connect(function()
            setTime(props.stack.TimeEnd - os.clock())
        end)

        return function ()
            conn:Disconnect()
        end
    end, {time})

    return roact.createElement('Frame', {
        Size = UDim2.new(.85,0,0,props.size),
        BackgroundTransparency = 1,
        LayoutOrder = 3,
    }, {
        Id = GUI.newElement('TextLabel', {
            TextXAlignment = 'Left',
            Text = time:map(function(value)
                return `• {props.id} (Lv.{props.stack.Level}) ` .. ((value > 0) and `({util.SecondsToFormattedTime(value)})` or '')
            end),
            Size = UDim2.fromScale(1,1),
            TextColor3 = Color3.fromRGB(220,220,220)
        }),
    })
end

return function (props)

    local update, setUpdate = roact.useState(0)
    local passive =  PassiveModule.Passives[props.Passive] 
    local data = PassiveClient:GetPassive(props.Passive)
    local now = os.clock()
    local id, timeStart, timeEnd = 'None', now, now


    if data then
        id, timeStart, timeEnd = util.GetLongestActiveDuration(data)
        if not id then
            id, timeStart, timeEnd = 'None', now, now
        end
    end


    roact.useEffect(function()

        local conn = PassiveClient:ListenToPassiveChange(props.Passive, function()
            setUpdate(update + 1)
        end)

        return function ()
            GUI:ClosePopup('PassiveInfo'..props.Passive)
            conn:Disconnect()
        end
    end)

    return roact.createElement('Frame', {
        BackgroundTransparency = 0.5,
        BackgroundColor3 = Color3.new(),
        Size = props.Size or UDim2.fromScale(0.2,0.2),
        Position = props.Position,
        AnchorPoint = props.AnchorPoint,
        [roact.Event.MouseEnter] = function()
            task.wait()
            local res = workspace.CurrentCamera.ViewportSize.Y

            local size = {
                title = res * 0.04,
                description = res * 0.12,
                stack = res * 0.025
            }

            local list = {}

            for _id, stack in PassiveClient:GetPassive(props.Passive) do
                table.insert(list, roact.createElement(ComponentPassiveStack, {
                    id = _id,
                    stack = stack,
                    size = size.stack
                }))
            end

            GUI:CreatePopup('PassiveInfo'..props.Passive, roact.createElement(roact.Fragment, nil, {
                GUI.newElement('TextLabel', {
                    Text = PassiveClient:BuildName(props.Passive),
                    Size = UDim2.new(1,0,0,size.title),
                    RichText = true,
                    LayoutOrder = 1,
                }),
                GUI.newElement('TextLabel', {
                    LayoutOrder = 2,
                    Text = PassiveClient:BuildDescription(props.Passive),
                    Size = UDim2.new(1,0,0,0),
                    AutomaticSize = 'Y',
                    TextScale = 0.02,
                    TextColor3 = Color3.fromRGB(200,200,200),
                    TextScaled = false,
                    TextYAlignment = 'Top',
                    RichText = true,
                }),
                roact.createElement(roact.Fragment, nil, list)
            }), {
                LayoutType = 'Follow',
                Size = UDim2.new(0.15,0,0.1,0)
            })
        end,
        [roact.Event.MouseLeave] = function()
            
           GUI:ClosePopup('PassiveInfo'..props.Passive)
        end
    }, {
        Ratio = roact.createElement('UIAspectRatioConstraint'),
        Corner = roact.createElement('UICorner', {CornerRadius = UDim.new(1,0)}),
        Progress = GUI.newElement('RadialBar', {
            Size = UDim2.fromScale(1,1),
            Time = {Start = timeStart, End = timeEnd},
            Color = Color3.new(1,1,1)
        }),
        Icon = passive and roact.createElement('ImageLabel', {
            AnchorPoint = Vector2.new(0.5,0.5),
            Position = UDim2.fromScale(0.5,0.5),
            Size = UDim2.fromScale(0.6,0.6),
            BackgroundTransparency = 1,
            Image = passive.Icon or ""
        })
    })
end
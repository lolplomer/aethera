
local GUIUtil = game.ReplicatedStorage:WaitForChild"Utilities":WaitForChild"GUI"
--local roact = require(game.ReplicatedStorage:WaitForChild"Utilities":WaitForChild"Roact")
local knit = require(game.ReplicatedStorage:WaitForChild"Packages":WaitForChild"Knit")


local GUI = knit.GetController"GUI"
local WindowManager = require(GUIUtil:WaitForChild"WindowManager")

local Window = WindowManager.new(script.Name, {DisableIcon = true})
local MasterFrame = Window.Frame

function Window:init()
   -- warn("Initializing window")
    Window:setState{Hello = 43}
    --print(Window.state, 'States')
end


MasterFrame
:vertical()
:split({0.3,0.7}, function(FrameA1, FrameA2)


    FrameA1
    :horizontal()
    :split({0.4,0.6}, function(FrameB1, FrameB2)

        FrameB1:addElement(function()
            return GUI.newElement("TextButton", {
                Text = Window.state.Hello,
                Size = UDim2.new(1,0,0.5,-10),
                UseGradient = false,
                Color = Color3.fromRGB(177, 65, 65),
                Callback = function()
                    --Window:setFrameTransparency(math.random())
                    local UI = 'HealthHUD'
                    local healthProps = GUI:GetProps(UI)
                    local disabled = not healthProps.Disabled
                    if disabled then
                        GUI:DisableUI(UI)
                    else
                        GUI:EnableUI(UI)
                    end
                end,
                LayoutOrder = 1,    
            })
        end):addElement(function()
            return GUI.newElement("TextLabel", {
                Text = "Sample text??",
                Size = UDim2.fromScale(1,0.5),
                LayoutOrder = 0
            })
        end)

        FrameB2:addElement(function()
            return GUI.newElement("Dropdown", {
                Size = UDim2.fromScale(0.5,0.5),
                Text = "Select Choices",
                Choices = {
                    {Text = "Hello1"},
                    {Text = "Hello2"},
                    {Text = "Yess"}
                }
            })
        end)
    end)


    FrameA2
    :horizontal()
    :split({0.5,0.5}, function(FrameB1, FrameB2)
        FrameB1:addElement(function()
            return GUI.newElement("TextLabel", {
                Text = "Oooomagaatt"
            })
        end)
        FrameB2:addElement(function()
            return GUI.newElement("TextButton", {
                Text = "Another test button",
                Color = Color3.fromRGB(75, 203, 90)
            })
        end)
    end)
end)

--Window.Component.Disabled = true

return Window.Component
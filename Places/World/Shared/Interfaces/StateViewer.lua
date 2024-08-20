local ReplicatedStorage = game:GetService("ReplicatedStorage")
local utility = ReplicatedStorage:WaitForChild'Utilities'
local GuiUtility = ReplicatedStorage:WaitForChild'Utilities':WaitForChild'GUI'
local guiutil = require(GuiUtility:WaitForChild"GUIUtil")
local roact = require(ReplicatedStorage:WaitForChild('Utilities'):WaitForChild('Roact'))
local Knit = require(ReplicatedStorage:WaitForChild('Packages'):WaitForChild('Knit'))

local GUI = Knit.GetController('GUI')
local CharacterController = Knit.GetController('CharacterController')

local viewer = roact.Component:extend('StateViewer')

guiutil.ImplementAnimatedOpenClose(viewer, {
    CloseSizeScale = 1,
    Size = UDim2.fromScale(1,1)
})


function viewer:init()
    self.MainFrame = roact.createRef()
    self.StateLabel = roact.createRef()
end

function viewer:updateText(state, index)
    local label = self.StateLabel:getValue()
    
   -- warn('STATEVIEWER REF ON UPDATED:',self.StateLabel,self.StateLabel.current)
    label.Text = `{state or 'None'} ({index or ''})`
end

function viewer:componentDidMount()
    self:updateText(CharacterController:GetState())
    CharacterController.StateChanged:Connect(function(state, index)
        self:updateText(state, index)
    end)
end

function viewer:didUpdate()
   -- warn('STATEVIEWER REF ON UPDATED:',self.StateLabel,self.StateLabel.current)
    guiutil.CheckDisabledProperty(self)
end

function viewer:render()
 --   print('Rendering viewer')
    return roact.createElement('CanvasGroup', {
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1,1),
        ref = self.MainFrame,
        Visible = not self.props.Disabled
    }, {
        StateLabel = GUI.newElement('TextLabel', {
            Position = UDim2.new(1,-20,0.5,0),
            AnchorPoint = Vector2.new(1,.5),
            Size = UDim2.fromScale(0.07,0.05),
            ref = self.StateLabel,
            BackgroundTransparency = 1,
            TextXAlignment = 'Right'
        })
    })
end

viewer.HUD = true

return viewer

local ReplicatedStorage = game.ReplicatedStorage
local Knit = require(ReplicatedStorage:WaitForChild('Packages'):WaitForChild('Knit'))

local roact = require(ReplicatedStorage:WaitForChild"Utilities":WaitForChild"Roact")

local directionConfig = {
    [Enum.FillDirection.Horizontal] = true,
    [Enum.FillDirection.Vertical] = true,
}

local Frame = {}
Frame.__index = Frame

local GUI = Knit.GetController"GUI"

function Frame.new(frameSize, Parent, Window)
    assert(typeof(frameSize) == 'UDim2', "frameSize must be UDim2")
    return setmetatable({
        Splitted = false,
        Direction = Enum.FillDirection.Vertical,
        Children = {},
        Size = frameSize,
        Parent = Parent,
        Window = Window,
        LayoutProperties = {},
        ScrollingAutomaticSize = nil,
        Offset = 10,
    }, Frame)
end

function Frame:render(LayoutOrder, props)

    local children = {}
    -- for i, descendingFrame in self.Frames do
    --     children[descendingFrame.Name or `Frame{i}`] = descendingFrame:render(i)
    -- end
    -- for i, elementMakerFn in self.Elements do
    --     children[`Element{i}`] = elementMakerFn()
    -- end
    local shouldRender = true
    if self.shouldRenderFn then
        shouldRender = self.shouldRenderFn(props)
    end
    if shouldRender then
        local indexOffset = 0
        for i, child in self.Children do
            i += indexOffset
            if typeof(child) == 'function' then
                local element, offset = child(i, props)
                if typeof(element) == 'function' then
                    element = roact.createElement(element, props)
                end
                children[`Element{i}`] = element
                indexOffset += (offset or 0)
            else
                children[child.Name or `Frame{i}`] = child:render(i, props)
            end
        end
    end

    --print('Frame Children:', children)


    local transparency = 1
    if self.Window then
        transparency = self.Window.state.FrameTransparency or 1
    end

    local LayoutProperties = {
        FillDirection = self.Direction,
        Padding = UDim.new(0,self.Offset),
        SortOrder = Enum.SortOrder.LayoutOrder
    }
    for property, value in self.LayoutProperties do
        LayoutProperties[property] = value
    end

    local size: UDim2 = self.Size
    local modifierSize: UDim2 = self._sizeModifier
    if modifierSize then
        size = UDim2.new(
            size.X.Scale * modifierSize.X.Scale,
            size.X.Offset + modifierSize.X.Offset,
            size.Y.Scale * modifierSize.Y.Scale,
            size.Y.Offset + modifierSize.Y.Offset
        )
    end
    local classFrame = "Frame"
    local frameProps = {
        Visible = shouldRender,
        BackgroundTransparency = self.Background and 0 or transparency,
        BackgroundColor3 = self.Background and (self.Background.Color or Color3.fromHex("587291")),
        Size = size,
        LayoutOrder = LayoutOrder or 0,
        Name = self.Name,
    }
    if self.ScrollingAutomaticSize then
        frameProps.CanvasSize = UDim2.new()
        frameProps.AutomaticCanvasSize = self.ScrollingAutomaticSize
        frameProps.ScrollBarThickness = 3
        frameProps.BorderSizePixel = 0

        classFrame = "ScrollingFrame"
    end

    return roact.createElement(classFrame, frameProps, {
        UIListLayout = not self.ListLayoutDisabled and roact.createElement("UIListLayout", LayoutProperties),
        UICorner = self.Background and roact.createElement("UICorner", {CornerRadius = self.Background.CornerRadius or UDim.new(0.09,0)}),
        Padding = self.Padding and roact.createElement('UIPadding', {
            PaddingBottom = UDim.new(0,self.Padding.Bottom or 0),
            PaddingLeft = UDim.new(0,self.Padding.Left or 0),
            PaddingRight = UDim.new(0,self.Padding.Right or 0),
            PaddingTop = UDim.new(0,self.Padding.Top or 0)
        }),
        --Children = roact.createElement(roact.Fragment, nil, children)
        Children = roact.createElement(roact.Fragment, nil, children)
    })
end

function Frame:shouldRender(conditionFn)
    self.shouldRenderFn = conditionFn
    return self
end

function Frame:addElement(elementMakerFn)
   -- assert(not self.Splitted, "Cannot add elements to splitted frame")

    table.insert(self.Children, elementMakerFn)
    return self
end
function Frame:addElementIf(conditionFn, children)
    local object = {
        Condition = conditionFn,
        children = children
    }
    table.insert(self.Children, object)
    return self
end

function Frame:disableListLayout()
    self.ListLayoutDisabled = true
    return self
end

function Frame:setDirection(direction)
    self.Direction = direction
    return self
end

function Frame:horizontal()
    self:setDirection(Enum.FillDirection.Horizontal)
    return self
end

function Frame:vertical()
    self:setDirection(Enum.FillDirection.Vertical)
    return self
end

function Frame:rename(newFrameName)
    self.Name = newFrameName
    return self
end

function Frame:enableScrolling(automaticSize)
    self.ScrollingAutomaticSize = automaticSize or "XY"
    self:padding {Right = 10}
    return self
end

function Frame:setLayoutProperties(properties)
    self.LayoutProperties = properties
    return self
end

function Frame:setOffset(newOffset)
    self.Offset = newOffset
    return self
end

function Frame:div(scale)
    self:addElement(function(order)
        local size = UDim2.fromScale(1,scale)
        if self.Direction == Enum.FillDirection.Horizontal then
            size = UDim2.fromScale(scale,1)
        end
        return roact.createElement("Frame", {
            BackgroundTransparency = 1,
            Size = size,
            LayoutOrder = order
        })
    end)
    return self
end

function Frame:center(direction)
    local properties
    if direction == "Horizontal" then
        properties = {HorizontalAlignment = 'Center'}
    elseif direction == 'Vertical' then
        properties = {VerticalAlignment = 'Center'}
    else
        properties = {
            HorizontalAlignment = "Center",
            VerticalAlignment = "Center"
        }
    end
    self:setLayoutProperties(properties)
    return self
end

function Frame:addBackground(background, returnFn)
    if typeof(background) == 'function' then
        returnFn = background
        background = nil
    end
    background = background or {}
    local padding = background.Padding or 10
    self.Background = background
    
    self
    :center()
    :setOffset(UDim2.new())

    local NewFrame = self:split({1}, nil, true)
    :setSize(UDim2.new(1,-padding,1,-padding))

    if returnFn then
        returnFn(NewFrame)
    end

    return NewFrame
end

function Frame:setSize(size)
    self._sizeModifier = size
    return self
end

function Frame:padding(size)
    self.Padding = size
    return self
end

function Frame:split(splitInfo, returnFn, returnFrame)
    local direction = self.Direction
    assert(not self.Splitted, "Frame is already splitted")
    assert(directionConfig[direction], `{direction} is not a valid split direction`)

    local frames = {}
    for _, frameSize in splitInfo do

        local Size
        if direction == Enum.FillDirection.Horizontal then
            Size = UDim2.new(frameSize, -self.Offset, 1, 0)
        else
            Size = UDim2.new(1, 0, frameSize, -self.Offset)
        end

        local newFrame = Frame.new(Size, self, self.Window)
        table.insert(self.Children, newFrame)
        table.insert(frames, newFrame)
    end
    self:setDirection(direction)
        
    if returnFn then
        returnFn(table.unpack(frames))
    end

    if returnFrame then
      return table.unpack(frames)
    end
    return self
end

function Frame:addText(fn_or_text, size, textsize)
    return self:addElement(function(layout, props)
        return GUI.newElement("TextLabel", {
            Text = typeof(fn_or_text) == 'function' and fn_or_text(props) or fn_or_text,
            LayoutOrder = layout,
            Size = size or UDim2.fromScale(1,0.1),
            TextScaled = type(textsize) == 'boolean' and textsize or nil,
            TextScale = type(textsize) == 'number' and textsize,
        })
    end)
end
Frame.addFrame = Frame.split

return Frame
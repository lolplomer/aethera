local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Models = {}

local Trove = require(ReplicatedStorage:WaitForChild"Packages":WaitForChild"Trove")

local HandlerClass = {}
HandlerClass.__index = HandlerClass

local ValueClass = {}
ValueClass.__index = ValueClass
ValueClass.__tostring = function(self)
    return self:GetValue()
end

local PriorityModule = {}


function HandlerClass:Destroy()
    self.Trove:Destroy()
end

function HandlerClass:Update(Property)
    local property = self.Values[Property]
    if property then
        for _, Value in property do
            self.Instance[Property] = Value:GetValue()
    --        print('New value of',Property,':',Value:GetValue(),'\nAll other values:',property)
            return
        end
        
        local DefaultValue = self.DefaultValues[Property]
    --    print("Default value",Property,DefaultValue,self.DefaultValues)
        if DefaultValue then
            self.Instance[Property] = DefaultValue
        end
    end
end

function HandlerClass:Add(Property, _value, Priority, Time)
    if not self.Values[Property] then
        self.Values[Property] = {}
    end
    if not self.DefaultValues[Property] then
        self.DefaultValues[Property] = _value
    end

    Priority = math.max(Priority or 1, 1)
    if not _value then
        error('Value cannot be empty')
    end
    
    local Value = ValueClass.new(self, Property, _value, Priority, Time)

    table.insert(self.Values[Property], Priority, Value)
    self:Update(Property)

    if tonumber(Time) then
        task.delay(Time, Value.Dispose, Value)
    end

    return Value
end

function HandlerClass:SetDefaultValue(property, value)
    self.DefaultValues[property] = value
end

function ValueClass.new(Handler, Property, Value, Priority, Time)
    return setmetatable({Handler,Property,Value,Priority,Time,true}, ValueClass)
end

function ValueClass:GetValue()
    return self[3]
end

function ValueClass:Set(value)
    if self[6] == false then return end

    self[3] = value
    self[1]:Update(self[2])

end

function ValueClass:Dispose()
    if self[6] == false then return end

    local handler, prop = self[1], self[2]

    for index, Value in handler.Values[prop] do
        if Value == self then
     --       print('Disposing Value index', index)
            handler.Values[prop][index] = nil
            self[6] = false
            break
        end
    end

    -- local index = table.find(handler.Values[prop], self)


    -- if index then
    --     table.remove(handler.Values[prop], index)
    --     self[6] = false
    -- end

    handler:Update(prop)
end

ValueClass.Destroy = ValueClass.Dispose

function PriorityModule:GetHandler(Instance: Instance)
    if not Models[Instance] then
        local Handler = setmetatable({
            Values = {},
            DefaultValues = {},
            Trove = Trove.new(),
            Instance = Instance,
        }, HandlerClass)

        Handler.Trove:Add(function()
            Models[Instance] = nil
        end)

        Handler.Trove:Connect(Instance.AncestryChanged, function(_, parent)
            if parent == nil then
                Handler:Destroy()
            end
        end)

        Models[Instance] = Handler
    end

    return Models[Instance]
end


function PriorityModule.Set(Instance, Property, Value, Priority, Time)
    local Handler = PriorityModule:GetHandler(Instance)

    return Handler:Add(Property, Value, Priority, Time)
end

return PriorityModule
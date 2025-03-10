local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Models = {}

local Trove = require(ReplicatedStorage:WaitForChild"Packages":WaitForChild"Trove")

local HandlerClass = {}
HandlerClass.__index = function(self, index)
    return rawget(self,"Methods")[index] or rawget(self, index) or HandlerClass[index]
end


local PropertyClass = {}
PropertyClass.__index = PropertyClass  

function PropertyClass:Get() 
    return self._instance.Instance[self._property]

end

function PropertyClass:Add(Value, Priority, Time)
    return self._instance:Add(self._property, Value, Priority, Time)
end

local ValueClass = {}
ValueClass.__index = ValueClass
ValueClass.__tostring = function(self)
    return self:GetValue()
end

local DISABLED_TWEEN_DATATYPES = {'boolean','Instance'}

local PriorityModule = {}

local function is_empty(t)
    for _ in t do
        return false
    end
    return true
end

function HandlerClass:Destroy()
    self.Trove:Destroy()
end

function HandlerClass:Reset(Property)
    for _, v in self.Values[Property] do
        v:Dispose()
    end
end

function HandlerClass:Update(Property)
    local property = self.Values[Property]
    if property then
        local v = self.DefaultValues[Property]
        
        if not is_empty(property) then
            local i = 1
            local _v
            while _v == nil do
                _v = property[i]
                i += 1
            end
            v = _v:GetValue()
        end


        if v  ~= nil then
            if self.TWINFO and not table.find(DISABLED_TWEEN_DATATYPES, typeof(v)) and self.IsInstance then
                TweenService:Create(self.Instance, self.TWINFO, {[Property] = v}):Play()
            else
                self.Instance[Property] = v
                
            end
        end

    end
end

function HandlerClass:Add(Property, _value, Priority, Time)
    if not self.Values[Property] then
        self.Values[Property] = {}
    end
    if not self.DefaultValues[Property] then
        self.DefaultValues[Property] = self.Instance[Property]
    end

    Priority = math.max(Priority or 1, 1)
    if _value == nil then
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

function HandlerClass:SetTweenInfo(TwInfo)
    self.TWINFO = TwInfo
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
            TWINFO = nil,
            IsInstance = typeof(Instance) == "Instance",
            Methods = {},
            id = math.random(1,100000)
        }, HandlerClass)

        if typeof(Instance) == "table" then
            for property,value in Instance do
                local method = setmetatable({
                    _instance = Handler,
                    _property = property
                }, PropertyClass)

                Handler.Methods[property] = method

                Handler:SetDefaultValue(property,value)
            end
        end

        Handler.Trove:Add(function()
            Models[Instance] = nil
        end)

        if Handler.IsInstance then
            Handler.Trove:Connect(Instance.AncestryChanged, function(_, parent)
                if parent == nil then
                    Handler:Destroy()
                end
            end)    
        end
        

        Models[Instance] = Handler
    end

    return Models[Instance]
end


function PriorityModule.Set(Instance, Property, Value, Priority, Time)
    local Handler = PriorityModule:GetHandler(Instance)

    return Handler:Add(Property, Value, Priority, Time)
end

return PriorityModule
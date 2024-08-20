local Timer = {}
Timer.__index = Timer

local Identifiers = {}

function Timer.new()
    local self = setmetatable({}, Timer)
    return self
end

function Timer.FromIdentifier(idenfitier: any)
    if Identifiers[idenfitier] then
        return Identifiers[idenfitier]
    end

    local self = Timer.new()
    Identifiers[idenfitier] = self

    return self
end

function Timer:()
    
end

return Timer

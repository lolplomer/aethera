local Passives = {}

local ModuleClass = {

    Passives = Passives,

    DefaultPassives = {
       MPRegeneration = {Level = 1}
    }

}

for _, Module in script:GetChildren() do
    Passives[Module.Name] = require(Module)
end

ModuleClass.__index = function(self, index)
    return ModuleClass[index] or Passives[index]
end

--local Module: {Passives: {any}, DefaultPassives: {[string]: {Level: number}}} =  setmetatable({}, ModuleClass)

return ModuleClass
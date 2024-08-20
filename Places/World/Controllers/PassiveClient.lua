local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)

local package = ReplicatedStorage.Packages
local signal = require(package.Signal)

local PassiveClient = Knit.CreateController { Name = "PassiveClient" }
PassiveClient.PassiveChanged = signal.new()
PassiveClient.PassiveActivated = signal.new()
PassiveClient.PassiveDeactivated = signal.new()

local PassiveModule = require(ReplicatedStorage.GameModules.Passives)

local function passive()
    return Knit.GetController('PlayerReplicaController'):GetReplica('Passive')
end

function PassiveClient:ListenToStackChange(passiveName: string, id: string, fn: (PassiveStack))
    return PassiveClient.PassiveChanged:Connect(function(_passiveName, _id, PassiveStack)
        if _id == id and passiveName == _passiveName then
            fn(PassiveStack)
        end
    end)
end

function PassiveClient:ListenToPassiveChange(passiveName, fn)
    return PassiveClient.PassiveChanged:Connect(function(_passiveName)
        if passiveName == _passiveName then
            fn(self:GetPassive(passiveName))
        end
    end)
end

function PassiveClient:GetActivePassives()
    return passive().Passives
end

function PassiveClient:GetPassive(passiveName, id)
    local PassiveReplica = passive()
    if id and PassiveReplica.Passives[passiveName] then
        return PassiveReplica.Passives[passiveName][id]
    end
    return PassiveReplica.Passives[passiveName]
end

function PassiveClient:GetLevel(passiveName)
    local level = 0
    local Passive: Passive = passive().Passives[passiveName]
    for _, stack in Passive do
        level += stack.Level
    end
    return level
end

function PassiveClient._generate(passiveName, id, method)
     
    local PassiveReplica = passive()

    local Passive: Passive = PassiveReplica.Passives[passiveName]
    local Module: {[string]: any} = PassiveModule[passiveName]

    local level = 0
    if id and Passive[id] then
        level = Passive[id].Level
    else
        for _, stack in Passive do
            level += stack.Level
        end
    end

    if Passive and Module and Module[method] then
       
        local result = Module[method](level)
        
        return result, level
    end

    return nil, level
end

function PassiveClient:GetStackCount(passiveName)
    local Passive = self:GetPassive(passiveName)

    local count = 0
    for _ in Passive do
        count += 1
    end

    return count
end

function PassiveClient:BuildName(passiveName, id)
    local name, level = self._generate(passiveName, id, 'Name')

    return `<b>{name or passiveName} [Lv. {level or 0}]</b>`
end

function PassiveClient:BuildDescription(passiveName: string, id: string | nil)
   local desc =  self._generate(passiveName, id, 'Description') or 'No description'
   return desc
end

function PassiveClient:KnitStart()

    local PassiveReplica = passive()

    local previous = {}

    PassiveReplica.Replica:ListenToRaw(function(_, path, value)
        local passiveName = path[2]
        local id, stack = path[3], nil
        if passiveName and id then
            stack = PassiveReplica.Passives[passiveName][id]
        elseif passiveName and not id and value then
            id, stack = next(value)
        end
        if id and stack then
            PassiveClient.PassiveChanged:Fire(passiveName, id, stack)
        end

        local has = next(PassiveReplica.Passives[passiveName]) ~= nil
        if previous[passiveName] ~= has then
            if has then
                PassiveClient.PassiveActivated:Fire(passiveName)
            else
                PassiveClient.PassiveDeactivated:Fire(passiveName)
            end
        end

        previous[passiveName] = has
    end)
end

export type Passive = {
    [string]: PassiveStack
}

export type PassiveStack = {
    Level: number,
    TimeStart: number,
    TimeEnd: number
}

return PassiveClient

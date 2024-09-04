local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MainClass = {}
MainClass.__index = MainClass

local Trove = require(ReplicatedStorage.Packages.Trove)

local Rigs = {}

local Rig = {}
Rig.__index = Rig

function Rig:AddDestructor(category, destructor)
    if self.Destructors[category] then
        self.Trove:Remove(self.Destructors[category])
    end
    self.Destructors[category] = destructor and self.Trove:Add(destructor)
end

local function NewRig(rig:Model)
    local cleaner = Trove.new()

    Rigs[rig] = setmetatable({
        Rig = rig,
        Destructors = {},
        Avatar = {},
        Trove = cleaner    
    },Rig)

    cleaner:AttachToInstance(rig)
    cleaner:Add(function()
        Rigs[rig] = nil
    end)

    return Rigs[rig]
end

local function GetRig(rig)
    if not Rigs[rig] then
        Rigs[rig] = NewRig(rig)
    end
    return Rigs[rig]
end

function MainClass:ApplyCategory(category, rig, value)
    print(category, rig, value)
    local Main = require(script.Parent)

    rig = GetRig(rig)

    local Module = Main.Category[category]
    if Module then
        if Module.IsValid and not Module.IsValid(value) then
            return
        end
        if Module.Apply then
            local Destructor = Module.Apply(rig.Rig, value)

            rig:AddDestructor(category, Destructor)
        end
    else
        warn('Unknown category',category)
    end
end

return MainClass

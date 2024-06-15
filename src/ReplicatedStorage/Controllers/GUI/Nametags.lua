local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local module = {}

local GUI = require(script.Parent)
local Player = game.Players.LocalPlayer

local Roact = require(ReplicatedStorage.Utilities.Roact)
local ReactRoblox = require(ReplicatedStorage.Packages["react-roblox"])

local Trove = require(ReplicatedStorage.Packages.Trove)

local nametags = {}
--local render = {}

local NametagClass = {}
NametagClass.__index = NametagClass

local overlap = OverlapParams.new()
overlap.FilterType =Enum.RaycastFilterType.Include


function NametagClass.new(Entity)
    if nametags[Entity] then
        nametags[Entity]:Destroy()
    end

    local self = setmetatable({
        Trove = Trove.new(),
        Entity = Entity,
        Character = Entity.Parent
    }, NametagClass)

   
    local Billboard = Instance.new('BillboardGui')
    Billboard.Size = UDim2.new(7,0,1.5,0)
    Billboard.StudsOffsetWorldSpace = Vector3.new(0,4,0)
    Billboard.AlwaysOnTop = true
    Billboard.ResetOnSpawn = false
    Billboard.Parent = Player.PlayerGui
    Billboard.Adornee = Entity
    Billboard.StudsOffset = Vector3.new(0,0,-3)

    local root = ReactRoblox.createRoot(Billboard)

    --root:render(GUI.newElement('Nametag', {Enabled = true}))

    self.Billboard = Billboard
    self.Gui = root
    
    nametags[Entity] = self

    print('New nearby entity', self.Character)

    self.Trove:Add(function()
        print('Nearby entity removed',self.Character)
        nametags[self.Entity] = nil
        self.Gui:unmount()
        Billboard:Destroy()
    end)

    self:Enable()

    return self
end

function NametagClass:Disable()
    self:SetEnabled(false)
end

function NametagClass:Enable()
    self:SetEnabled(true)
end


function NametagClass:SetEnabled(bool)
    if self.Enabled ~= bool then
        self.Enabled = bool

        self.Billboard.Enabled = bool
        self.Gui:render(GUI.newElement('Nametag', {Enabled = bool, Character = self.Character}))
    end
end


function NametagClass:Destroy()
    self.Trove:Destroy()
end

function module:RenderEntityNametag()
    local Character = Player.Character
    if Character then
        local Entities = CollectionService:GetTagged('Entity')

        overlap.FilterDescendantsInstances = Entities
        local NearbyEntities = workspace:GetPartBoundsInRadius(Character:GetPivot().Position, 150, overlap)

        for _, Nametag in nametags do
            local i = table.find(NearbyEntities, Nametag.Entity)
            if not i then
                Nametag:Destroy()
            else
                table.remove(NearbyEntities, i)
            end
        end
        for _, Entity in NearbyEntities do
            NametagClass.new(Entity)    
        end
    end
end

function module.Init()
    task.spawn(function()
        while Player:IsDescendantOf(game.Players) do
            task.wait(0.3)
            module:RenderEntityNametag()
        end
    end)
end

return module
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local MobModule = require(ReplicatedStorage.GameModules.Mobs)
local Trove = require(ReplicatedStorage.Packages.Trove)

local Model = ReplicatedStorage.Models

local MobService = Knit.CreateService {
    Name = "MobService",
    Client = {},
}

local Mob = {}
Mob.__index = Mob

local MobFolder = Instance.new('Folder')
MobFolder.Parent = workspace
MobFolder.Name = 'Mobs'

local Mobs = {}

function Mob.new(module, level, id, CF)
    local StatService = Knit.GetService('StatService')
    local model:Model = Model:FindFirstChild(module.Model)
    if not model then
        return warn('Unknown model',module.Model)
    end

    model = model:Clone()
    model.Parent = MobFolder
    model:PivotTo(CF)

    local self = setmetatable({
        _cleaner = Trove.new(),
        id = id,
        Stats = StatService:CreateMobStats(module.RawStats, level),
        Model = model
    }, Mob)

    self._cleaner:Add(self.Stats)
    self._cleaner:Add(self.Model)
    self._cleaner:Connect(model.AncestryChanged, function()
        if not model.Parent then
            self:Destroy()
        end
    end)
    return self
end

function Mob:Destroy()
    self._cleaner:Destroy()
end

local previous = 0
function MobService:Spawn(MobName, Level, CF)
    local module = MobModule[MobName]
    print(module)
    if module then
        print('spawning..',MobName)
        previous += 1
        local id = previous
        local mob = Mob.new(module, Level or 1, id, CF or CFrame.new())
        mob._cleaner:Add(function()
            print('Mob Deleted')
            Mobs[mob.Model] = nil
        end)
        Mobs[mob.Model] = mob

        return mob
    end
end

function MobService:GetMobData(model)
    return Mobs[model]
end

function MobService:KnitStart()
    local playerDataService = Knit.GetService('PlayerDataService')
    playerDataService.PlayerAdded:Connect(function(player)
        player.Chatted:Connect(function(msg)
            print('mobserice',msg)
            local arg = msg:split(' ')
            if arg[1]=='spawn' then
                local mob = MobService:Spawn(arg[2],1,player.Character.HumanoidRootPart.CFrame * CFrame.new(0,0,-5))
                print('Mob Data:', mob)
            end
        end)
    end)
end

function MobService:KnitInit()
    
end


return MobService

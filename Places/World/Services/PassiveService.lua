local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")

local Knit = require(ReplicatedStorage.Packages.Knit)

local PassiveService = Knit.CreateService {
    Name = "PassiveService",
    Client = {},
}

local PlayerDataService, StatService, PlayerStateService, CombatService

local misc = game.ReplicatedStorage:WaitForChild('Utilities'):WaitForChild('Misc')
local ReplicaService = require(game.ServerScriptService.ReplicaService)
local PassiveReplicaToken = ReplicaService.NewClassToken("Passive")
local WriteLib = ReplicatedStorage.Utilities.WriteLibs.Passive

local Trove = require(ReplicatedStorage.Packages.Trove)
local Util = require(game.ReplicatedStorage.Utilities.Util)

local Promise = require(ReplicatedStorage.Utilities.Promise)
local PassiveModule = require(ReplicatedStorage.GameModules.Passives)

local ReplicaClass = require(misc.ReplicaClass)

local Passives = {}

local sleep = Promise.promisify(task.wait)

local function GetPassive(passiveName)
   return PassiveModule.Passives[passiveName] 
end

local PassiveClass = {} do
    PassiveClass.__index = function(self, index)
        return PassiveClass[index] or ReplicaClass.__index(self, index)
    end
    function PassiveClass.new(Replica)

        local Player = Replica.Tags.Player
        local playerState = PlayerStateService:GetPlayerState(Player)
        local playerStats = StatService:GetStats(Player)
        local combatData = CombatService:GetCombatData(Player)

        local self = setmetatable({
            Replica = Replica,
            ActivePassives = {},
            Player = Replica.Tags.Player,
            
        }, PassiveClass)

        self.Attribute = {
            Combat = combatData,
            Stats = playerStats,
            State = playerState,
            Passive = self
        }

        return self
    end

    function PassiveClass:RemovePassive(passiveName, id)
        local Passive = GetPassive(passiveName)
    
        if not Passive then
            return
        end

        if id and self.Passives[passiveName] and self.Passives[passiveName][id]  then
            self.Replica:SetValue({'Passives',passiveName,id}, nil)
        end

        self:RemoveTimer(passiveName,id)
        self:UpdatePassive(passiveName)
    end

    function PassiveClass:AddPassive(passiveName, id, level, duration, hidden)
        
        duration = duration or -1
        level = tonumber(level) or 1
        id = id or 'None'

        local Passive = GetPassive(passiveName)
        local Now = os.clock()
    
        if not Passive or not id then
            return
        end
        local PassiveData = self.Passives[passiveName]
        local Data = {
            Level = level, 
            TimeStart = Now, 
            TimeEnd = duration < 0 and -1 or Now + duration,
            Hidden = hidden ~= nil and true or false
        }

        if not PassiveData then
            self.Replica:SetValue({'Passives', passiveName}, {[id] = Data})
        else
            self.Replica:SetValue({'Passives', passiveName, id}, Data)
        end

        self:UpdatePassive(passiveName)
        
        self:SetTimer(passiveName, id, duration)

        local function remove()
            self:RemovePassive(passiveName, id)
        end

        return remove
    end

    function PassiveClass:RemoveTimer(passiveName, id)
        local activePassive = self.ActivePassives[passiveName]
        if activePassive and activePassive.Timer[id] then
            if not activePassive._TROVE._cleaning then
                activePassive._TROVE:Remove(activePassive.Timer[id])     
            end
            activePassive.Timer[id] = nil
        end
        
    end

    function PassiveClass:SetTimer(passiveName, id, duration)
        self:RemoveTimer(passiveName, id)
        local activePassive = self.ActivePassives[passiveName]

        if activePassive and duration and duration > 0 then
            
            local timer = activePassive._TROVE:AddPromise(sleep(duration))
            timer:andThenCall(self.RemovePassive, self, passiveName, id)

            activePassive.Timer[id] = timer
        end
    end

    function PassiveClass:UpdatePassive(passiveName)
        local level = 0

        if self.Passives[passiveName] then
            
            for _, data in self.Passives[passiveName] do
                level += data.Level
            end

        end

        if level > 0 then
            self:Activate(passiveName, level)
        else
            self:Deactivate(passiveName)
        end
    end

    function PassiveClass:Activate(passiveName, level)
        local player = self.Player
    
        level = level or 1
        local Passive = PassiveModule.Passives[passiveName]
    
        if not Passive then
            return
        end
        
        local activePassive = self.ActivePassives[passiveName] 
        
        local userData = {}
        if activePassive then
            if not activePassive._TROVE._cleaning then
                activePassive._TROVE:Remove(activePassive.Deactivate)
            end
            
            userData = activePassive.Data
        end
    
        local deactivePassive = Passive.Activate(player, level, self.Attribute, userData)

        if not self.ActivePassives[passiveName] then
            self.ActivePassives[passiveName] = {
                _TROVE = Trove.new(), 
                Timer = {},
            }
           
            activePassive = self.ActivePassives[passiveName]
            activePassive._TROVE:Add(function()
                self.Replica:SetValue({'Passives',passiveName}, {})
            end)
        end

        activePassive.Deactivate = deactivePassive

        activePassive._TROVE:Add(deactivePassive)
        activePassive.Data = userData
    
        --self.Replica:Write("SetPassive", passiveName, level)
    end
    function PassiveClass:Deactivate(passiveName)
        local activePassive = self.ActivePassives[passiveName] 
        if activePassive then
            activePassive._TROVE:Clean()
        end
    
        self.ActivePassives[passiveName] = nil
       -- self.Replica:Write("RemovePassive", passiveName)
    end
end


local function ActivateDefaultPassives(Player: Player)
    for PassiveName, Info in PassiveModule.DefaultPassives do
        local PlayerPassive = PassiveService:GetPlayerPassives(Player)
        PlayerPassive:AddPassive(PassiveName, 'Default', Info.Level, -1)
    end
end

local function OnPlayerAdded(player: Player, data)
    local PassiveReplica = ReplicaService.NewReplica({
        ClassToken = PassiveReplicaToken,
        Tags = {Player = player},
        Data = {
            Passives = {}
        },
        Parent = data.Replica,
        WriteLib = WriteLib,
    })
    local PassiveController = PassiveClass.new(PassiveReplica)

    PassiveReplica:AddCleanupTask(function()
        for Name, _ in PassiveController.ActivePassives do
            PassiveController:Deactivate(Name)
        end
    end)

    PassiveReplica:AddCleanupTask(function()
        Passives[player] = nil
    end)

    player.Chatted:Connect(function(message)
        local args = message:split(" ")
        local passive = args[2]
        if args[1] == 'activatepassive' then
            local level = tonumber(args[3]) or 1
            local id = args[4] or tostring(math.random(1,100))
            local duration = tonumber(args[5]) or 10
            PassiveController:AddPassive(passive, id, level, duration)
        elseif args[1] == 'deactivatepassive' then
            PassiveController:Deactivate(passive)
        elseif args[1] == 'mypassive' then
            print(PassiveController)
        end
    end)

    Passives[player] = PassiveController
    ActivateDefaultPassives(player)
end

function PassiveService:GetPlayerPassives(player)
    return Util.GetAsync(Passives, player, "Passives")
end

function PassiveService:KnitInit()
    PlayerDataService = Knit.GetService('PlayerDataService')
    StatService =  Knit.GetService("StatService")
    PlayerStateService =  Knit.GetService("PlayerStateService")
    CombatService = Knit.GetService('CombatService')

    PlayerDataService.PlayerAdded:Connect(OnPlayerAdded)
end


return PassiveService

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)
local BridgeNet2 = require(ReplicatedStorage.Packages.bridgenet2)

local PlayerDataService, KeybindService, InventoryService

local CombatService = Knit.CreateService {
    Name = "CombatService",
    Client = {},
}

local CombatData = {}

local GameModules = ReplicatedStorage.GameModules
local CombatFolder = GameModules.Combat
local States = require(CombatFolder.States)

local StateChanged = BridgeNet2.ReferenceBridge('StateChanged')

function CombatService:KnitStart()
    
end

function CombatService:KnitInit()
    PlayerDataService = Knit.GetService("PlayerDataService")
    KeybindService = Knit.GetService("KeybindService")
    InventoryService = Knit.GetService("InventoryService")

    KeybindService
    -- :SetDefaultKeybind("Block", Enum.KeyCode.F)
    -- :SetDefaultKeybind("M1", Enum.UserInputType.MouseButton1)
    :SetDefaultKeybind("WeaponEquipmentSwitchPrevious", Enum.KeyCode.Q)
    :SetDefaultKeybind("WeaponEquipmentSwitchNext", Enum.KeyCode.E)

    for Name, Info in States do
        for index, key in Info.Keys do
            KeybindService:SetDefaultKeybind(Name, key, index)
        end
    end
 
    PlayerDataService.PlayerAdded:Connect(function(player: Player)
        CombatData[player] = {
            State = nil,
            StateIndex = nil,
        }
    end)

    game.Players.PlayerRemoving:Connect(function(player)
        CombatData[player] = nil
    end) 

    StateChanged:Connect(function(player, content)
        local State, index = table.unpack(content)
        local Data = CombatData[player]

        Data.State = State
        Data.StateIndex = index
    end)

    KeybindService:OnKeybindTrigger('WeaponEquipmentSwitchPrevious', function(player: Player)
        local Inventory = InventoryService:GetInventory(player)
        Inventory:PreviousEquipment('Weapon')
       -- print('prev')
    end)

    KeybindService:OnKeybindTrigger('WeaponEquipmentSwitchNext', function(player: Player)
        local Inventory = InventoryService:GetInventory(player)
        Inventory:NextEquipment('Weapon')
       -- print('next')
    end)
end

function CombatService.Client:SetState(Player, State, StateIndex)
    local PlayerStateService = Knit.GetService("PlayerStateService")
    local PlayerState = PlayerStateService:GetPlayerState(Player)

    PlayerState:SetMultiple ({
        CombatState = State,
        CombatStateIndex = StateIndex
    })
end


return CombatService

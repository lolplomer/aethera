local CollectionService = game:GetService("CollectionService")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)
local BridgeNet2 = require(ReplicatedStorage.Packages.bridgenet2)
local Signal = require(ReplicatedStorage.Packages.Signal)

local Util = require(ReplicatedStorage.Utilities.Util)

local KeybindService = Knit.CreateService {
    Name = "KeybindService",
    Client = {},
}

local InputFolder = game.ReplicatedStorage:WaitForChild"Utilities":WaitForChild"Input"

local InputConverter = require(InputFolder:WaitForChild"Converter")

local DefaultKeybinds = {}
local PlayerDataService

function KeybindService:KnitStart()
    PlayerDataService:RegisterDataIndex("Keybinds", DefaultKeybinds)
    PlayerDataService:LoadReady("Keybind")
end

function KeybindService:SetDefaultKeybind(keybindName, Input, index)
    index = tonumber(index) or 1
    if not DefaultKeybinds[keybindName] then
        DefaultKeybinds[keybindName] = {}
    end
    DefaultKeybinds[keybindName][index] = InputConverter:ConvertInput(Input)
    return self
end

function KeybindService:KnitInit()
    PlayerDataService = Knit.GetService("PlayerDataService")
    PlayerDataService:AwaitLoad("Keybind")

    self:SetDefaultKeybind('Interact', Enum.KeyCode.F)
    self:SetDefaultKeybind('MouseLock', Enum.KeyCode.LeftControl)
end

function KeybindService:SetObjectInteract(Object: BasePart, ActionText: string)
    local proximity = Util.new('ProximityPrompt', {
        ActionText = ActionText,
        Parent = Object,
        Exclusivity = Enum.ProximityPromptExclusivity.OneGlobally
    })

    CollectionService:AddTag(proximity, 'Proximity')

    local function finish()
        
        local attachment = Util.new('Attachment', {
            Parent = workspace.Terrain,
            WorldCFrame = Object.CFrame
        })

        proximity.Parent = attachment

        Debris:AddItem(attachment, 1)
        proximity.Enabled = false
        
    end

    return proximity, finish
end

function KeybindService:OnKeybindTrigger(keybind, fn)
    return self.KeybindTriggered:Connect(function(player, Keybind)
        if Keybind == keybind then
            fn(player)
        end
    end)
end

function KeybindService:CapturePlayerKeybind(player)
    local keybindList = {}

    local function Capture(keybind, fn)
        keybindList[keybind] = fn
    end

    local triggeredSignal = self.KeybindTriggered:Connect(function(_player, keybind, index)
        if player == _player and keybindList[keybind] then
            keybindList[keybind](index)
        end
    end)

    return Capture, triggeredSignal
end

KeybindService.ChangeKeybind = BridgeNet2.ReferenceBridge('ChangeKeybind') do
    KeybindService.ChangeKeybind.OnServerInvoke = function(player, content)
        local keybind, input, index = table.unpack(content)
        index = tonumber(index) or index

        local PlayerData = PlayerDataService:GetPlayerData(player)
        local InputData = InputConverter:ConvertInput(input)

        assert(PlayerData.Keybinds[keybind], `Keybind named {keybind} does not exist`)
        assert(InputData, `Invalid Input {input}`)

        PlayerData.Replica:SetValue({"Keybinds",keybind,index},InputData)
    end
end

KeybindService.ClientKeybindTriggered = BridgeNet2.ReferenceBridge('KeybindTriggered') do
    KeybindService.ClientKeybindTriggered:Connect(function(player, content)
        local keybind, index = table.unpack(content)
        KeybindService.KeybindTriggered:Fire(player, keybind, index)
      --  print(player, 'Pressed keybind:', keybind, index)
    end)
end

KeybindService.KeybindTriggered = Signal.new()

return KeybindService

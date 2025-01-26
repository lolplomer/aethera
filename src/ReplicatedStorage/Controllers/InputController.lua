local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage:WaitForChild"Packages"
local Knit = require(Packages:WaitForChild"Knit")
local Signal = require(Packages:WaitForChild"Signal")
local BridgeNet2 = require(Packages:WaitForChild("bridgenet2"))

local InputController = Knit.CreateController { Name = "InputController" }
local PlayerDataController

local UIS = game:GetService("UserInputService")
local InputFolder = ReplicatedStorage:WaitForChild"Utilities":WaitForChild"Input"
local InputConverter = require(InputFolder:WaitForChild"Converter")

InputController.KeybindTriggered = Signal.new()
InputController.KeybindTriggerEnded = Signal.new()

InputController.InGui = false
InputController.GuiKeybind = nil

local KeybindTriggered = BridgeNet2.ReferenceBridge('KeybindTriggered')
local ChangeKeybind = BridgeNet2.ReferenceBridge('ChangeKeybind')

local function CheckGuiKeybind(keybind)
    return InputController.InGui == false or keybind == InputController.GuiKeybind
    
end

local function BeginCapturingKeybindInputs()
    UIS.InputBegan:Connect(function(inputObject, gameProcessedEvent)
        
        if gameProcessedEvent then return end
        local input = InputConverter:ConvertInputObject(inputObject)
        local keybind, index = InputController:FindKeybindFromInput(input)
        if keybind ~= nil and CheckGuiKeybind(keybind) then
            
           InputController.KeybindTriggered:Fire(keybind, index) 
           KeybindTriggered:Fire({keybind, index})
        end
    end)

    UIS.InputEnded:Connect(function(inputObject)
        local input = InputConverter:ConvertInputObject(inputObject)
        local keybind, index = InputController:FindKeybindFromInput(input)
        if keybind ~= nil and CheckGuiKeybind(keybind) then
           InputController.KeybindTriggerEnded:Fire(keybind, index) 
        end
    end)
end

local function RemapShiftLockKeys(KEYS: string)
    local Players = game:GetService("Players")

    local mouseLockController = Players.LocalPlayer
        .PlayerScripts
        :WaitForChild("PlayerModule")
        :WaitForChild("CameraModule")
        :WaitForChild("MouseLockController")

    local obj = mouseLockController:FindFirstChild("BoundKeys")
    if obj then
        obj.Value = KEYS
    else
        obj = Instance.new("StringValue")
        obj.Name = "BoundKeys"
        obj.Value = KEYS
        obj.Parent = mouseLockController
    end
end

function InputController:TriggerKeybind(KeybindName, index)
    self.KeybindTriggered:Fire(KeybindName, index)
end

function InputController:EndKeybindTrigger(keybindName, index)
    self.KeybindTriggerEnded:Fire(keybindName, index)
end

function InputController:OnKeybindTrigger(KeybindName, Fn)
    return self.KeybindTriggered:Connect(function(Keybind, index)
        if Keybind == KeybindName then
            Fn(index)
        end
    end)
end

function InputController:OnKeybindTriggerEnded(keybindName, Fn)
    return self.KeybindTriggerEnded:Connect(function(keybind, index)
        if keybind == keybindName then
            Fn(index)    
        end
    end)
end

function InputController:GetInputOfKeybind(keybind, index)
    local PlayerData = PlayerDataController.PlayerData
    if not PlayerData then return Enum.KeyCode.Zero end

    local inputs = PlayerData.Keybinds[keybind]
    index = index or 1
    if inputs then
        return InputConverter:ReadInputData(inputs[index])
    end
end

function InputController:FindKeybindFromInput(input)
    local PlayerData = PlayerDataController.PlayerData
    if not PlayerData then return end
    
    for keybind, Inputs in PlayerData.Keybinds do
        for index, inputData in Inputs do
            if InputConverter:ReadInputData(inputData) == input then
                return keybind, index
            end    
        end
    end
end

function InputController:ChangeKeybind(keybind, input)
    ChangeKeybind:Fire {keybind, input}
end

function InputController:KnitStart()
   BeginCapturingKeybindInputs()
   --RemapShiftLockKeys('LeftControl,RightControl')
end


function InputController:KnitInit()
    PlayerDataController = Knit.GetController'PlayerDataController'
end


return InputController

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)

local GameModules = ReplicatedStorage:WaitForChild"GameModules"
local CombatFolder = GameModules:WaitForChild("Combat")
local CharacterModule = require(CombatFolder:WaitForChild"Character")

local Util = require(ReplicatedStorage.Utilities.Util)
local Player = game.Players.LocalPlayer


local Signal = require(ReplicatedStorage.Packages.Signal)
local CharacterController = Knit.CreateController { Name = "CharacterController" }
CharacterController.StateChanged = Signal.new()

local packet = require(ReplicatedStorage.Packets.Combat)

local Char

local State = {
    State = nil,
    Index = nil
}

function CharacterController:KnitStart()
    Util.CharacterAdded(Player, function(Character: Model)
        Char = CharacterModule:Initialize(Character)

        Char.StateChanged:Connect(function(state, index)
            State.State = state
            State.Index = index
            self.StateChanged:Fire(state, index)
        end)
    end)
end

function CharacterController:CastNormalAttack()
    local origin: CFrame = Char.Root.CFrame
    local size = Vector3.new(7,7,1)
    local params = RaycastParams.new()

    local filter = CollectionService:GetTagged('Entity')
    local index = table.find(filter, Char.Root)
    if index then
        table.remove(filter, index)
    end

    params.FilterDescendantsInstances = filter
    params.FilterType = Enum.RaycastFilterType.Include
    
    local result = workspace:Blockcast(origin, size, origin.LookVector * 7, params)

    if result and result.Instance then
        local Model = result.Instance.Parent

        packet.NormalAttack.send(Model)
        
        print('Hit', Model)
    end
end

function CharacterController:ChangeState(state, index)
    index = index or 1
    Char:ChangeState(state, index)
end

function CharacterController:GetState()
    return State.State, State.Index
end

function CharacterController:GetCharacter()
    return Char
end

function CharacterController:KnitInit()
    
end


return CharacterController

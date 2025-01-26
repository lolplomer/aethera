local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)
local Signal = require(ReplicatedStorage.Packages.Signal)

local CharacterService = Knit.CreateService {
    Name = "CharacterService",
    Client = {},
}

CharacterService.CharacterLoaded = Signal.new()

function CharacterService:LoadCharacter(player: Player)
    player:LoadCharacter()
    CharacterService.CharacterLoaded:Fire(player.Character, player)
end

function CharacterService:Spawn(player: Player)
    if player:GetAttribute('Spawned') then
        return
    end

    player.CharacterAdded:Connect(function(character)
        local humanoid = character:WaitForChild('Humanoid')
        humanoid.Died:Connect(function()
            task.wait(2)
            self:LoadCharacter(player)
        end)
    end)

    self:LoadCharacter(player)
end

function CharacterService:KnitStart()

    print('Initiating CharacterService')

    local PlayerDataService = Knit.GetService("PlayerDataService")
    local LoadingService = Knit.GetService('LoadingService')

    -- game.Players.PlayerAdded:Connect(function(player)
    --     print('Player Joined')
    --     LoadingService:AwaitUntilPlayerLoads(player)
    --     print('Player Joined [2]')
    --     self:Spawn(player)
    -- end)


    PlayerDataService.PlayerAdded:Connect(function(player)
        LoadingService:AwaitUntilPlayerLoads(player)    
        self:Spawn(player)
    end)
end


return CharacterService

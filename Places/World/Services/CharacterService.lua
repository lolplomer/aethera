local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)

local CharacterService = Knit.CreateService {
    Name = "CharacterService",
    Client = {},
}

function CharacterService:Spawn(player: Player)
    if player:GetAttribute('Spawned') then
        return
    end

    player.CharacterAdded:Connect(function(character)
        local humanoid = character:WaitForChild('Humanoid')
        humanoid.Died:Connect(function()
            task.wait(2)
            player:LoadCharacter()
        end)
    end)

    player:LoadCharacter()
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

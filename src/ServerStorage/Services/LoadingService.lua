local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Signal = require(ReplicatedStorage.Packages.Signal)

local Knit = require(ReplicatedStorage.Packages.Knit)

local LoadingService = Knit.CreateService {
    Name = "LoadingService",
    Client = {
        LoadingDone = Knit.CreateSignal()
    },
}

LoadingService.LoadingDone = Signal.new()

function LoadingService:IsDoneLoading(player: Player)
    return player:GetAttribute('Loaded')
end

function LoadingService:AwaitUntilPlayerLoads(player: Player)
    while not LoadingService:IsDoneLoading(player) do
        LoadingService.LoadingDone:Wait()
    end
end

function LoadingService:KnitInit()
    LoadingService.Client.LoadingDone:Connect(function(player: Player)
        player:SetAttribute('Loaded', true)
        LoadingService.LoadingDone:Fire(player)
    end)
end

return LoadingService

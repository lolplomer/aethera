local ReplicatedStorage = game:GetService"ReplicatedStorage"
--game.ReplicatedFirst:RemoveDefaultLoadingScreen()

local Knit = require(ReplicatedStorage.Packages.Knit)

local function fetch(names)
    local services = {}
    for _, v in names do
        services[v] = ReplicatedStorage:FindFirstChild(v)
    end
    return services
end

while not game:IsLoaded() do
    game.Loaded:Wait()
    print('Done loading the game')
end

ReplicatedStorage:WaitForChild('KnitServerStarted')

local controllers = fetch {'Controllers', 'PlaceControllers'}

for _,v in controllers do
    Knit.AddControllers(v)
end

Knit.Start():andThen(function()
    local ReplicaController = require(ReplicatedStorage:WaitForChild("Madwork"):WaitForChild"ReplicaController")
    ReplicaController.RequestData()
    warn("Knit Client has been started")
end):catch(warn)

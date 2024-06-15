local ReplicatedStorage = game:GetService"ReplicatedStorage"
game.ReplicatedFirst:RemoveDefaultLoadingScreen()

local Knit = require(ReplicatedStorage.Packages.Knit)

while not game:IsLoaded() do
    print('Waiting until game loads...')
    game.Loaded:Wait()
    print('Done loading the game')
end

Knit.AddControllersDeep(game.ReplicatedStorage:WaitForChild("Controllers"))

Knit.Start():andThen(function()
    local ReplicaController = require(ReplicatedStorage:WaitForChild("Madwork"):WaitForChild"ReplicaController")
    ReplicaController.RequestData()
    warn("Knit Client has been started")
end):catch(warn)

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)

local MapController = Knit.CreateController { Name = "MapController" }

function MapController:KnitStart()

end


function MapController:KnitInit()
    self.Waypoints = require(script.WaypointsClient)
end


return MapController

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local service = {}

local waypoints = {}

local Knit = require(ReplicatedStorage.Packages.Knit)
local PlayerDataService = Knit.GetService('PlayerDataService')
local CharacterService = Knit.GetService('CharacterService')

local getRandomPoint

CharacterService.CharacterLoaded:Connect(function(character: Model, player: Player)
    
    local playerData = PlayerDataService:GetPlayerData(player)
    if not playerData then return end

    local lastPosition = Vector2.new(unpack(playerData.Profile.Data.Map.LastPosition))
    local wp = service:GetClosestWaypoint(lastPosition)

    local pos = getRandomPoint(wp.Model.PrimaryPart.Position, 5, 10)
    print('teleporting to a new position', wp.Name, pos)
    character:PivotTo(CFrame.new(pos))
end)

function getRandomPoint(position, minRadius, maxRadius)
    local angle = math.rad(math.random(0, 360)) -- random angle in degrees
    local distance = math.random() * (maxRadius - minRadius) + minRadius -- random distance within radius range

    -- calculate x and z offsets (2D)
    local offsetX = math.cos(angle) * distance
    local offsetZ = math.sin(angle) * distance

    -- adjust for y if you want a flat area, or you can randomize it for a sphere
    local offsetY = 0 -- flat; change this for height variation!

    -- return the random point
    return position + Vector3.new(offsetX, offsetY, offsetZ)
end

function service.PlayerAdded(player: Player, playerData)


    warn(player, 'previous position is', unpack(playerData.Map.LastPosition))

    player.CharacterRemoving:Connect(function(character: Model)
        local CF = character:GetPivot()
        playerData.Map.LastPosition = {CF.X, CF.Z}

        print("Player last position: ", CF.X, CF.Z)
    end)
end

function service:GetWaypoints()
    return waypoints
end

function service:GetClosestWaypoint(pos: Vector2)
    
    local dist, current = 0, nil

    for _, wp in waypoints do
        
        local _dist = (pos - wp.MapPosition).Magnitude
        if not current or _dist < dist then
            dist = _dist
            current = wp
        end

    end

    return current, dist
end

function service:_initializeAllWaypoints()
    
    local Waypoints = workspace:FindFirstChild('Waypoints')

    if Waypoints then
    
        for _, wp:Model in Waypoints:GetChildren() do
            if wp:IsA("Model") then   
                local pos = wp:GetPivot()
                waypoints[wp.Name] = {
                    MapPosition = Vector2.new(pos.X, pos.Z),
                    Model = wp,
                    Name = wp.Name
                };

                wp:AddTag('Waypoint')
            end
        end

        return
    end

    warn('No waypoints folder in workspace, waypoints are not initialized')

end

service:_initializeAllWaypoints()

return service
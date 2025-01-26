local CollectionService = game:GetService("CollectionService")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local controller = {}

local util = require(ReplicatedStorage.Utilities.Util)
local trove = require(ReplicatedStorage.Packages.Trove)

local proximities = {}

function controller:_newWaypoint(waypoint: Attachment)
    
    local proximity: ProximityPrompt = util.new('ProximityPrompt', {
        RequiresLineOfSight = false,
        Exclusivity = Enum.ProximityPromptExclusivity.OneGlobally,
        Parent = waypoint,
        ObjectText = 'Waypoint',
        ActionText = 'Map Teleport'
    })

    proximity:AddTag('Proximity')

    proximities[proximity] = waypoint
end

function controller:_initialize()

    for _, waypoint: Attachment in CollectionService:GetTagged('Waypoints') do
        self:_newWaypoint(waypoint)
    end

    CollectionService:GetInstanceAddedSignal('Waypoints'):Connect(function(waypoint)
        self:_newWaypoint(waypoint)
    end)

    ProximityPromptService.PromptTriggered:Connect(function(prompt)
        local waypoint: Attachment = proximities[prompt]

        if waypoint then
            
            print('Hello waypoint',waypoint)

        end
    end)
end

controller:_initialize()

return controller
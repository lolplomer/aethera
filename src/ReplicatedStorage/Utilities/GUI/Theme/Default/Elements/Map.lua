--[[
    MapElement Component
    ====================
    A dynamic and interactive map component created using Roact for Roblox games.

    Props:
    ------
    - Scale (number): Initial scale of the map. Defaults to 1.
    - AllowMoving (boolean): Enables map movement with mouse drag and zoom with the scroll wheel.

    Behavior:
    ---------
    - Dragging the map is enabled when AllowMoving is true. Hold the left mouse button and drag to move.
    - Zoom the map using the mouse scroll wheel (scroll up to zoom in, scroll down to zoom out).
    - Automatically updates marker positions and map elements based on scale and offset.

    Example Usage:
    --------------
    local roact = require(...)
    local MapElement = require(...)

    local element = roact.createElement(MapElement, {
        Scale = 1,
        AllowMoving = true,
    })

    Notes:
    ------
    - Requires Roact, Trove, and additional Roblox services (e.g., Players, UserInputService).
    - Map images and settings are defined in the mapSettings module.
--]]

local roact = require(game.ReplicatedStorage:WaitForChild('Utilities'):WaitForChild('Roact'))
local mapSettings = require(game.ReplicatedStorage:WaitForChild('GameModules'):WaitForChild('MapSettings'))
local Knit = require(game.ReplicatedStorage:WaitForChild('Packages'):WaitForChild('Knit'))
local GUI = Knit.GetController("GUI")
local trove = require(game.ReplicatedStorage:WaitForChild('Packages'):WaitForChild('Trove'))
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local roactSpring = require(ReplicatedStorage.Packages.ReactSpring)

local MarkerIcons = mapSettings.Markers

local tableUtil = require(ReplicatedStorage.Packages.TableUtil)

local PlayerDataController = Knit.GetController("PlayerDataController")

local player = Players.LocalPlayer

local function WorldToMapPosition(worldPos, mapScale)
    local init = mapSettings.InitialPosition
    local x, y = worldPos.X, worldPos.Z
    local scale = mapScale
    
    return Vector2.new(
        (x - init.X / 2) * scale,
        (y - init.Y / 2) * scale
    )
end

local function Vector2ToUDim2(vec: Vector2)
    return UDim2.fromOffset(vec.X,vec.Y)
end

local function Marker(props)

    local position, setPosition = roact.useBinding(Vector3.zero)
    local rotation, setRotation = roact.useBinding(0)

    local _bindings = roact.joinBindings({position, props.MapScale})

    local target: BasePart = props.Target

    local icon

    if typeof(target) =="Instance" then


        local update = roact.useCallback(function()
            local _,Y_ROT = target.CFrame:ToOrientation()
                        
            setRotation(-math.deg(Y_ROT))
            setPosition(target.CFrame.Position) 
        end)

        if target:IsA("BasePart") then

            local player = game.Players:GetPlayerFromCharacter(target.Parent)

            if player ~= nil then
                icon = MarkerIcons.Player.Icon
            end



            roact.useEffect(function()
                local connection
                update()
                if player ~= nil then
                    connection = RunService.PreSimulation:Connect(function()
                        if target:IsDescendantOf(workspace) then
                            update()
                        end
                    end) 
                end
                return function ()
                    if connection then
                        connection:Disconnect()    
                    end
                end
            end)

        elseif target:IsA('Attachment') and target:HasTag('Waypoints') then
            
            
        end

        
    end

    return roact.createElement("ImageLabel", {
        ScaleType = Enum.ScaleType.Fit,
        Size = UDim2.fromOffset(30, 30),
        BackgroundTransparency = 1,
        Image = props.Icon or icon or "rbxasset://textures/ui/GuiImagePlaceholder.png",
        Rotation = rotation,
        AnchorPoint = Vector2.new(0.5, 0.5),

        Position = _bindings:map(roact.useCallback(function(v)
            local pos, scale = unpack(v)
            return Vector2ToUDim2(WorldToMapPosition(pos, scale))
        end)),
    })
end


local function MapElement(props)
    local style, api = roactSpring.useSpring(function()
        return {
            mapScale = props.Scale or 1,
            mapOffset = Vector2.zero,
            config = {

                tension = 170,
                friction = 35,
                --clamp = true,
                -- frequency = 0.4,
                -- damping = 0.3
            }
        }
    end)

    local markers, setMarkerState = roact.useState(CollectionService:GetTagged('MapMarker'))

    local mapOffset, mapScale = style.mapOffset, style.mapScale
    local joinedBindings = roact.joinBindings({mapOffset, mapScale})

    local LocalWorldToMapPosition = roact.useCallback(function(worldPos)
        return WorldToMapPosition(worldPos, mapScale:getValue())
    end)

    local WorldToUDim2 = roact.useCallback(function(worldPos)
        return Vector2ToUDim2(LocalWorldToMapPosition(worldPos))
    end)

    local RenderMarkers = roact.useCallback(function()
        local data = PlayerDataController.PlayerData and PlayerDataController.PlayerData.Replica

        local MapMarkers = tableUtil.Map(markers, function(v: Instance)
            return roact.createElement(Marker, {
                Target = v,
                MapScale = mapScale,
                MapOffset = mapOffset
            })
        end)

        return MapMarkers
    end)



    roact.useEffect(function()
        local Cleaner = trove.new()

        Cleaner:Connect(CollectionService:GetInstanceAddedSignal('MapMarker'), function(newMarker: Instance)
            setMarkerState(function(state)
                return {unpack(state), newMarker}
            end)
        end)

        Cleaner:Connect(CollectionService:GetInstanceRemovedSignal('MapMarker'), function(newMarker: Instance)
            setMarkerState(function(state)
                return tableUtil.Filter(state, function(v)
                    return newMarker ~= v
                end)
            end)
        end)

        if props.AllowMoving then

            local isDragging = false
            local lastMousePosition
            local lastMousePositionSet = 0

            Cleaner:Connect(UserInputService.InputBegan, function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    isDragging = true
                    lastMousePosition = input.Position
                end
            end)

            Cleaner:Connect(UserInputService.InputChanged, function(input)
                if isDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                    local delta = (input.Position - lastMousePosition) * 15
                    api.start {mapOffset = mapOffset:getValue() + Vector2.new(delta.X, delta.Y)}

                    if (os.clock() - lastMousePositionSet) > 0 then
                        lastMousePositionSet=os.clock()
                        lastMousePosition = input.Position
                    end

                elseif input.UserInputType == Enum.UserInputType.MouseWheel then

                    local currentScale = mapScale:getValue()
                    local offset = mapOffset:getValue()
                    local wheel = input.Position.Z

                    local newScale = math.clamp(currentScale + wheel * 0.2 , 0.1, 1)

                    local factor = newScale / currentScale
                    local centerViewport = workspace.CurrentCamera.ViewportSize/2

                    local delta = (Vector2.new(input.Position.X,input.Position.Y)-centerViewport-offset) * (1 - factor)

                    api.start {
                        mapScale = newScale;
                        mapOffset = offset + delta
                    }
                end
            end)

            Cleaner:Connect(UserInputService.InputEnded, function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    isDragging = false
                end
            end)
        end

        return function()
            Cleaner:Destroy()
        end
    end, {props.AllowMoving})


    local function old_renderMarkers(DataReplica)
        local Markers = {}

        Markers._SELECTION = CreateMarker {
            Icon = mapSettings.Markers.Marker.Icon,
        }

        -- Add player icon marker
        Markers._PLAYER = CreateMarker {
            Icon = mapSettings.Markers.Player.Icon,
            Position = joinedBindings:map(function()
                return WorldToUDim2(player.Character and player.Character:GetPivot().Position or Vector3.new(0, 0, 0))
            end),
        };

        if DataReplica then
            for i, data in pairs(DataReplica.Data.Map.Markers) do
                Markers[i] = CreateMarker {
                    Icon = mapSettings.Markers.Marker.Icon,
                    Position = joinedBindings:map(function()
                        return WorldToUDim2(Vector3.new(data[1][1], 0, data[1][3]))
                    end),
                }
            end
        end

        return Markers
    end



    return roact.createElement("Frame", {
        Size = UDim2.fromScale(0, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = joinedBindings:map(function(bindings)
            local offset = bindings[1]
            return UDim2.new(0.5, offset.X, 0.5, offset.Y)
        end),
    }, {
        Map = roact.createElement(roact.Fragment, nil, tableUtil.Map(mapSettings.MapImages, function(v)

            local x, y = v.Center.X - mapSettings.InitialPosition.X / 2, v.Center.Y - mapSettings.InitialPosition.Y / 2

            return roact.createElement("ImageLabel", {
                Image = v.Image,
                Size = joinedBindings:map(function(bindings)
                    local scale = bindings[2]
                    return UDim2.fromOffset(v.Size.X * scale, v.Size.Y * scale)
                end),
                Position = joinedBindings:map(function(bindings)
                    local scale = bindings[2]
                    return UDim2.fromOffset(x * scale, y * scale)
                end),
                BackgroundTransparency = 1,
                AnchorPoint = Vector2.new(0.5, 0.5),
            })

        end)),

        MarkerContainer = GUI.newElement("BlankFrame", {
            ClipsDescendants = false,
            ZIndex = 3,
        }, {
            Markers = GUI.newElement("BlankFrame", { ClipsDescendants = false, ZIndex = 3 }, RenderMarkers()),
        }),
    })
end

return MapElement

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SocialService = game:GetService("SocialService")
local TweenService = game:GetService("TweenService")
local mapSettings = require(ReplicatedStorage:WaitForChild"GameModules":WaitForChild"MapSettings")

local roact = require(game.ReplicatedStorage:WaitForChild('Utilities'):WaitForChild('Roact'))

local map = roact.PureComponent:extend('MapElement')

local Knit = require(ReplicatedStorage:WaitForChild('Packages'):WaitForChild('Knit'))
local GUI = Knit.GetController"GUI"

local packages = ReplicatedStorage:WaitForChild"Packages"
local trove = require(packages:WaitForChild"Trove")

local util = require(ReplicatedStorage:WaitForChild"Utilities":WaitForChild"Util")
local tweenInfo = TweenInfo.new(.7,Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

local player = game.Players.LocalPlayer
local PlayerDataController =  Knit.GetController("PlayerDataController")

local ANIMATESPEED = 7

function map:init()
    self.MarkerRef = roact.createRef()

    self.Cleaner = trove.new()
    self.animateTime = os.clock()
    self.Players = {}
    self:setState({update = 0})

    self:CreatePlayerMarker()
end

local function CreateMarker(props)
    return roact.createElement("ImageLabel", {
        ScaleType = Enum.ScaleType.Fit,
        Size = UDim2.fromOffset(30,30),
        BackgroundTransparency = 1,
        Image = props.Icon,
        AnchorPoint = Vector2.new(0.5,0.5),
        Position = props.Position and UDim2.fromOffset(props.Position.X,props.Position.y) or UDim2.fromScale(.5,.5),
        [roact.Ref] = props[roact.Ref]
    })
end

function map:CreatePlayerMarker(player)
    player = player or game.Players.LocalPlayer
    self.Players[player] = true
end

function map:UpdatePlayerPosition(PlayerMarkers, dt, initScale)

    
  
   
    local t = math.clamp(1-((self.animateTime-os.clock())/tweenInfo.Time),0,1)

    -- if self.props.Name ~= 'Minimap' and self.animateTime - os.clock() > 0 then
    --    -- print(t,1-((self.animateTime+1-os.clock())/tweenInfo.Time), self.animateTime - os.clock())    
    -- end
    

    local scale = initScale or self.props.Scale or 1
    local init = mapSettings.InitialPosition*scale
    for _,player in PlayerMarkers:GetChildren() do
        local playerObj: Player = Players:FindFirstChild(player.Name)
        if playerObj and playerObj.Character then
            local CF = playerObj.Character:GetPivot()
            local x,y = CF.Position.X, CF.Position.Z

         --   print(player.Position, scale)
            player.Position = player.Position:Lerp(UDim2.fromOffset(
                (x-init.X/2) + (x*scale - x), --* easeInOutQuad(t),
                (y-init.Y/2) + (y*scale - y) --* easeInOutQuad(t)
            ),self.props.DisableMarkerAnimation and 1 or dt*ANIMATESPEED)

            local _,yRot = CF:ToOrientation()
            player.Rotation = math.deg(-yRot)
        end
    end
end

function map:UpdateMarkerPosition(Markers, dt, initScale, onlySelectionMarker)
    
   -- print('select position', self.props.SelectPosition)
   local DataReplica = PlayerDataController:GetPlayerData().Replica

    local SelectionMarker = Markers._SELECTION
    local scale = initScale or self.props.Scale or 1

    SelectionMarker.Visible = self.MarkerSelectPosition ~= nil
    if self.MarkerSelectPosition then
        --local Pos = self:ToMapPosition(Vector2.new(self.props.SelectPosition.X,self.props.SelectPosition.Y))  
        local Pos = self.MarkerSelectPosition
        SelectionMarker.Position = SelectionMarker.Position:Lerp(UDim2.fromOffset(
            Pos.X + (Pos.X * scale - Pos.X),
            Pos.Y + (Pos.Y * scale - Pos.Y)
        ), self.props.DisableMarkerAnimation and 1 or dt*ANIMATESPEED) 
    end

    if not onlySelectionMarker then
        local markerData = DataReplica.Data.Map.Markers
   --     print(self.props.Scale)
        for _, marker in Markers:GetChildren() do
            local data = markerData[marker.Name]
            if data then
                local pos = self:WorldToMapPosition(Vector3.new(
                    data[1][1],0,data[1][3]
                ))
                marker.Position = marker.Position:Lerp(UDim2.fromOffset(pos.X,pos.Y), self.props.DisableMarkerAnimation and 1 or dt*ANIMATESPEED)
            end
        end
    end
end

function map:didMount()
    if not self.props.Disabled then
        self:Initiate()    
    end
    self:setMapScale(self.props.Scale)
end

function map:Initiate(initScale)
    if self.Cleaner then
        self.Cleaner:Destroy()
    end
    self.Cleaner = trove.new()
    local runServ = game:GetService'RunService' 

    local MarkerContainer = self.MarkerRef:getValue()
    local PlayerMarkers = MarkerContainer.Players
    local Markers = MarkerContainer.Markers

    self:UpdatePlayerPosition(PlayerMarkers, .2, initScale)
    print('Initiated map')
    --local scale = self.props.Scale or 1
    self.Cleaner:Connect(runServ.Heartbeat, function(dt)
        --print('Rendering map',self.props.Name)
        self:UpdatePlayerPosition(PlayerMarkers, dt)
        self:UpdateMarkerPosition(Markers, dt)
    end)

    local DataReplica = PlayerDataController:GetPlayerData().Replica

    self.Cleaner:Add(DataReplica:ListenToRaw(function(_,path)
        if path[1]=='Map' and path[2]=='Markers' then
            self:setState {update = self.state.update + 1}
        end
    end))
end

function map:WorldToMapPosition(worldPos:Vector3)
    local init = mapSettings.InitialPosition
    local scale = self.props.Scale
    local x,y = worldPos.X, worldPos.Z
    return Vector2.new(
        (x-init.X/2)*scale, --+ (x*scale - x), --* easeInOutQuad(t),
        (y-init.Y/2)*scale --+ (y*scale - y)
    ) --* easeInOutQuad(t))
end

function map:ToWorldPosition(mapPosition, _scale)
    local init = mapSettings.InitialPosition
    local scale = _scale or self.props.Scale
    print(scale)
    local pos = (mapPosition + init/2)-- +     (mapPosition * scale - mapPosition) --* scale

    local result = workspace:Raycast(
        Vector3.new(pos.X,10000,pos.Y),
        Vector3.new(0,-10000,0)
    )

    local y = player.Character:GetPivot().Y

    if result and result.Position then
        y = result.Position.Y + 3
    end

    return Vector3.new(
            pos.X,
            y,
            pos.Y
        )
end

function map:ToMapPosition(position: Vector2, _scale, _mapFrame)
    local mapFrame = _mapFrame or self.props[roact.Ref]:getValue()
    local scale = _scale or self.props.Scale
    local absPos = mapFrame.AbsolutePosition
    local pos = Vector2.new(position.X,position.Y)
    
    local p = pos - absPos

    return p/scale
end

function map:setMapScale(scale)
    local mapFrame = self.props[roact.Ref]:getValue()
    local initPos = mapSettings.InitialPosition

    for _, v:ImageLabel in mapFrame:GetChildren() do
        if v:IsA('ImageLabel') then
            local info = mapSettings.MapImages[tonumber(v.Name)]
            local _x,_y = info.Center.X - initPos.X/2, info.Center.Y-initPos.Y/2
            
            TweenService:Create(v, tweenInfo, {
                Size = UDim2.fromOffset(info.Size.X*scale,info.Size.Y*scale),
                Position = UDim2.fromOffset(_x*scale,_y*scale)
            }):Play()

            -- v.Size = v.Size:Lerp(UDim2.fromOffset(info.Size.X*scale,info.Size.Y*scale),t)
            -- v.Position = v.Position:Lerp(UDim2.fromOffset(_x*scale,_y*scale),t)
        end
    end
end

function map:didUpdate(prevProps)

   -- local mapFrame = self.props[roact.Ref]:getValue()
    
    self.animateTime = os.clock() + tweenInfo.Time
    local scale = self.props.Scale
  --  local initPos = mapSettings.InitialPosition

    if self.props.Disabled and self.Cleaner then
       -- print('Disabled cleaner')
        self.Cleaner:Destroy()
    end

    if prevProps.Scale ~= scale then
        self:setMapScale(scale)
    end
    
 
    if prevProps.Disabled ~= self.props.Disabled and not self.props.Disabled then
        self:Initiate(self.props.DisabledScale)
     end

     --print('Updated select position:',self.props.SelectPosition)
     
     if self.props.SelectPosition and self.props.SelectPosition ~= prevProps.SelectPosition then
        self.MarkerSelectPosition = self:ToMapPosition(self.props.SelectPosition)
        self:UpdateMarkerPosition(self.props[roact.Ref]:getValue().MarkerContainer.Markers, 1/ANIMATESPEED, nil, true)
     elseif self.props.SelectPosition == nil then
        self.MarkerSelectPosition = nil
     end
 
end

function map:UDim2ToVector2(value: UDim2)
    return Vector2.new(value.X.Offset,value.Y.Offset)
end

function map:render()
    local mapImages = {}

   -- print(scale)

    for i,v in mapSettings.MapImages do
        local x,y = v.Center.X - mapSettings.InitialPosition.X/2, v.Center.Y-mapSettings.InitialPosition.Y/2
        mapImages[i] = roact.createElement('ImageLabel', {
            Image = v.Image,
            Size = UDim2.fromOffset(v.Size.X,v.Size.Y),
            Position = UDim2.fromOffset(x,y),
            BackgroundTransparency = 1,
            AnchorPoint = Vector2.new(0.5,0.5)
        })
    end

    local PlayerMarkers = {}

    for _player,_ in self.Players do
        PlayerMarkers[_player.Name] = CreateMarker {
            Icon = mapSettings.Markers.Player.Icon,
            
        }
    end

    local Markers = {}

    Markers._SELECTION = CreateMarker {
        Icon = mapSettings.Markers.Marker.Icon,
    }
    local DataReplica = PlayerDataController:GetPlayerData().Replica
    for i, data in DataReplica.Data.Map.Markers do
        Markers[i] = CreateMarker {
            Icon = mapSettings.Markers.Marker.Icon,
            Position = self.props.Disabled and self:WorldToMapPosition(Vector3.new(
                data[1][1],0,data[1][3]
            )),
        }
    end
    

    return roact.createElement('Frame', {
        Size = UDim2.fromScale(0,0),
        AnchorPoint = Vector2.new(.5,.5),
        [roact.Ref] = self.props[roact.Ref]
    }, {
        Map = roact.createFragment(mapImages),
        MarkerContainer = GUI.newElement('BlankFrame', {
            ClipsDescendants=false,
            ZIndex=3,
            [roact.Ref] = self.MarkerRef
        }, {
            Players = GUI.newElement('BlankFrame', {ClipsDescendants = false, ZIndex = 5}
            , PlayerMarkers),
            Markers = GUI.newElement('BlankFrame', {ClipsDescendants = false, ZIndex = 3}
            , Markers)
        })
    })
end

return map
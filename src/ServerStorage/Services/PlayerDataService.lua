local UseMockOnStudio = true
local StoreName = "PlayerDataTEST4"

local packages = game.ReplicatedStorage.Packages
local knit = require(packages.Knit)
local signal = require(packages.Signal)

local serverScriptService = game:GetService"ServerScriptService"
local profileService = require(serverScriptService.ProfileService)
local replicaService = require(serverScriptService.ReplicaService)
local HttpService = game:GetService"HttpService"
local runService = game:GetService"RunService"

local dataReplicaToken = replicaService.NewClassToken("PlayerData")

local profileStore, dataTemplate = nil, {}

local service = knit.CreateService{
    Name = script.Name,
    Client = {}
}

local InvalidDataIndexes = {"Profile","Replica"}

local Misc = game.ReplicatedStorage.Utilities.Misc
local PlayerDataClass = require(Misc.PlayerDataClass)


service.PlayerAdded = signal.new()

local PlayerData = {}
local LoadWait = {}

local function onPlayerLeave(player)
    if PlayerData[player] then
        print(`{player.Name} left the server, successfully released their profile`)
        PlayerData[player].Profile:Release()
    end
end

local function GetTableSize(t)
    return #HttpService:JSONEncode(t)
end

local function onPlayerJoin(player:Player)
    local profile = profileStore:LoadProfileAsync(tostring(player.UserId))
    if profile ~= nil then
        profile:AddUserId(player.UserId)
        profile:Reconcile()
        profile:ListenToRelease(function()
            PlayerData[player].Replica:Destroy()
            player:Kick()
        end)
        if player:IsDescendantOf(game.Players) == true then
            local replica = replicaService.NewReplica({
                ClassToken = dataReplicaToken,
                Data = profile.Data,
                Replication = player,
                Tags = {Player = player}
            })
            replica:AddCleanupTask(function()
                local data = PlayerData[player]
                data.Replica = nil
                data.Profile = nil
                PlayerData[player] = nil
            end)
            PlayerData[player] = setmetatable({
                Replica = replica,
                Profile = profile
            },PlayerDataClass)
            print(`{player.Name} ({player.UserId}) has joined the server. their data:`, PlayerData[player])
            service.PlayerAdded:Fire(player, PlayerData[player])
        else
            print(`{player.Name} left the server while loading profile and successfully released it`)
            profile:Release()
        end
    else
        player:Kick() 
    end
    
    local data = service:GetPlayerData(player)
    player.Chatted:Connect(function(message)
        local args = message:split(" ")
        if args[1] == 'viewdata' then
            print(data.Profile.Data)
        elseif args[1] == 'size' then
            local index = args[2]
            local size = GetTableSize(index and data[index] or data.Profile.Data)
            local percentage = (size/4000000)*100
            
            print(`{index or "whole data"} has a size of {size}, and used {percentage}% of space`)
        end
    end)
end

function service:GetPlayerData(player)
    return PlayerData[player]
end

function service:RegisterDataIndex(DataIndex, template)
    if not table.find(InvalidDataIndexes, DataIndex) then
        dataTemplate[DataIndex] = template
    else
        error(`Cannot use index {DataIndex} to register data index`)    
    end
    
end

function service:AwaitLoad(waitCode)
    LoadWait[waitCode] = false
end

function service:LoadReady(waitCode)
    LoadWait[waitCode] = true
end

function service:AreAwaitsReady()
    for _, ready in LoadWait do
        if not ready then return false end
    end
    return true
end

function service:KnitStart()    
    profileStore = profileService.GetProfileStore(StoreName, dataTemplate)
    if runService:IsStudio() and UseMockOnStudio == true then
        warn("Server is running on studio, ProfileService will use Mock")
        profileStore = profileStore.Mock
    end

    task.defer(function()
        
        if service:AreAwaitsReady() == false then          
            local ready, lastWarn = false, 0
            while not ready do
                ready = true
                task.wait()
                for waitCode, waitReady in LoadWait do
                    if not waitReady then
                        ready = false
                        if os.clock() - lastWarn > 4 then
                            lastWarn = os.clock()
                            warn(`PlayerDataService is not proceeding: Awaiting for code {waitCode}`)
                        end
                        break
                    end
                end
            end
        end

        for _, player in game.Players:GetPlayers() do
            task.spawn(onPlayerJoin,player)
        end
        game.Players.PlayerAdded:Connect(onPlayerJoin)

        game.Players.PlayerRemoving:Connect(onPlayerLeave)
    end)

end

return service
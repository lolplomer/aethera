local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)

local ReplicaStressTest = Knit.CreateService {
    Name = "ReplicaStressTest",
    Client = {},
}

-- regular remote events: 570kb/s (unopened console log) 610-620 kb/s (opened console log)

-- bridgenet2: 143kb/s
function ReplicaStressTest:KnitStart()
    
end


function ReplicaStressTest:KnitInit()
    -- local ReplicaService = require(game.ServerScriptService.ReplicaService)
    -- local Token = ReplicaService.NewClassToken('StressTest')

    -- local playerDataService = Knit.GetService('PlayerDataService')
  

    -- playerDataService.PlayerAdded:Connect(function(player)
    --     print('player stresser joined',player)

    --     local REPLICA = ReplicaService.NewReplica {
    --         Replication = player,
    --         Tags = {Player = player},
    --         ClassToken = Token,
    --         Data = {
    --             Value = 0,
    --             STR = "SADSADAS",
    --         }
    --     }

    --     local started = false 

    --     player.Chatted:Connect(function(msg)
    --         print(msg, 'initiated strss')
    --         if msg == 'start stress' then
    --             if started then return end
    --             started = true
    --             print('Starting stress...')
    --             local i = 0
    --             while started do
    --                 task.wait()
    --                 local v = math.random()

    --                 for _ = 1,4 do
    --                     REPLICA:SetValue('Value',v)
    --                     local str = ""
    --                     for _ = 1,500 do
    --                         str ..= string.char(math.random(46,100))
    --                     end
    --                     REPLICA:SetValue('STR',str)
    --                     i+=2
    --                 end
                   
    --                 print('Executed',i,'remote calls')
    --             end
    --         elseif msg == 'stop stress' then
    --             started = false
    --         end
    --     end)
    -- end)
end


return ReplicaStressTest

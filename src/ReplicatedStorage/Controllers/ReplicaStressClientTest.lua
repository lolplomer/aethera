local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)

local ReplicaStressClientTest = Knit.CreateController { Name = "ReplicaStressClientTest" }


function ReplicaStressClientTest:KnitStart()
    -- local PlayerReplicaController = Knit.GetController('PlayerReplicaController')
    -- local REPLICA = PlayerReplicaController:GetReplica('StressTest').Replica

    -- REPLICA:ListenToRaw(function(_,path, value)
    --     print(path[1], 'Changed:', value)
    -- end)

    -- REPLICA:ListenToChange({'Value'}, function(value, old)
    --     print('StressTest value changed:',value,'OLD:',old)
    -- end)
end 


function ReplicaStressClientTest:KnitInit()
 
end
 

return ReplicaStressClientTest

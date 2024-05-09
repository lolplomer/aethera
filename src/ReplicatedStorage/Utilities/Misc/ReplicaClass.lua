local ReplicaClass = {}
ReplicaClass.__index = function(self, index)
    local Replica = rawget(self, 'Replica')
    return rawget(self,index) or (Replica and Replica.Data[index])
end

function ReplicaClass.new(replica, extraParameters)
    local t = extraParameters
    if t then
        t.Replica = replica
    else
        t = {Replica = ReplicaClass}
    end
    return setmetatable(t, ReplicaClass)
end

return ReplicaClass

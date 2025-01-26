local PlayerDataClass = {}
PlayerDataClass.__index = function(self, index)
    return rawget(self,index) or self.Replica.Data[index] -- changed from self.Replica
end

return PlayerDataClass

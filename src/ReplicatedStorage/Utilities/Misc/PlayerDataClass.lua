local PlayerDataClass = {}
PlayerDataClass.__index = function(self, index)
    return rawget(self,index) or self.Replica.Data[index]
end

return PlayerDataClass

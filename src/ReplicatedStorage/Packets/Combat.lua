local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ByteNet = require(ReplicatedStorage.Packages.bytenet)

return ByteNet.defineNamespace('Combat', function()
    return {
        NormalAttack = ByteNet.definePacket {
            value = ByteNet.inst
        }
    }
end)
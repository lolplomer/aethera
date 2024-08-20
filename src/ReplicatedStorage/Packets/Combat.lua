local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ByteNet = require(ReplicatedStorage.Packages.bytenet)

return ByteNet.defineNamespace('Combat', function()
    return {
        NormalAttack = ByteNet.definePacket {
            value = ByteNet.inst
        },
        DamageCounter = ByteNet.definePacket {
            value = ByteNet.struct {
                damage = ByteNet.float64,
                position = ByteNet.vec3,
                crit = ByteNet.bool
            }
        }
    }
end)
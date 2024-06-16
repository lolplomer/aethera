local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ByteNet = require(ReplicatedStorage.Packages.bytenet)

return ByteNet.defineNamespace('Mob', function()
    return {
        CFrame = ByteNet.definePacket {
            value = ByteNet.struct {
                At = ByteNet.vec3,
                Direction = ByteNet.vec3,
                Model = ByteNet.inst
            },
            reliabilityType = 'unreliable'
        },
        Render = ByteNet.definePacket {
            value = ByteNet.inst
        },
        Unrender = ByteNet.definePacket {
            value = ByteNet.inst
        },
        State = ByteNet.definePacket {
            value = ByteNet.struct {
                Model = ByteNet.inst,
                State = ByteNet.string
            }
        }
    }
end)
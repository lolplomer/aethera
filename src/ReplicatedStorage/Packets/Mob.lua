local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ByteNet = require(ReplicatedStorage.Packages.bytenet)

return ByteNet.defineNamespace('Mob', function()
    return {
        CFrame = ByteNet.definePacket {
            value = ByteNet.struct {
                At = ByteNet.vec3,
                Direction = ByteNet.vec3,
                Model = ByteNet.inst,
                State = ByteNet.string,
                Instant = ByteNet.optional(ByteNet.bool),
                Duration = ByteNet.optional(ByteNet.float64)
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
        },
        Animation = ByteNet.definePacket {
            value = ByteNet.struct {
                Model = ByteNet.inst,
                Animation = ByteNet.string,
                Category = ByteNet.optional(ByteNet.string)
            }
        }
    }
end)
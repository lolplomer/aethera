local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ByteNet = require(ReplicatedStorage.Packages.bytenet)

return ByteNet.defineNamespace('Effect', function()
    return {
        Spawn = ByteNet.definePacket {
            value = ByteNet.struct {
                Effect = ByteNet.string,

                Position = ByteNet.optional(ByteNet.vec3),
                Orientation = ByteNet.optional(ByteNet.array(ByteNet.float64)),

                Parent = ByteNet.optional(ByteNet.inst),
                --CFrame = ByteNet.optional(ByteNet.cframe),
                -- Position = (ByteNet.vec3),
                -- Orientation = ByteNet.vec3,
                Lifetime = ByteNet.optional(ByteNet.float64),
                Emit = ByteNet.optional(ByteNet.float64),

                Number1 = ByteNet.optional(ByteNet.float64),
                Number2 = ByteNet.optional(ByteNet.float64),

                Bool1 = ByteNet.optional(ByteNet.bool),
            },
            reliabilityType = 'unreliable'
        }
    }
end)
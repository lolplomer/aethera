local ReplicatedStorage = game:GetService("ReplicatedStorage")
local promise = require(ReplicatedStorage.Utilities.Promise)
local knit = require(ReplicatedStorage.Packages.Knit)

local action = {}

function action.Initiate(mob)

    local EffectService = knit.GetService('EffectService')

    return {
        Cooldown = 2.2,

        TargetMinimumDistance = 8,

        Trigger = function()

            return promise.new(function(resolve)
                local targetPlayer: Player = mob.Target
                
                mob:PlayAnimation('Attack')

                EffectService:SpawnEffect('Slash-02', {
                    Parent = mob.Root,
                    --CFrame = mob.Root.CFrame,
                    Bool1 = false,
                    Number1 = 45,
                    Number2 = 180
                })

                task.wait(0.15)
                local result: RaycastResult = mob:CastSingleTargetAttack(6, 6, targetPlayer.Character)
                if result then
                    EffectService:SpawnEffect('Hit', {
                        Parent = result.Instance,
                    })
                end

                resolve()
            end)
            

        end,
    }
end

return action
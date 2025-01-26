local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Knit = require(ReplicatedStorage.Packages.Knit)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Table = require(ReplicatedStorage.Packages.TableUtil)

local ShakeController = Knit.CreateController { Name = "ShakeController" }

ShakeController.Shakes = {}
local running = {};

local player = Players.LocalPlayer

local function step(dt)
    local magnitude = 0;

    local Final = CFrame.new()
    if next(running) then
        local t = table.create(#running)
        for fn, _ in running do
            
            local CF:CFrame = fn(running[fn].time)
            if CF.Position.Magnitude > magnitude then
                magnitude = CF.Position.Magnitude
            end
            table.insert(t,CF)

            running[fn].time += dt;

            if running[fn].time > running[fn].stopAfter then
                running[fn] = nil
            end
        end
    
        local Offset: CFrame = Table.Reduce(t, function(accum, CF)
            return accum * CF
        end, CFrame.new())
    
        local currentOffsetMagnitude = Offset.Position.Unit.Magnitude
        local isNAN  = currentOffsetMagnitude ~= currentOffsetMagnitude

        Final = (magnitude > 0 and not isNAN) and CFrame.new(Offset.Position.Unit * magnitude) * (Offset - Offset.Position) or CFrame.new()
    end

    local Char = player.Character
    if Char then
        Char.Humanoid.CameraOffset =Char.Humanoid.CameraOffset:Lerp(Final.Position, dt*10)
    end
end


function  ShakeController:NewShake(Data,Name)
    self.Shakes[Name] = Data
end

function  ShakeController:Start(Name,Time)
    local Shake = self.Shakes[Name]

    if not Shake then return end

    running[Shake] = {time = 0, stopAfter = Time or math.huge};
end

function ShakeController:Stop(Name)
    local Shake = self.Shakes[Name]
    
    if not Shake then return end

    if running[Shake] then
        running[Shake] = nil;
    end
end

function ShakeController:KnitInit()
    self:NewShake(function(t)
        return CFrame.new(math.sin(-t*10)*0.6, (math.cos(-t*2*10)+1)*0.5*0.6,0)
    end, "Running")

    local hitFreq,hitAmp = 15,1;
    local function Cosine(t,freq,amp,n)
        return t < (((math.pi/2)+(math.pi))/freq)*n and math.cos(t*freq) * amp or 0
    end

    local function Sine(t,freq,amp,n)
        return (t < (math.pi/freq)*n ) and math.sin(-t * freq) * amp or 0
    end

    self:NewShake(function(t)
       return CFrame.new(-Sine(t,hitFreq,hitAmp,1),0,0)
    end, "Hit1")
    
    self:NewShake(function(t)
       return CFrame.new(0,0,Sine(t,hitFreq,1,1))
     end, "Lunge")


    self:NewShake(function(t)
        return CFrame.new(Sine(t,hitFreq,hitAmp,1),0,0)
     end, "Hit2")

end

function ShakeController:KnitStart()
    game:GetService("TextChatService").SendingMessage:Connect(function(message:string)
        local args = message.Text:split(' ')
        if args[1] == "shake" then
            self:Start(args[2])
        elseif args[1]=='stopshake' then
            self:Stop(args[2])
        end
    end)

    RunService.RenderStepped:Connect(step)
end

return ShakeController

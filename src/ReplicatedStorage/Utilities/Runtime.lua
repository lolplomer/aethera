local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Runtime = {}
Runtime.__index = Runtime

local Trove = require(ReplicatedStorage.Packages.Trove)
local Signal = require(ReplicatedStorage.Packages.Signal)

local DebugMode = false

function Runtime.new()
    local self = setmetatable({
        TimePosition = 0,
        Keyframes = {},
        Trove = Trove.new(),
        IsPlaying = false,
        IsPaused = false,
        Keyframe = 0,
        LastStep = 0,
        WaitTime = 0,
        Duration = 0 -- Default to 0 if no Duration is provided
    }, Runtime)

    self.Changed = self.Trove:Construct(Signal)
    self.Completed = self.Trove:Construct(Signal)
    self.KeyframeChanged = self.Trove:Construct(Signal)
    
    return self
end

function Runtime.newKeyframe(TimePosition, Value, Name)
    return {
        [1] = TimePosition, 
        [2] = Value, 
        [3] = Name,
    
        TimePosition = TimePosition,
        Value = Value,
        Name = Name
    
    }
end

function Runtime:SetWaitTime(t)
    self.WaitTime = t
end

function Runtime:AddKeyframe(TimePosition, Value)
    --print('New keyframe added',TimePosition,Value)
    table.insert(self.Keyframes, Runtime.newKeyframe(TimePosition, Value))
    -- Update Duration if TimePosition exceeds current Duration
    if TimePosition > self.Duration then
        self.Duration = TimePosition
    end
    return self
end

function Runtime:ReplaceKeyframes(keyframes)
    self:Stop()
    self.Keyframes = keyframes
    self:Recalibrate()
    self.Duration = self.Keyframes[#self.Keyframes][1]

    if typeof(keyframes[1][2]) == "Vector3" and DebugMode then
        local util = require(ReplicatedStorage.Utilities.Util)

        if self.Debug then
            self.Debug:Destroy()
        end

        self.Debug = Trove.new()

        for _,v in keyframes do
            self.Debug:Add(util.new('Part', {
                Size = Vector3.one,
                Position = v[2],
                Parent = workspace,
                Color = Color3.new(0,1,0),
                Anchored = true,
                Material = 'Neon',
                Transparency = 0.6,
                CanQuery = false,
                CanTouch = false,
                CanCollide = false
            }))
        end
    end
    
    
end

function Runtime:Recalibrate()
    table.sort(self.Keyframes, function(a,b)
        return a[1] < b[1]
    end)
    return self
end

function Runtime:Play()
    if self.IsPlaying and not self.IsPaused then return end
    self:Recalibrate()

    self.IsPaused = false
    if self.IsPlaying then return end

    self.IsPlaying = true


    --warn('--- Playing ---')

    if self.PlayingState then
        self.PlayingState:Clean()
    end

    self.PlayingState = self.Trove:Extend()

    self.PlayingState:Add(function()
        self.PlayingState = nil    
    end)

    self.PlayingState:Connect(RunService.Heartbeat, function(dt)
        if not self.IsPaused then
            if (os.clock() - self.LastStep) > self.WaitTime then
                self.LastStep = os.clock()
                self:SetTimePosition(self.TimePosition + self.WaitTime + dt)  
            end
              
        end
        
    end)

    -- task.spawn(function()
    --     while self.IsPlaying and not self.IsPaused do
    --         self:SetTimePosition(self.TimePosition + task.wait())
    --     end
    -- end)
end

function Runtime:Pause()
    if not self.IsPlaying then return end
    self.IsPaused = true
end

function Runtime:Stop()
    self.IsPlaying = false
    self.IsPaused = false
    self.TimePosition = 0
    self.Keyframe = 0

    if self.PlayingState then
        self.PlayingState:Clean()
    end
    --self.Trove:Clean()
end

function Runtime:Destroy()
    self.Trove:Destroy()
end

function Runtime:Interpolate(timePosition)
    local before, after
    for i = 1, #self.Keyframes - 1 do
        if self.Keyframes[i][1] <= timePosition and self.Keyframes[i+1][1] >= timePosition then
            before = self.Keyframes[i]
            after = self.Keyframes[i+1]
            if self.Keyframe ~= i then
                self.Keyframe = i

                self.KeyframeChanged:Fire(before, after)
            end
            break
        end
    end

    if not before then
        return self.Keyframes[1][2], self.Keyframes[1][2] -- Return the first keyframe value if timePosition is before the first keyframe
    end

    if not after then
        return self.Keyframes[#self.Keyframes][2], self.Keyframes[#self.Keyframes][2]  -- Return the last keyframe value if timePosition is after the last keyframe
    end

    local alpha = (timePosition - before[1]) / (after[1] - before[1])
    --print(alpha)
    return before[2] + alpha * (after[2] - before[2]), after[2], before[3]
end


function Runtime:SetTimePosition(newTimePosition)
    self.TimePosition = math.clamp(newTimePosition, 0, self.Duration)
    local value, point, name = self:Interpolate(self.TimePosition)
    self.Changed:Fire(value, point, name)
    if self.TimePosition >= self.Duration and self.IsPlaying then
        self:Stop()
        self.Completed:Fire()
    end
end

return Runtime

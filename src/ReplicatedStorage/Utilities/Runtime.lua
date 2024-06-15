local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Runtime = {}
Runtime.__index = Runtime

local Trove = require(ReplicatedStorage.Packages.Trove)
local Signal = require(ReplicatedStorage.Packages.Signal)

function Runtime.new()
    local self = setmetatable({
        TimePosition = 0,
        Keyframes = {},
        Trove = Trove.new(),
        IsPlaying = false,
        IsPaused = false,
        Duration = 0 -- Default to 0 if no Duration is provided
    }, Runtime)

    self.Changed = self.Trove:Construct(Signal)
    self.Completed = self.Trove:Construct(Signal)

    return self
end

function Runtime.newKeyframe(TimePosition, Value)
    return {TimePosition, Value}
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
    self.IsPlaying = true
    self.IsPaused = false

    task.spawn(function()
        while self.IsPlaying and not self.IsPaused do
            self:SetTimePosition(self.TimePosition + task.wait())
        end
    end)
end

function Runtime:Pause()
    if not self.IsPlaying then return end
    self.IsPaused = true
end

function Runtime:Stop()
    self.IsPlaying = false
    self.IsPaused = false
    self.TimePosition = 0
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
            break
        end
    end

    if not before then
        return self.Keyframes[1][2] -- Return the first keyframe value if timePosition is before the first keyframe
    end

    if not after then
        return self.Keyframes[#self.Keyframes][2] -- Return the last keyframe value if timePosition is after the last keyframe
    end

    local alpha = (timePosition - before[1]) / (after[1] - before[1])
    return before[2] + alpha * (after[2] - before[2]), after[2]
end


function Runtime:SetTimePosition(newTimePosition)
    self.TimePosition = math.clamp(newTimePosition, 0, self.Duration)
    local value, point = self:Interpolate(self.TimePosition)
    self.Changed:Fire(value, point)
    if self.TimePosition >= self.Duration and self.IsPlaying then
        self:Stop()
        self.Completed:Fire()
    end
end

return Runtime

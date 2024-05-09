local Rating = {
    F = {
        Label = "F",
        Color = Color3.fromHex("D9D9D9"),
        OuterColor = Color3.fromHex("A1A3AD"),
        Icon = "rbxassetid://13836251798",
        IconRatio = 41.2/53.1,
        Rank = 1,
    },
    D = {
        Label = 'D',
        Color = Color3.fromRGB(214, 69, 65),
        Icon = "rbxassetid://13836252747",
        IconRatio = 49.01/53.1,
        Rank = 2,
    },
    C = {
        Label = 'C',
        Color = Color3.fromRGB(244, 176, 52),
        Icon = "rbxassetid://13836251988",
        IconRatio = 45.47/54.26,
        Rank = 3,
    },
    B = {
        Label = 'B',
        Color = Color3.fromHex("#60B054"),
        Icon = "rbxassetid://13836252999",
        IconRatio = 39.92/53.1,
        Rank = 4,
    },
    A = {
        Label = 'A',
        Color = Color3.fromHex("#4372B3"),
        Icon = "rbxassetid://13836252513",
        IconRatio = 49.01/54.96,
        Rank = 5,
    },
    S = {
        Label = 'S',
        Color = Color3.fromRGB(255, 174, 66),
        Icon = "rbxassetid://13836252250",
        IconRatio = 43.38/53.61,
        Rank = 6,
    },
    SS = {
        Label = 'SS',
        Color = Color3.fromRGB(255, 215, 0),
        Icon = "rbxassetid://13836253406",
        IconRatio = 65.45/53.61,
        Rank = 7,
    },
}

local function Init()
    for rating, info in Rating do
        info.Key = rating
    end
end

Init()

Rating.Default = Rating.F

return setmetatable(Rating, {
    __index = function(self, index)
        return rawget(self, index)
    end,
    __call = function(self)
        return self.Default
    end,
})
local settings = {}

settings.InitialPosition = Vector2.new(-10, -430)

settings.MapImages = {
    -- {
    --     Image = "rbxassetid://17467626820",
    --     Size = Vector2.new(820, 920),
    --     Center = Vector2.new(-10, -430)
    -- },
    {
        Image = "rbxassetid://18535377056",
        Size = Vector2.new(1346.24, 1037.832),
        Center = Vector2.new(-47.145, -414.296)
    },
    {
        Image = "rbxassetid://18535375984",
        Size = Vector2.new(1346.24, 1037.832),
        Center = Vector2.new(-47.145, -1445.09)
    },
    {
        Image = "rbxassetid://18535375659",
        Size = Vector2.new(499.022, 1314.427),
        Center = Vector2.new(854.921, -918.799)
    },
    -- {
    --     Image = "rbxassetid://17471280359",
    --     Size = Vector2.new(1240, 550),
    --     Center = Vector2.new(65, 320)
    -- }
}

settings.Markers = {
    Player = {
        Icon = "rbxassetid://17472347649"
    },
    Marker = {
        Icon = "rbxassetid://17480523426"
    }
}

settings.AbsoluteCenterPosition = Vector2.new()

do
    local sum = Vector2.new()
    for _, v in settings.MapImages do
        sum += v.Center
    end
    settings.AbsoluteCenterPosition = sum / #settings.MapImages
end

return settings
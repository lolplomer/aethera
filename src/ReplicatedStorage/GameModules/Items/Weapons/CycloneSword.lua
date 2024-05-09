local item = {
    Rating = "S",
    DisplayName = "Cyclone Sword",

    Description = 
[[
    
A legendary zephyr weapon, wields the power of wind. 
Its swirling blade cuts through foes with lightning speed, 
guided by the bearer's mastery. A treasure of the chosen, 
it symbolizes the might of the Zephyr    

]],

    Stackable = false,
    Model = "CycloneSword",
    Icon = {
        ViewportOffset = CFrame.Angles(0,0,-math.rad(5))
    },
    Equipment = {
        Stats = {
            ATK = {25},
            MP = {70}
        },
        Type = "Weapon",
        Subtype = "Sword",
    },
    Data = {
        Lvl = 78,
        Substats = {
            DEF = {70},
            CRITDMG = {0.36},
            CRITRATE = {0.12},
            MOVSPD = {0.3}
        }
    }
}


return item
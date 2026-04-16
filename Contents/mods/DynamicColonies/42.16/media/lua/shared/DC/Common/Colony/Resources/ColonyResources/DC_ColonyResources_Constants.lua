DC_Colony = DC_Colony or {}
DC_Colony.Resources = DC_Colony.Resources or {}
DC_Colony.Resources.Internal = DC_Colony.Resources.Internal or {}

local Resources = DC_Colony.Resources
local Internal = Resources.Internal

Internal.RESOURCE_SCHEMA_VERSION = Internal.RESOURCE_SCHEMA_VERSION or 1

Resources.CROP_CATALOG = Resources.CROP_CATALOG or {
    Cabbage = {
        cropID = "Cabbage",
        displayName = "Cabbage",
        seedFullTypes = { "Base.CabbageSeed", "Base.CabbageBagSeed2" },
        produceFullType = "Base.Cabbage",
        growthHours = 292,
        tempMinC = 12,
        tempMaxC = 22,
        harvestMin = 2,
        harvestMax = 4
    },
    Broccoli = {
        cropID = "Broccoli",
        displayName = "Broccoli",
        seedFullTypes = { "Base.BroccoliSeed", "Base.BroccoliBagSeed2" },
        produceFullType = "Base.Broccoli",
        growthHours = 292,
        tempMinC = 14,
        tempMaxC = 22,
        harvestMin = 2,
        harvestMax = 4
    },
    Carrot = {
        cropID = "Carrot",
        displayName = "Carrot",
        seedFullTypes = { "Base.CarrotSeed", "Base.CarrotBagSeed2" },
        produceFullType = "Base.Carrots",
        growthHours = 432,
        tempMinC = 10,
        tempMaxC = 20,
        harvestMin = 3,
        harvestMax = 6
    },
    Potato = {
        cropID = "Potato",
        displayName = "Potato",
        seedFullTypes = { "Base.PotatoSeed", "Base.PotatoBagSeed2" },
        produceFullType = "Base.Potato",
        growthHours = 432,
        tempMinC = 8,
        tempMaxC = 18,
        harvestMin = 3,
        harvestMax = 4
    },
    Radish = {
        cropID = "Radish",
        displayName = "Radish",
        seedFullTypes = { "Base.RedRadishSeed", "Base.RedRadishBagSeed2" },
        produceFullType = "Base.RedRadish",
        growthHours = 144,
        tempMinC = 10,
        tempMaxC = 18,
        harvestMin = 4,
        harvestMax = 9
    },
    Strawberry = {
        cropID = "Strawberry",
        displayName = "Strawberry",
        seedFullTypes = { "Base.StrewberrieSeed", "Base.StrewberrieBagSeed2" },
        produceFullType = "Base.Strewberrie",
        growthHours = 360,
        tempMinC = 14,
        tempMaxC = 24,
        harvestMin = 4,
        harvestMax = 6
    },
    Tomato = {
        cropID = "Tomato",
        displayName = "Tomato",
        seedFullTypes = { "Base.TomatoSeed", "Base.TomatoBagSeed2" },
        produceFullType = "Base.Tomato",
        growthHours = 360,
        tempMinC = 18,
        tempMaxC = 28,
        harvestMin = 4,
        harvestMax = 5
    },
    BellPepper = {
        cropID = "BellPepper",
        displayName = "Bell Pepper",
        seedFullTypes = { "Base.BellPepperSeed", "Base.BellPepperBagSeed" },
        produceFullType = "Base.BellPepper",
        growthHours = 292,
        tempMinC = 18,
        tempMaxC = 28,
        harvestMin = 2,
        harvestMax = 4
    }
}

Internal.SeedToCropID = Internal.SeedToCropID or nil
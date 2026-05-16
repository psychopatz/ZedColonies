DC_Buildings = DC_Buildings or {}
DC_Buildings.Config = DC_Buildings.Config or {}

local Config = DC_Buildings.Config
Config.Definitions = Config.Definitions or {}

local function addProductionStation(definition)
    if type(definition) ~= "table" or tostring(definition.buildingType or "") == "" then
        return
    end
    Config.Definitions[definition.buildingType] = definition
end

addProductionStation({
    buildingType = "FabricationBench",
    displayName = "Fabrication Bench",
    iconPath = "media/ui/Buildings/DC_Workshop.png",
    enabled = true,
    maxLevel = 1,
    isInfinite = false,
    levels = {
        [1] = {
            enabled = true,
            workPoints = 36,
            xpReward = 120,
            recipe = {
                { category = "Wood", count = 4 },
                { category = "Hardware", count = 8 },
                { category = "Cloth", count = 2 },
            },
            effects = {
                productionSlots = 1,
            }
        }
    }
})

addProductionStation({
    buildingType = "Forge",
    displayName = "Forge",
    iconPath = "media/ui/Buildings/DC_Workshop.png",
    enabled = true,
    maxLevel = 1,
    isInfinite = false,
    levels = {
        [1] = {
            enabled = true,
            workPoints = 42,
            xpReward = 120,
            recipe = {
                { category = "Stone", count = 6 },
                { category = "Metal", count = 4 },
                { category = "Hardware", count = 8 },
            },
            effects = {
                productionSlots = 1,
            }
        }
    }
})

addProductionStation({
    buildingType = "Cookhouse",
    displayName = "Cookhouse",
    iconPath = "media/ui/Buildings/DC_Kitchen.png",
    enabled = true,
    maxLevel = 1,
    isInfinite = false,
    levels = {
        [1] = {
            enabled = true,
            workPoints = 36,
            xpReward = 120,
            recipe = {
                { category = "Wood", count = 4 },
                { category = "Hardware", count = 6 },
                { category = "Cloth", count = 2 },
            },
            effects = {
                productionSlots = 1,
            }
        }
    }
})

addProductionStation({
    buildingType = "TextileRoom",
    displayName = "Textile Room",
    iconPath = "media/ui/Buildings/DC_Workshop.png",
    enabled = true,
    maxLevel = 1,
    isInfinite = false,
    levels = {
        [1] = {
            enabled = true,
            workPoints = 36,
            xpReward = 120,
            recipe = {
                { category = "Wood", count = 4 },
                { category = "Cloth", count = 6 },
                { category = "Hardware", count = 6 },
            },
            effects = {
                productionSlots = 1,
            }
        }
    }
})

addProductionStation({
    buildingType = "Woodshop",
    displayName = "Woodshop",
    iconPath = "media/ui/Buildings/DC_Workshop.png",
    enabled = true,
    maxLevel = 1,
    isInfinite = false,
    levels = {
        [1] = {
            enabled = true,
            workPoints = 36,
            xpReward = 120,
            recipe = {
                { category = "Wood", count = 8 },
                { category = "Hardware", count = 6 },
            },
            effects = {
                productionSlots = 1,
            }
        }
    }
})

addProductionStation({
    buildingType = "TinkerBench",
    displayName = "Tinker Bench",
    iconPath = "media/ui/Buildings/DC_Laboratory.png",
    enabled = true,
    maxLevel = 1,
    isInfinite = false,
    levels = {
        [1] = {
            enabled = true,
            workPoints = 42,
            xpReward = 120,
            recipe = {
                { category = "Hardware", count = 8 },
                { category = "ElectronicScrap", count = 6 },
                { category = "Glass", count = 2 },
            },
            effects = {
                productionSlots = 1,
            }
        }
    }
})

addProductionStation({
    buildingType = "ProvisionYard",
    displayName = "Provision Yard",
    iconPath = "media/ui/Buildings/DC_Greenhouse.png",
    enabled = true,
    maxLevel = 1,
    isInfinite = false,
    levels = {
        [1] = {
            enabled = true,
            workPoints = 36,
            xpReward = 120,
            recipe = {
                { category = "Wood", count = 6 },
                { category = "Cloth", count = 2 },
                { category = "Hardware", count = 4 },
            },
            effects = {
                productionSlots = 1,
            }
        }
    }
})

addProductionStation({
    buildingType = "FuelDepot",
    displayName = "Fuel Depot",
    iconPath = "media/ui/Buildings/DT_PowerGenerator.png",
    enabled = true,
    maxLevel = 1,
    isInfinite = false,
    levels = {
        [1] = {
            enabled = true,
            workPoints = 42,
            xpReward = 120,
            recipe = {
                { category = "Metal", count = 6 },
                { category = "Hardware", count = 8 },
                { category = "Adhesive", count = 2 },
            },
            effects = {
                productionSlots = 1,
            }
        }
    }
})

return Config

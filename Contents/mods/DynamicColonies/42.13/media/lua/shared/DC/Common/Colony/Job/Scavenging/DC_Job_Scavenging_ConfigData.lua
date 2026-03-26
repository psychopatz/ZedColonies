DC_Colony = DC_Colony or {}
DC_Colony.Config = DC_Colony.Config or {}

local Config = DC_Colony.Config

Config.ScavengeLootDefaults = {
    basePoolRolls = 2,
    maxPoolRolls = 5,
    darkSearchSpeedMultiplier = 0.5,
    litSearchSpeedMultiplier = 1.0,
    secondarySkillWeightScale = 0.45,
    skillWeightMultiplierScale = 0.85,
    bonusRareRollThreshold = 10,
    bonusRareRollMasteryThreshold = 16,
    maxBonusRareRolls = 2,
    botchChanceBase = 0.04,
    botchChancePerDifficultyGap = 0.035,
    cleanChanceBase = 0.10,
    cleanChancePerSkillSurplus = 0.025,
    excellentChanceBase = 0.03,
    excellentChancePerSkillSurplus = 0.02,
    tierFailureWeights = {
        [0] = 7,
        [1] = 5,
        [2] = 3,
        [3] = 1
    }
}

Config.ScavengeSiteProfileOrder = {
    "GunStore",
    "Medical",
    "ElectronicsStore",
    "AutoShop",
    "Warehouse",
    "Office",
    "Residential"
}

Config.ScavengeSiteProfiles = {
    Unknown = {
        id = "Unknown",
        displayName = "Unsorted Location",
        secondarySkillWeights = {},
        ruleWeights = {}
    },
    Residential = {
        id = "Residential",
        displayName = "Residential",
        matchTokens = {
            "bedroom", "kitchen", "bathroom", "livingroom", "diningroom",
            "closet", "laundry", "garage", "apartment", "house", "motelroom"
        },
        failureWeightDelta = -1,
        secondarySkillWeights = {
            Cooking = 0.30,
            Social = 0.15,
            Plants = 0.15
        },
        ruleWeights = {
            open_food = 1.6,
            open_clothing = 1.5,
            open_media = 1.2,
            waste_scrap = 0.8,
            general_material = 0.9,
            locked_house_tools = 1.3,
            electronics_components = 0.5,
            carpentry_strip = 1.3,
            plumbing_parts = 1.2,
            metal_salvage = 0.3,
            industrial_hardware = 0.4,
            medical_cache = 0.3,
            firearms_cache = 0.2,
            ammo_cache = 0.2
        }
    },
    Medical = {
        id = "Medical",
        displayName = "Medical",
        matchTokens = {
            "medical", "clinic", "hospital", "pharmacy", "doctor",
            "ward", "treatment", "ambulance"
        },
        failureWeightDelta = 1,
        secondarySkillWeights = {
            Intellectual = 0.35,
            Construction = 0.10
        },
        ruleWeights = {
            open_food = 0.5,
            open_clothing = 0.4,
            open_media = 0.3,
            waste_scrap = 0.7,
            general_material = 0.5,
            locked_house_tools = 0.6,
            electronics_components = 0.8,
            carpentry_strip = 0.2,
            plumbing_parts = 0.6,
            metal_salvage = 0.2,
            industrial_hardware = 0.4,
            medical_cache = 2.8,
            firearms_cache = 0.1,
            ammo_cache = 0.1
        }
    },
    Warehouse = {
        id = "Warehouse",
        displayName = "Warehouse",
        matchTokens = {
            "warehouse", "storage", "storageroom", "toolstorage", "loading",
            "shipping", "industrial", "factory", "crate"
        },
        poolRollBonus = 1,
        failureWeightDelta = -1,
        secondarySkillWeights = {
            Construction = 0.30,
            Mining = 0.20
        },
        ruleWeights = {
            open_food = 0.3,
            open_clothing = 0.2,
            open_media = 0.2,
            waste_scrap = 1.4,
            general_material = 1.9,
            locked_house_tools = 1.1,
            electronics_components = 0.5,
            carpentry_strip = 1.4,
            plumbing_parts = 0.7,
            metal_salvage = 1.8,
            industrial_hardware = 1.8,
            medical_cache = 0.2,
            firearms_cache = 0.1,
            ammo_cache = 0.2
        }
    },
    ElectronicsStore = {
        id = "ElectronicsStore",
        displayName = "Electronics",
        matchTokens = {
            "electronics", "electronic", "computer", "server", "control",
            "tech", "audio", "radio"
        },
        failureWeightDelta = 1,
        secondarySkillWeights = {
            Crafting = 0.35
        },
        ruleWeights = {
            open_food = 0.2,
            open_clothing = 0.2,
            open_media = 0.6,
            waste_scrap = 1.0,
            general_material = 0.4,
            locked_house_tools = 0.7,
            electronics_components = 2.8,
            carpentry_strip = 0.2,
            plumbing_parts = 0.2,
            metal_salvage = 0.6,
            industrial_hardware = 0.8,
            medical_cache = 0.1,
            firearms_cache = 0.1,
            ammo_cache = 0.1
        }
    },
    AutoShop = {
        id = "AutoShop",
        displayName = "Auto Shop",
        matchTokens = {
            "mechanic", "garage", "carrepair", "autoshop", "autostore",
            "repair", "tools", "vehicle"
        },
        secondarySkillWeights = {
            Intellectual = 0.30,
            Construction = 0.20
        },
        ruleWeights = {
            open_food = 0.2,
            open_clothing = 0.2,
            open_media = 0.2,
            waste_scrap = 1.3,
            general_material = 1.1,
            locked_house_tools = 0.9,
            electronics_components = 0.9,
            carpentry_strip = 0.5,
            plumbing_parts = 0.5,
            metal_salvage = 1.7,
            industrial_hardware = 1.6,
            medical_cache = 0.1,
            firearms_cache = 0.1,
            ammo_cache = 0.1
        }
    },
    Office = {
        id = "Office",
        displayName = "Office",
        matchTokens = {
            "office", "meeting", "conference", "classroom", "library",
            "school", "reception", "admin"
        },
        failureWeightDelta = -1,
        secondarySkillWeights = {
            Social = 0.35,
            Maintenance = 0.15
        },
        ruleWeights = {
            open_food = 0.8,
            open_clothing = 0.6,
            open_media = 1.8,
            waste_scrap = 0.4,
            general_material = 0.3,
            locked_house_tools = 0.5,
            electronics_components = 1.4,
            carpentry_strip = 0.1,
            plumbing_parts = 0.1,
            metal_salvage = 0.1,
            industrial_hardware = 0.2,
            medical_cache = 0.2,
            firearms_cache = 0.0,
            ammo_cache = 0.0
        }
    },
    GunStore = {
        id = "GunStore",
        displayName = "Gun Store",
        matchTokens = {
            "gun", "weapon", "ammo", "armory", "armoury", "locker"
        },
        failureWeightDelta = 2,
        secondarySkillWeights = {
            Crafting = 0.20,
            Melee = 0.15
        },
        ruleWeights = {
            open_food = 0.1,
            open_clothing = 0.3,
            open_media = 0.1,
            waste_scrap = 0.8,
            general_material = 0.5,
            locked_house_tools = 0.6,
            electronics_components = 0.4,
            carpentry_strip = 0.1,
            plumbing_parts = 0.1,
            metal_salvage = 0.5,
            industrial_hardware = 0.6,
            medical_cache = 0.2,
            firearms_cache = 3.5,
            ammo_cache = 3.2
        }
    }
}


Config.ScavengeLootRules = {
    {
        id = "open_food",
        tags = { "Food" },
        weight = 18,
        minQty = 1,
        maxQty = 2,
        difficulty = 2,
        skillWeights = { Cooking = 0.65, Plants = 0.35, Social = 0.15 }
    },
    {
        id = "open_clothing",
        tags = { "Clothing" },
        weight = 10,
        minQty = 1,
        maxQty = 1,
        difficulty = 3,
        skillWeights = { Crafting = 0.45, Maintenance = 0.35 }
    },
    {
        id = "open_media",
        tags = { "Literature" },
        weight = 4,
        minQty = 1,
        maxQty = 1,
        difficulty = 2,
        skillWeights = { Intellectual = 0.75, Social = 0.20 }
    },
    {
        id = "waste_scrap",
        tags = { "Quality.Waste" },
        weight = 16,
        minQty = 1,
        maxQty = 2,
        bulkBonus = 1,
        bundleBonus = 1,
        difficulty = 1,
        skillWeights = { Construction = 0.25, Mining = 0.25 }
    },
    {
        id = "general_material",
        tags = { "Resource.Material.General" },
        weight = 9,
        minQty = 1,
        maxQty = 2,
        bulkBonus = 1,
        bundleBonus = 1,
        difficulty = 5,
        salvageSensitive = true,
        botchOutcome = "waste",
        skillWeights = { Construction = 0.55, Crafting = 0.35, Mining = 0.25 }
    },
    {
        id = "locked_house_tools",
        tags = { "Resource.Material.Hardware" },
        weight = 8,
        minTier = 1,
        minQty = 1,
        maxQty = 2,
        bulkBonus = 1,
        requiresAnyCapabilities = { "Scavenge.Access.LockedHome", "Scavenge.Access.ElectronicStore" },
        difficulty = 7,
        salvageSensitive = true,
        botchOutcome = "waste",
        skillWeights = { Construction = 0.55, Crafting = 0.30 }
    },
    {
        id = "electronics_components",
        tags = { "Electronics.Gadget" },
        weight = 7,
        minTier = 1,
        minQty = 1,
        maxQty = 2,
        requiresAnyCapabilities = { "Scavenge.Access.ElectronicStore" },
        difficulty = 9,
        salvageSensitive = true,
        botchOutcome = "waste",
        rareSkillThreshold = 8,
        rareWeightMultiplier = 1.35,
        skillWeights = { Intellectual = 0.65, Crafting = 0.45 }
    },
    {
        id = "carpentry_strip",
        tags = { "Resource.Material.Hardware" },
        weight = 11,
        minTier = 2,
        minQty = 2,
        maxQty = 4,
        bulkBonus = 1,
        requiresAllCapabilities = { "Scavenge.Extraction.CarpentryHammer", "Scavenge.Extraction.CarpentrySaw" },
        difficulty = 9,
        salvageSensitive = true,
        botchOutcome = "waste",
        skillWeights = { Construction = 0.80, Crafting = 0.25 }
    },
    {
        id = "plumbing_parts",
        tags = { "Resource.Parts" },
        weight = 7,
        minTier = 2,
        minQty = 1,
        maxQty = 2,
        requiresAnyCapabilities = { "Scavenge.Extraction.Plumbing" },
        difficulty = 8,
        salvageSensitive = true,
        botchOutcome = "waste",
        skillWeights = { Construction = 0.35, Intellectual = 0.40, Crafting = 0.25 }
    },
    {
        id = "metal_salvage",
        tags = { "Resource.Material.Metal" },
        weight = 10,
        minTier = 3,
        minQty = 2,
        maxQty = 4,
        bulkBonus = 1,
        bundleBonus = 1,
        requiresAllCapabilities = { "Scavenge.Extraction.MetalTorch", "Scavenge.Extraction.MetalMask" },
        difficulty = 11,
        salvageSensitive = true,
        botchOutcome = "waste",
        rareSkillThreshold = 10,
        rareWeightMultiplier = 1.25,
        skillWeights = { Crafting = 0.70, Construction = 0.40, Mining = 0.35 }
    },
    {
        id = "industrial_hardware",
        tags = { "Resource.Material.Hardware" },
        weight = 8,
        minTier = 3,
        minQty = 2,
        maxQty = 3,
        bulkBonus = 1,
        requiresAnyCapabilities = { "Scavenge.Extraction.MetalTorch", "Scavenge.Access.HeavyEntry" },
        difficulty = 10,
        salvageSensitive = true,
        botchOutcome = "waste",
        rareSkillThreshold = 11,
        rareWeightMultiplier = 1.30,
        skillWeights = { Crafting = 0.55, Construction = 0.30, Intellectual = 0.20 }
    },
    {
        id = "medical_cache",
        tags = { "Medical" },
        weight = 6,
        minTier = 3,
        minQty = 1,
        maxQty = 2,
        requiresAnyCapabilities = { "Scavenge.Access.HeavyEntry", "Scavenge.Access.ElectronicStore" },
        difficulty = 10,
        isRare = true,
        skillUnlockLevel = 6,
        rareSkillThreshold = 11,
        rareWeightMultiplier = 1.55,
        botchOutcome = "fail",
        skillWeights = { Medical = 0.85, Intellectual = 0.25 }
    },
    {
        id = "firearms_cache",
        tags = { "Weapon.Ranged.Firearm" },
        weight = 3,
        minTier = 3,
        minQty = 1,
        maxQty = 1,
        requiresAnyCapabilities = { "Scavenge.Access.HeavyEntry" },
        difficulty = 12,
        isRare = true,
        skillUnlockLevel = 8,
        rareSkillThreshold = 13,
        rareWeightMultiplier = 1.85,
        botchOutcome = "fail",
        skillWeights = { Shooting = 0.90, Crafting = 0.20 }
    },
    {
        id = "ammo_cache",
        tags = { "Weapon.Ranged.Ammo" },
        weight = 5,
        minTier = 3,
        minQty = 1,
        maxQty = 2,
        requiresAnyCapabilities = { "Scavenge.Access.HeavyEntry" },
        difficulty = 9,
        isRare = true,
        skillUnlockLevel = 6,
        rareSkillThreshold = 10,
        rareWeightMultiplier = 1.55,
        botchOutcome = "fail",
        skillWeights = { Shooting = 0.70, Crafting = 0.20 }
    }
}

return Config

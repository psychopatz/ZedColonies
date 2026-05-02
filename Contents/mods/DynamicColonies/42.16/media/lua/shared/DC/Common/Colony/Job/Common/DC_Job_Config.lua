DC_Colony = DC_Colony or {}
DC_Colony.Config = DC_Colony.Config or {}

local Config = DC_Colony.Config

Config.JobTypes = {
    Unemployed = "Unemployed",
    Builder = "Builder",
    Doctor = "Doctor",
    Farm = "Farm",
    Fish = "Fish",
    Gatherer = "Gatherer",
    Scavenge = "Scavenge",
    TravelCompanion = "TravelCompanion"
}

Config.JobProfiles = {
    Unemployed = {
        jobType = Config.JobTypes.Unemployed,
        displayName = "Unemployed",
        siteType = nil,
        requiredToolTags = {},
        cycleHours = 24,
        dailyCaloriesNeed = 2000,
        dailyHydrationNeed = 1600,
        outputRules = {},
        skillID = nil,          -- no skill tracked for unemployed workers
        sortOrder = 10,          -- position in the cycle returned by GetNextJobType
        defaultForArchetype = nil,
        hooks = {}
    },
    Builder = {
        jobType = Config.JobTypes.Builder,
        displayName = "Builder",
        siteType = nil,
        requiredToolTags = {
            "Builder.Tool.Hammer",
            "Builder.Tool.Saw"
        },
        cycleHours = 36,
        dailyCaloriesNeed = 2200,
        dailyHydrationNeed = 1800,
        outputRules = {},
        skillID = "Construction",
        sortOrder = 20,
        defaultForArchetype = "Builder",
        hooks = {}
    },
    Doctor = {
        jobType = Config.JobTypes.Doctor,
        displayName = "Doctor",
        siteType = nil,
        requiredToolTags = {},
        cycleHours = 24,
        dailyCaloriesNeed = 2100,
        dailyHydrationNeed = 1700,
        outputRules = {},
        skillID = "Medical",
        sortOrder = 30,
        defaultForArchetype = "Doctor",
        hooks = {}
    },
    Farm = {
        jobType = Config.JobTypes.Farm,
        displayName = "Farmer",
        siteType = Config.SiteTypes.FarmPlotSite,
        requiredToolTags = {
            "Tool.Farming"
        },
        cycleHours = 24,
        dailyCaloriesNeed = 2200,
        dailyHydrationNeed = 1800,
        outputRules = {},
        skillID = "Plants",
        sortOrder = 60,
        defaultForArchetype = "Farmer",
        hooks = {}
    },
    Fish = {
        jobType = Config.JobTypes.Fish,
        displayName = "Fishing",
        siteType = Config.SiteTypes.FishingSite,
        requiredToolTags = {},
        cycleHours = 18,
        dailyCaloriesNeed = 2100,
        dailyHydrationNeed = 1700,
        outputRules = {},
        skillID = "Animals",
        sortOrder = 70,
        defaultForArchetype = "Angler",
        hooks = {}
    },
    Gatherer = {
        jobType = Config.JobTypes.Gatherer,
        displayName = "Gatherer",
        siteType = nil,
        requiredToolTags = {},
        cycleHours = 18,
        dailyCaloriesNeed = 2200,
        dailyHydrationNeed = 1800,
        outputRules = {},
        skillID = nil,          -- dynamic: resolved via Gatherer.GetPrimarySkillID(worker)
        sortOrder = 40,
        defaultForArchetype = nil,
        hooks = {}
    },
    Scavenge = {
        jobType = Config.JobTypes.Scavenge,
        displayName = "Scavenging",
        siteType = Config.SiteTypes.ScavengeSite,
        requiredToolTags = {},
        cycleHours = 16,
        dailyCaloriesNeed = 2300,
        dailyHydrationNeed = 1900,
        outputRules = {
            { tags = { "Quality.Waste" }, picks = 1, minQty = 1, maxQty = 2 },
            { tags = { "Resource.Material.General" }, picks = 1, minQty = 1, maxQty = 2 },
            { tags = { "Tool.General" }, picks = 1, minQty = 1, maxQty = 1 }
        },
        skillID = nil,          -- dynamic: resolved via ScavengeSiteSkillMap[worker.scavengeSiteProfileID]
        sortOrder = 50,
        defaultForArchetype = "Scavenger",
        hooks = {}
    },
    TravelCompanion = {
        jobType = Config.JobTypes.TravelCompanion,
        displayName = "Travel Companion",
        siteType = nil,
        requiredToolTags = {
            "Colony.Combat.Melee",
            "Colony.Combat.Ranged",
            "Colony.Combat.Ammo",
            "Colony.Carry.Backpack",
        },
        cycleHours = 24,
        dailyCaloriesNeed = 2300,
        dailyHydrationNeed = 1900,
        outputRules = {},
        skillID = nil,          -- dynamic: combat XP handled separately by companion combat logic
        sortOrder = 45,          -- inserted between Gatherer(40) and Scavenge(50) when V2 active
        requiresV2 = true,      -- excluded from GetNextJobType when IsTravelCompanionSupported() is false
        defaultForArchetype = nil,
        hooks = {}
    }
}

Config.LegacyProfessionToJob = {
    Builder = Config.JobTypes.Builder,
    Doctor = Config.JobTypes.Doctor,
    Farmer = Config.JobTypes.Farm,
    Angler = Config.JobTypes.Fish,
    Scavenger = Config.JobTypes.Scavenge
}

Config.ArchetypeJobBonuses = {
    Farmer = {
        [Config.JobTypes.Farm] = 1.35
    },
    Angler = {
        [Config.JobTypes.Fish] = 1.35
    },
    Scavenger = {
        [Config.JobTypes.Scavenge] = 1.35,
        [Config.JobTypes.Gatherer] = 1.15
    }
}

Config.ArchetypeCarryWeight = {
    Farmer = 8,
    Angler = 8,
    Scavenger = 10
}

return Config

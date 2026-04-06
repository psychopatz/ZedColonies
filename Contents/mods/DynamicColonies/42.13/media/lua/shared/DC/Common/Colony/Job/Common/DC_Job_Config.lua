DC_Colony = DC_Colony or {}
DC_Colony.Config = DC_Colony.Config or {}

local Config = DC_Colony.Config

Config.JobTypes = {
    Unemployed = "Unemployed",
    Builder = "Builder",
    Doctor = "Doctor",
    Farm = "Farm",
    Fish = "Fish",
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
        outputRules = {}
    },
    Builder = {
        jobType = Config.JobTypes.Builder,
        displayName = "Builder",
        siteType = nil,
        requiredToolTags = {},
        cycleHours = 36,
        dailyCaloriesNeed = 2200,
        dailyHydrationNeed = 1800,
        outputRules = {}
    },
    Doctor = {
        jobType = Config.JobTypes.Doctor,
        displayName = "Doctor",
        siteType = nil,
        requiredToolTags = {},
        cycleHours = 24,
        dailyCaloriesNeed = 2100,
        dailyHydrationNeed = 1700,
        outputRules = {}
    },
    Farm = {
        jobType = Config.JobTypes.Farm,
        displayName = "Farmer",
        siteType = Config.SiteTypes.FarmPlotSite,
        requiredToolTags = {},
        cycleHours = 24,
        dailyCaloriesNeed = 2200,
        dailyHydrationNeed = 1800,
        outputRules = {}
    },
    Fish = {
        jobType = Config.JobTypes.Fish,
        displayName = "Fishing",
        siteType = Config.SiteTypes.FishingSite,
        requiredToolTags = {},
        cycleHours = 18,
        dailyCaloriesNeed = 2100,
        dailyHydrationNeed = 1700,
        outputRules = {}
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
        }
    },
    TravelCompanion = {
        jobType = Config.JobTypes.TravelCompanion,
        displayName = "Travel Companion",
        siteType = nil,
        requiredToolTags = {},
        cycleHours = 24,
        dailyCaloriesNeed = 2300,
        dailyHydrationNeed = 1900,
        outputRules = {}
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
        [Config.JobTypes.Scavenge] = 1.35
    }
}

Config.ArchetypeCarryWeight = {
    Farmer = 8,
    Angler = 8,
    Scavenger = 10
}

return Config

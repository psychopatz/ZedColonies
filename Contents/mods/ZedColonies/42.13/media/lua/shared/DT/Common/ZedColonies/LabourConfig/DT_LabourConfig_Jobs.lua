DT_Labour = DT_Labour or {}
DT_Labour.Config = DT_Labour.Config or {}

local Config = DT_Labour.Config

Config.JobTypes = {
    Builder = "Builder",
    Doctor = "Doctor",
    Farm = "Farm",
    Fish = "Fish",
    Scavenge = "Scavenge"
}

Config.JobProfiles = {
    Builder = {
        jobType = Config.JobTypes.Builder,
        displayName = "Builder",
        siteType = nil,
        requiredToolTags = { "Builder.Tool.Hammer", "Builder.Tool.Saw" },
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
        displayName = "Farming",
        siteType = Config.SiteTypes.FarmPlotSite,
        requiredToolTags = { "Tool.Farming" },
        cycleHours = 24,
        dailyCaloriesNeed = 2200,
        dailyHydrationNeed = 1800,
        outputRules = {
            { tags = { "Food.Perishable.Vegetable" }, picks = 2, minQty = 1, maxQty = 2 },
            { tags = { "Food.Perishable.Fruit" }, picks = 1, minQty = 1, maxQty = 1 }
        }
    },
    Fish = {
        jobType = Config.JobTypes.Fish,
        displayName = "Fishing",
        siteType = Config.SiteTypes.FishingSite,
        requiredToolTags = { "Tool.Fishing" },
        cycleHours = 18,
        dailyCaloriesNeed = 2100,
        dailyHydrationNeed = 1700,
        outputRules = {
            { tags = { "Food.Perishable.Fish" }, picks = 2, minQty = 1, maxQty = 2 },
            { tags = { "Resource.Fishing" }, picks = 1, minQty = 1, maxQty = 1 }
        }
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

DC_Colony = DC_Colony or {}
DC_Colony.Config = DC_Colony.Config or {}

local Config = DC_Colony.Config

Config.MOD_DATA_KEY = "DColony_Index"
Config.MOD_DATA_INDEX_KEY = "DColony_Index"
Config.MOD_DATA_SCHEMA_VERSION = 3
Config.MOD_DATA_COLONY_PREFIX = "DColony_Colony_"
Config.MOD_DATA_WORKERS_PREFIX = "DColony_Workers_"
Config.MOD_DATA_WORKER_PREFIX = "DColony_Worker_"
Config.MOD_DATA_SITES_PREFIX = "DColony_Sites_"
Config.MOD_DATA_WAREHOUSE_PREFIX = "DColony_Warehouse_"
Config.MOD_DATA_WAREHOUSE_ITEMS_PREFIX = "DColony_WarehouseItems_"
Config.MOD_DATA_RESOURCES_PREFIX = "DColony_Resources_"
Config.COMMAND_MODULE = "DColony"
Config.PROJECTION_PREFIX = "DTLAB_"
Config.HOURS_PER_DAY = 24
Config.SIM_TICK_RATE = 60
Config.SIM_TIME_STEP_HOURS = 0.25
Config.PRESENTATION_TICK_RATE = 120
Config.PROJECTION_RANGE = 100
Config.DEFAULT_SITE_RADIUS = 8
Config.DEFAULT_STARVATION_DEATH_HOURS = 72
Config.DEFAULT_DEHYDRATION_DEATH_HOURS = 72
Config.HYDRATION_POINTS_PER_THIRST = 1000
Config.RECRUIT_START_CALORIES_MIN = 500
Config.RECRUIT_START_CALORIES_MAX = 800
Config.RECRUIT_START_HYDRATION_MIN = 500
Config.RECRUIT_START_HYDRATION_MAX = 800
Config.RECRUIT_REQUIRED_REPUTATION = 80
Config.RECRUIT_GUARANTEED_REPUTATION = 100
Config.RECRUIT_MIN_SUCCESS_CHANCE = 5
Config.RECRUIT_DAILY_CHANCE = 50
Config.RECRUIT_NAG_WARNING_REPEATS = 1
Config.RECRUIT_NAG_REPUTATION_PENALTY = -15
Config.NON_RECRUITABLE_ARCHETYPES = {
    Gambler = true
}
Config.DEFAULT_LABOUR_DAILY_CALORIES_USE = 500
Config.DEFAULT_LABOUR_DAILY_HYDRATION_USE = 500
Config.DEFAULT_WORKER_MAX_HP = 100
Config.WORKER_HP_LOSS_PER_HOUR = 1
Config.WORKER_HP_REGEN_PER_HOUR = 3
Config.WORKER_HP_INFIRMARY_REGEN_MULTIPLIER = 1.5
Config.WORKER_HP_DOCTOR_REGEN_MULTIPLIER = 4.0
Config.WORKER_BANDAGE_TREATMENT_HOURS = 24
Config.WORKER_ACTIVITY_LOG_LIMIT = 12
Config.NUTRITION_MODEL_VERSION = 3
Config.DEFAULT_WORKER_CARRY_WEIGHT = 8
Config.DEFAULT_WAREHOUSE_CAPACITY = 100
Config.DEFAULT_SCAVENGE_DUMP_HOURS = 1.0
Config.DEFAULT_SCAVENGE_TRAVEL_HOURS = 2.0
Config.DEFAULT_SCAVENGE_WORK_CYCLE_HOURS = 16.0
Config.DEFAULT_SCAVENGE_WORK_AMOUNT = 500
Config.DEFAULT_SCAVENGE_BASE_WORK_MULTIPLIER = 1.0

Config.CONTAINER_CAPACITY_BY_TAG = {
    Tiny = 4,
    Low = 8,
    Medium = 12,
    High = 18
}

Config.CONTAINER_WEIGHT_REDUCTION_BY_TAG = {
    Low = 0.2,
    Medium = 0.5,
    High = 0.8
}

Config.MEAL_SCHEDULE = {
    { id = "breakfast", label = "Breakfast", hour = 7, caloriesShare = 0.28, hydrationShare = 0.24 },
    { id = "lunch", label = "Lunch", hour = 13, caloriesShare = 0.34, hydrationShare = 0.36 },
    { id = "dinner", label = "Dinner", hour = 19, caloriesShare = 0.38, hydrationShare = 0.40 }
}

Config.States = {
    Idle = "Idle",
    Working = "Working",
    Resting = "Resting",
    Incapacitated = "Incapacitated",
    MissingTool = "MissingTool",
    MissingSite = "MissingSite",
    Starving = "Starving",
    Dehydrated = "Dehydrated",
    StorageFull = "StorageFull",
    WarehouseShortage = "WarehouseShortage",
    Dead = "Dead"
}

Config.PresenceStates = {
    Home = "Home",
    AwayToSite = "AwayToSite",
    Scavenging = "Scavenging",
    AwayToHome = "AwayToHome",
    CompanionToPlayer = "CompanionToPlayer",
    CompanionActive = "CompanionActive",
    CompanionReturning = "CompanionReturning"
}

Config.ReturnReasons = {
    Manual = "ManualRecall",
    FullHaul = "FullHaul",
    LowEnergy = "LowEnergy",
    LowTiredness = "LowEnergy", -- Compatibility
    LowFood = "LowFood",
    LowDrink = "LowDrink",
    MissingTool = "MissingTool",
    MissingSite = "MissingSite"
}

Config.SiteTypes = {
    FarmPlotSite = "FarmPlotSite",
    FishingSite = "FishingSite",
    ScavengeSite = "ScavengeSite"
}

function Config.GetRecruitChanceForReputation(reputation)
    local rep = tonumber(reputation) or 0
    local minRep = tonumber(Config.RECRUIT_REQUIRED_REPUTATION) or 80
    local maxRep = tonumber(Config.RECRUIT_GUARANTEED_REPUTATION) or 100
    local minChance = tonumber(Config.RECRUIT_MIN_SUCCESS_CHANCE) or 5

    if rep < minRep then
        return 0
    end

    if maxRep <= minRep then
        return 100
    end

    if rep >= maxRep then
        return 100
    end

    local progress = (rep - minRep) / (maxRep - minRep)
    local chance = minChance + ((100 - minChance) * progress)
    return math.max(minChance, math.min(100, math.floor(chance + 0.5)))
end

function Config.NormalizeArchetypeKey(archetypeID)
    local value = tostring(archetypeID or ""):gsub("^%s+", ""):gsub("%s+$", "")
    if value == "" then
        return ""
    end
    return string.lower(value)
end

function Config.IsRecruitableArchetype(archetypeID)
    local normalized = Config.NormalizeArchetypeKey(archetypeID)
    if normalized == "" then
        return true
    end

    for blockedArchetype, blocked in pairs(Config.NON_RECRUITABLE_ARCHETYPES or {}) do
        if blocked and normalized == Config.NormalizeArchetypeKey(blockedArchetype) then
            return false
        end
    end

    return true
end

return Config

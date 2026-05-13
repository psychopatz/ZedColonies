DC_Colony = DC_Colony or {}
DC_Colony.Registry = DC_Colony.Registry or {}
DC_Colony.Registry.Internal = DC_Colony.Registry.Internal or {}

local Config = DC_Colony.Config
local Registry = DC_Colony.Registry
local Internal = Registry.Internal
local Data = Internal.ColonyRegWorkerState or {}

Internal.ColonyRegWorkerState = Data

function Data.clampAmount(value)
    return math.max(0, tonumber(value) or 0)
end

function Data.getReserveCaps(worker)
    local profile = Config.GetJobProfile(worker and worker.jobType)
    local dailyCaloriesNeed = Config.GetEffectiveDailyCaloriesNeed and Config.GetEffectiveDailyCaloriesNeed(worker, profile)
        or tonumber(worker and worker.dailyCaloriesNeed)
        or tonumber(profile and profile.dailyCaloriesNeed)
        or 0
    local dailyHydrationNeed = Config.GetEffectiveDailyHydrationNeed and Config.GetEffectiveDailyHydrationNeed(worker, profile)
        or tonumber(worker and worker.dailyHydrationNeed)
        or tonumber(profile and profile.dailyHydrationNeed)
        or 0
    return Data.clampAmount(dailyCaloriesNeed), Data.clampAmount(dailyHydrationNeed)
end

function Data.normalizeLedgerEntry(entry)
    if DC_Colony and DC_Colony.Nutrition and DC_Colony.Nutrition.SanitizeLedgerEntry then
        return DC_Colony.Nutrition.SanitizeLedgerEntry(entry)
    end

    if not entry then
        return 0, 0
    end
    local calories = Data.clampAmount(entry.caloriesRemaining)
    local hydration = Data.clampAmount(entry.hydrationRemaining)
    if hydration > 0 and hydration < 25 then
        hydration = hydration * (Config.HYDRATION_POINTS_PER_THIRST or 1000)
    end

    entry.caloriesRemaining = calories
    entry.hydrationRemaining = hydration
    return calories, hydration
end

function Data.getInventoryLedgerWeight(entries)
    local totalWeight = 0
    for _, entry in ipairs(entries or {}) do
        local qty = math.max(1, tonumber(entry and entry.qty) or 1)
        totalWeight = totalWeight + (math.max(0, tonumber(Config.GetItemWeight and Config.GetItemWeight(entry and entry.fullType)) or 0) * qty)
    end
    return totalWeight
end

return Data
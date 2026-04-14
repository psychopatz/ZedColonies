DC_Colony = DC_Colony or {}
DC_Colony.Config = DC_Colony.Config or {}
DC_Colony.StarterWorkers = DC_Colony.StarterWorkers or {}

local Config = DC_Colony.Config
local StarterWorkers = DC_Colony.StarterWorkers

Config.STARTER_WORKER_COUNT_MIN = 0
Config.STARTER_WORKER_COUNT_MAX = 10
Config.STARTER_WORKER_ARCHETYPE_POOL = {
    "General",
    "Scavenger",
    "Farmer",
    "Carpenter",
    "Hiker",
    "Janitor",
    "Mechanic",
    "Electrician"
}

function Config.GetStarterWorkerCount()
    local value = Config.GetSandboxNumberAny
        and Config.GetSandboxNumberAny({ "StarterWorkerCount" }, 0)
        or 0
    value = math.floor(tonumber(value) or 0)
    value = math.max(Config.STARTER_WORKER_COUNT_MIN, value)
    return math.min(Config.STARTER_WORKER_COUNT_MAX, value)
end

function StarterWorkers.GetArchetypePool()
    return Config.STARTER_WORKER_ARCHETYPE_POOL
end

return StarterWorkers

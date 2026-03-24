DC_Colony = DC_Colony or {}
DC_Colony.Health = DC_Colony.Health or {}

local Config = DC_Colony.Config

function Config.GetHealthMax(worker)
    return math.max(1, tonumber(Config.DEFAULT_WORKER_MAX_HP) or 100)
end

function Config.GetHealthLossPerHour(worker)
    return math.max(0, tonumber(Config.WORKER_HP_LOSS_PER_HOUR) or 1)
end

function Config.GetHealthRegenPerHour(worker)
    return math.max(0, tonumber(Config.WORKER_HP_REGEN_PER_HOUR) or 1)
end

-- Fallback constants if not loaded from Core yet
Config.DEFAULT_WORKER_MAX_HP = Config.DEFAULT_WORKER_MAX_HP or 100
Config.WORKER_HP_LOSS_PER_HOUR = Config.WORKER_HP_LOSS_PER_HOUR or 1
Config.WORKER_HP_REGEN_PER_HOUR = Config.WORKER_HP_REGEN_PER_HOUR or 1

return DC_Colony.Health

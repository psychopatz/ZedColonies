DC_Colony = DC_Colony or {}
DC_Colony.Health = DC_Colony.Health or {}

local Config = DC_Colony.Config
local Health = DC_Colony.Health

function Health.ClampHP(value, maxHp)
    local safeMax = math.max(1, tonumber(maxHp) or (Config.GetHealthMax and Config.GetHealthMax()) or 100)
    return math.max(0, math.min(safeMax, tonumber(value) or safeMax))
end

function Health.GetMax(worker)
    return math.max(1, tonumber(worker and worker.maxHp) or (Config.GetHealthMax and Config.GetHealthMax(worker)) or 100)
end

function Health.GetCurrent(worker)
    if not worker then return 0 end
    return Health.ClampHP(worker.hp, Health.GetMax(worker))
end

function Health.SetCurrent(worker, value)
    if not worker then return 0 end
    worker.hp = Health.ClampHP(value, Health.GetMax(worker))
    return worker.hp
end

function Health.GetRatio(worker)
    local maxValue = Health.GetMax(worker)
    local current = Health.GetCurrent(worker)
    return math.max(0, math.min(1, current / maxValue))
end

function Health.IsDead(worker)
    return Health.GetCurrent(worker) <= 0
end

return Health

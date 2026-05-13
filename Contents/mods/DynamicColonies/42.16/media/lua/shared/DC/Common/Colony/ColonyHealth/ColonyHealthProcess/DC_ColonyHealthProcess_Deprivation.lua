DC_Colony = DC_Colony or {}
DC_Colony.Health = DC_Colony.Health or {}

local Config = DC_Colony.Config
local Health = DC_Colony.Health

function Health.ApplyDeprivationDamage(worker, deprivedHours)
    if not worker or deprivedHours <= 0 then
        return Health.GetCurrent(worker)
    end

    local damage = deprivedHours * (Config.GetHealthLossPerHour and Config.GetHealthLossPerHour() or 1)
    return Health.SetCurrent(worker, Health.GetCurrent(worker) - damage)
end

return Health
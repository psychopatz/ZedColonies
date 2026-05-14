DC_Buildings = DC_Buildings or {}
DC_Buildings.Production = DC_Buildings.Production or {}

local Production = DC_Buildings.Production

Production.Config = Production.Config or {
    IntervalHours = 1,
    MaxCyclesPerPass = 4,
}

return Production

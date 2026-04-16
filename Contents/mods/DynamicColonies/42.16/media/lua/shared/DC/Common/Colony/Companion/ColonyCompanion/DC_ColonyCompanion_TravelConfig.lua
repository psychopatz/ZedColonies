DC_Colony = DC_Colony or {}
DC_Colony.Companion = DC_Colony.Companion or {}

local Internal = DC_Colony.Companion.Internal
local Config = Internal.Config

function Internal.GetTravelHours()
    local simInternal = DC_Colony and DC_Colony.Sim and DC_Colony.Sim.Internal or nil
    if simInternal and simInternal.getScavengeTravelHours then
        return math.max(0, tonumber(simInternal.getScavengeTravelHours()) or 0)
    end

    return math.max(
        0,
        tonumber(Config.GetScavengeTravelHours and Config.GetScavengeTravelHours())
            or tonumber(Config.DEFAULT_SCAVENGE_TRAVEL_HOURS)
            or 0
    )
end
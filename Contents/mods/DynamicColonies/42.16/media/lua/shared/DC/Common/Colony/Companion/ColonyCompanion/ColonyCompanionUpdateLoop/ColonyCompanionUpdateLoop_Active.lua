DC_Colony = DC_Colony or {}
DC_Colony.Companion = DC_Colony.Companion or {}

local Companion = DC_Colony.Companion
Companion.Internal = Companion.Internal or {}

local Internal = Companion.Internal
local UpdateLoop = Internal.UpdateLoop or {}
local Config = Internal.Config

Internal.UpdateLoop = UpdateLoop

function UpdateLoop.UpdateTravelCompanionActiveState(worker, ctx)
    local deltaHours = math.max(0, tonumber(ctx and ctx.deltaHours) or 0)
    local currentHour = tonumber(ctx and ctx.currentHour) or Internal.GetCurrentWorldHours()
    local forcedRest = ctx and ctx.forcedRest == true or false
    local hasCalories = ctx and ctx.hasCalories ~= false
    local hasHydration = ctx and ctx.hasHydration ~= false
    local profile = ctx and ctx.profile or Config.GetJobProfile(worker.jobType)
    local energy = DC_Colony and DC_Colony.Energy or nil
    local companionData = Internal.GetCompanionData(worker)
    local presenceState = tostring(worker.presenceState or "")

    Internal.RefreshCompanionCommanderValidity(worker)
    if tostring(worker.presenceState or "") ~= presenceState then
        return true
    end
    if companionData.awaitingDespawn == true then
        worker.state = Config.States.Working
        return true
    end

    if energy and deltaHours > 0 then
        energy.ApplyWorkDrain(worker, deltaHours, profile)
    end

    if not worker.jobEnabled then
        Internal.BeginWorkerCompanionReturn(nil, worker, Config.ReturnReasons.Manual)
    elseif not hasHydration then
        Internal.BeginWorkerCompanionReturn(nil, worker, Config.ReturnReasons.LowDrink)
    elseif not hasCalories then
        Internal.BeginWorkerCompanionReturn(nil, worker, Config.ReturnReasons.LowFood)
    elseif forcedRest or (energy and energy.IsDepleted and energy.IsDepleted(worker)) then
        local lowEnergyReason = Config.ReturnReasons and (Config.ReturnReasons.LowEnergy or Config.ReturnReasons.LowTiredness) or "LowEnergy"
        if energy and energy.BeginForcedRest then
            energy.BeginForcedRest(worker, currentHour, lowEnergyReason, "Too tired for companion duty. Returning home to rest.")
        end
        Internal.BeginWorkerCompanionReturn(nil, worker, lowEnergyReason)
    else
        worker.state = Config.States.Working
        companionData.stage = Internal.Constants.TRAVEL_STAGE_ACTIVE
    end
    return true
end

return Companion
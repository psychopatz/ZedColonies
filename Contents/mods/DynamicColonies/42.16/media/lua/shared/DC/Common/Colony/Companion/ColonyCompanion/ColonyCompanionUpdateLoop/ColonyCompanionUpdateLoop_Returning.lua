DC_Colony = DC_Colony or {}
DC_Colony.Companion = DC_Colony.Companion or {}

local Companion = DC_Colony.Companion
Companion.Internal = Companion.Internal or {}

local Internal = Companion.Internal
local UpdateLoop = Internal.UpdateLoop or {}
local Config = Internal.Config

Internal.UpdateLoop = UpdateLoop

function UpdateLoop.UpdateTravelCompanionReturningState(worker, ctx)
    local deltaHours = math.max(0, tonumber(ctx and ctx.deltaHours) or 0)
    local currentHour = tonumber(ctx and ctx.currentHour) or Internal.GetCurrentWorldHours()
    local profile = ctx and ctx.profile or Config.GetJobProfile(worker.jobType)
    local energy = DC_Colony and DC_Colony.Energy or nil
    local companionData = Internal.GetCompanionData(worker)

    if companionData.awaitingDespawn == true then
        worker.state = Config.States.Working
        return true
    end
    if worker.state ~= Config.States.Incapacitated then
        worker.state = Config.States.Idle
    end
    if Internal.GetCompanionUUID(worker)
        and DTNPCServerCore
        and DTNPCServerCore.GetNPCDataByUUID
        and DTNPCServerCore.GetNPCDataByUUID(Internal.GetCompanionUUID(worker)) then
        Internal.BeginWorkerCompanionReturn(nil, worker, worker.returnReason or companionData.returnReason or Config.ReturnReasons.Manual)
        return true
    end
    worker.travelHoursRemaining = math.max(0, tonumber(worker.travelHoursRemaining) or 0)
    if deltaHours > 0 then
        worker.travelHoursRemaining = math.max(0, worker.travelHoursRemaining - deltaHours)
    end
    if worker.travelHoursRemaining > 0 then
        UpdateLoop.ApplyTravelProgressFailsafe(worker, companionData, currentHour, deltaHours)
    end
    UpdateLoop.SetTravelProgressMarker(companionData, currentHour, worker.travelHoursRemaining)
    if energy and deltaHours > 0 then
        energy.ApplyTravelDrain(worker, deltaHours, profile)
    end
    if worker.travelHoursRemaining <= 0 then
        Internal.FinalizeReturnTravel(worker, currentHour)
    else
        worker.state = worker.state == Config.States.Incapacitated and Config.States.Incapacitated or Config.States.Idle
    end
    return true
end

return Companion
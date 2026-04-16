DC_Colony = DC_Colony or {}
DC_Colony.Companion = DC_Colony.Companion or {}

local Internal = DC_Colony.Companion.Internal

function Internal.RestoreWorkerAfterFailedStart(worker)
    if not worker then
        return
    end

    worker.jobEnabled = false
    worker.presenceState = Internal.Config.PresenceStates.Home
    worker.travelHoursRemaining = 0
    worker.returnReason = nil
    worker.state = Internal.Config.States.Idle
end

function Internal.CreateCompanionSoul(worker)
    if not worker or not DynamicTrading_Roster or not DynamicTrading_Roster.AddSoul then
        return nil, "Dynamic Trading roster is unavailable.", false
    end

    local uuid, existing = Internal.FindExistingCompanionSoul(worker)
    if uuid then
        return uuid, nil, existing == true
    end

    local homeCoords = {
        x = worker.homeX or 0,
        y = worker.homeY or 0,
        z = worker.homeZ or 0,
    }
    local archetypeID = worker.archetypeID or worker.profession or "General"

    uuid = DynamicTrading_Roster.AddSoul("Independent", archetypeID, homeCoords, {
        forceFaction = true
    })
    if not uuid then
        return nil, "Unable to create companion soul.", false
    end

    local companionData = Internal.GetCompanionData(worker)
    if companionData then
        companionData.uuid = uuid
    end

    Internal.Debug(
        "Created independent companion soul workerID=" .. tostring(worker.workerID)
            .. " uuid=" .. tostring(uuid)
            .. " owner=" .. tostring(worker.ownerUsername)
    )

    return uuid, nil, true
end
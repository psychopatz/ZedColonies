DC_SupplyWindow = DC_SupplyWindow or {}
DC_SupplyWindow.Internal = DC_SupplyWindow.Internal or {}

local Internal = DC_SupplyWindow.Internal

local function isRelevantEquipmentEntry(entry, window)
    if entry and entry.kind == "player" and Internal.ensurePlayerEntryEquipmentData then
        Internal.ensurePlayerEntryEquipmentData(entry)
    end

    if not entry or entry.kind == "money" or entry.canAssignTool ~= true then
        return false
    end

    local config = Internal.Config or {}
    local worker = window and window.workerData or nil
    if config.GetMatchingEquipmentRequirementDefinitions and worker and worker.jobType then
        return #(config.GetMatchingEquipmentRequirementDefinitions(entry.fullType, worker.jobType) or {}) > 0
    end

    return true
end

function Internal.canTransferWithWorker(worker)
    if not worker then
        return false
    end

    local config = Internal.Config or {}
    local normalizedJob = config.NormalizeJobType and config.NormalizeJobType(worker.jobType) or tostring(worker.jobType or "")
    if normalizedJob == ((config.JobTypes or {}).Scavenge) then
        local homeState = tostring((config.PresenceStates or {}).Home or "Home")
        local presenceState = tostring(worker.presenceState or homeState)
        return presenceState == homeState
    end

    return true
end

function Internal.getTransferBlockedReason(worker)
    if not worker then
        return "No worker selected."
    end

    local config = Internal.Config or {}
    local normalizedJob = config.NormalizeJobType and config.NormalizeJobType(worker.jobType) or tostring(worker.jobType or "")
    if normalizedJob == ((config.JobTypes or {}).Scavenge) and not Internal.canTransferWithWorker(worker) then
        return tostring(worker.name or "This worker") .. " is away from home. Transfers are disabled until they return."
    end

    return "Transfers are currently unavailable."
end

function Internal.canStoreInWarehouseOutput(entry)
    if not entry or entry.kind == "money" then
        return false
    end
    if Internal.Config and Internal.Config.IsMedicalProvisionFullType and Internal.Config.IsMedicalProvisionFullType(entry.fullType) then
        return false
    end
    return tostring(entry.fullType or "") ~= ""
end

function Internal.shouldShowPlayerEntry(entry, activeTab, window)
    if not entry then
        return false
    end

    if activeTab == Internal.Tabs.Equipment then
        return isRelevantEquipmentEntry(entry, window)
    end

    if activeTab == Internal.Tabs.Output then
        if Internal.isWarehouseView and Internal.isWarehouseView(window) then
            return Internal.canStoreInWarehouseOutput(entry)
        end
        return false
    end

    if entry.kind == "money" then
        return true
    end

    return entry.canDeposit == true
end

function Internal.shouldShowWorkerEntry(entry, activeTab)
    if not entry then
        return false
    end

    if activeTab == Internal.Tabs.Equipment or activeTab == Internal.Tabs.Output then
        return true
    end

    if entry.kind == "money" then
        return true
    end

    return (tonumber(entry.calories) or 0) > 0
        or (tonumber(entry.hydration) or 0) > 0
        or (tonumber(entry.treatmentUnits) or 0) > 0
end

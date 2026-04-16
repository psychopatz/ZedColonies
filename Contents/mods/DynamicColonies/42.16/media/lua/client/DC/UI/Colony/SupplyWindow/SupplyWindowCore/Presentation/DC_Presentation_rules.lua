DC_SupplyWindow = DC_SupplyWindow or {}
DC_SupplyWindow.Internal = DC_SupplyWindow.Internal or {}

local Internal = DC_SupplyWindow.Internal

local function isRelevantEquipmentEntry(entry, window)
    if entry and entry.kind == "player" and Internal.ensurePlayerEntryEquipmentData then
        Internal.ensurePlayerEntryEquipmentData(entry)
    end

    if not entry or entry.kind == "money" or entry.canAssignTool ~= true or entry.isDynamicTradingLocked == true then
        return false
    end

    local config = Internal.Config or {}
    local worker = window and window.workerData or nil

    if worker and Internal.isAmmoRequirementActive and Internal.isAmmoRequirementActive(worker)
        and Internal.entryMatchesRangedAmmo and Internal.entryMatchesRangedAmmo(entry, worker) then
        return true
    end

    if worker and worker.jobType then
        local cacheKey = table.concat({
            tostring(worker.workerID or ""),
            tostring(worker.jobType or ""),
            tostring(Internal.isAmmoRequirementActive and Internal.isAmmoRequirementActive(worker) or false),
        }, "|")

        if window._equipmentRequirementKeySetCacheKey ~= cacheKey then
            local keySet = {}
            for _, definition in ipairs(config.GetWorkerEquipmentRequirementDefinitions and config.GetWorkerEquipmentRequirementDefinitions(worker) or {}) do
                local requirementKey = tostring(definition and definition.requirementKey or "")
                if requirementKey ~= "" then
                    if requirementKey ~= "Colony.Combat.Ammo"
                        or (Internal.isAmmoRequirementActive and Internal.isAmmoRequirementActive(worker)) then
                        keySet[requirementKey] = true
                    end
                end
            end
            window._equipmentRequirementKeySetCacheKey = cacheKey
            window._equipmentRequirementKeySet = keySet
        end

        local keySet = window._equipmentRequirementKeySet or {}
        for _, definition in ipairs(entry.equipmentRequirementKeys or {}) do
            local requirementKey = tostring(definition and definition.requirementKey or "")
            if keySet[requirementKey] then
                return true
            end
        end

        return false
    end

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

    if entry.canDeposit == true then
        return true
    end

    return activeTab == Internal.Tabs.Provisions and tostring(entry.provisionBlockedReason or "") ~= ""
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

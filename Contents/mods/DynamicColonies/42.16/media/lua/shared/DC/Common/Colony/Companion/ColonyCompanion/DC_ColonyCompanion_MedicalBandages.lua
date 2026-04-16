DC_Colony = DC_Colony or {}
DC_Colony.Companion = DC_Colony.Companion or {}

local Companion = DC_Colony.Companion
local Internal = Companion.Internal
local Config = Internal.Config

function Internal.GetMedicalBandageTier(fullType)
    local value = tostring(fullType or "")
    if value == "Base.AlcoholRippedSheets" then
        return "sterilized_rag", "Base.RippedSheetsDirty"
    end
    if value == "Base.RippedSheets" then
        return "clean_rag", "Base.RippedSheetsDirty"
    end
    if value == "Base.Bandage" or value == "Base.BandageBox" or value == "Base.AlcoholBandage" then
        return "bandage", "Base.BandageDirty"
    end
    return "clean_rag", "Base.RippedSheetsDirty"
end

function Internal.RemoveNutritionEntry(worker, index)
    if not worker or not index then
        return
    end

    table.remove(worker.nutritionLedger, index)
    worker.nutritionCacheDirty = true
end

function Internal.AddDirtyMedicalOutput(worker, fullType)
    local registry = Internal.GetRegistry()
    if not registry or not registry.AddOutputEntry or not fullType or fullType == "" then
        return
    end

    registry.AddOutputEntry(worker, {
        fullType = fullType,
        displayName = registry.Internal and registry.Internal.GetDisplayNameForFullType and registry.Internal.GetDisplayNameForFullType(fullType) or nil,
        qty = 1,
    })
end

function Internal.ResolveBandageSupply(worker)
    if not worker then
        return nil
    end

    for index, entry in ipairs(worker.nutritionLedger or {}) do
        local isMedical = Config.IsMedicalProvisionEntry and Config.IsMedicalProvisionEntry(entry) or false
        local useKind = tostring(entry and entry.medicalUse or "")
        local units = math.max(0, tonumber(entry and entry.treatmentUnitsRemaining) or 0)
        if isMedical and units > 0 and (useKind == "bandage" or useKind == "") then
            local tierID, dirtyFullType = Internal.GetMedicalBandageTier(entry.fullType)
            return {
                index = index,
                entry = entry,
                tierID = tierID,
                dirtyFullType = dirtyFullType,
            }
        end
    end

    return nil
end

function Internal.ConsumeBandageSupply(workerID)
    local registry = Internal.GetRegistry()
    local worker = registry and registry.GetWorkerRaw and registry.GetWorkerRaw(workerID) or nil
    if not worker then
        return nil
    end

    local supply = Internal.ResolveBandageSupply(worker)
    if not supply then
        return nil
    end

    local entry = supply.entry
    entry.treatmentUnitsRemaining = math.max(0, tonumber(entry.treatmentUnitsRemaining) or 0) - 1
    if entry.treatmentUnitsRemaining <= 0 then
        Internal.RemoveNutritionEntry(worker, supply.index)
    else
        worker.nutritionCacheDirty = true
    end

    Internal.AddDirtyMedicalOutput(worker, supply.dirtyFullType)
    return {
        tierID = supply.tierID,
        fullType = entry and entry.fullType or nil,
        dirtyFullType = supply.dirtyFullType,
    }
end

Companion.ResolveBandageSupply = Internal.ResolveBandageSupply
Companion.ConsumeBandageSupply = Internal.ConsumeBandageSupply
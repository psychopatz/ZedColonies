DC_Colony = DC_Colony or {}
DC_Colony.Warehouse = DC_Colony.Warehouse or {}
DC_Colony.Warehouse.Internal = DC_Colony.Warehouse.Internal or {}

local Config = DC_Colony.Config
local Registry = DC_Colony.Registry
local Warehouse = DC_Colony.Warehouse
local Internal = Warehouse.Internal
local Data = Internal.Data or {}

Internal.Data = Data

function Data.NormalizeProvisionEntry(entry)
    if type(entry) ~= "table" or not entry.fullType then
        return nil
    end

    local normalized = {
        fullType = tostring(entry.fullType),
        entryID = tostring(entry.entryID or Registry.Internal.GenerateLedgerEntryID and Registry.Internal.GenerateLedgerEntryID("prov") or ""),
        displayName = entry.displayName or Registry.Internal.GetDisplayNameForFullType(entry.fullType),
        provisionType = Config.IsMedicalProvisionEntry and Config.IsMedicalProvisionEntry(entry) and "medical" or tostring(entry.provisionType or "nutrition"),
        caloriesRemaining = math.max(0, tonumber(entry.caloriesRemaining) or 0),
        hydrationRemaining = math.max(0, tonumber(entry.hydrationRemaining) or 0),
        treatmentUnitsRemaining = math.max(0, tonumber(entry.treatmentUnitsRemaining) or 0),
        medicalUse = entry.medicalUse and tostring(entry.medicalUse) or nil,
        qty = math.max(1, math.floor(tonumber(entry.qty) or 1)),
    }
    if entry.consumedOutputFullType then
        normalized.consumedOutputFullType = tostring(entry.consumedOutputFullType)
        normalized.consumedOutputDisplayName = tostring(entry.consumedOutputDisplayName or Registry.Internal.GetDisplayNameForFullType(entry.consumedOutputFullType))
        if entry.consumedOutputFluidAmount ~= nil then
            normalized.consumedOutputFluidAmount = math.max(0, tonumber(entry.consumedOutputFluidAmount) or 0)
        end
    end
    return normalized
end

function Data.NormalizeEquipmentEntry(entry)
    return Registry.Internal.NormalizeEquipmentEntry and Registry.Internal.NormalizeEquipmentEntry(entry) or nil
end

function Data.NormalizeOutputEntry(entry)
    return Registry.Internal.NormalizeOutputEntry and Registry.Internal.NormalizeOutputEntry(entry) or nil
end

function Data.StackProvisionEntries(entries)
    local stacked = {}
    local byKey = {}

    for _, raw in ipairs(entries or {}) do
        local entry = Data.NormalizeProvisionEntry(raw)
        if entry then
            local key = table.concat({
                entry.fullType,
                entry.provisionType or "",
                tostring(entry.caloriesRemaining or 0),
                tostring(entry.hydrationRemaining or 0),
                tostring(entry.treatmentUnitsRemaining or 0),
                tostring(entry.medicalUse or ""),
                tostring(entry.consumedOutputFullType or ""),
                tostring(entry.consumedOutputDisplayName or ""),
                tostring(entry.consumedOutputFluidAmount ~= nil and string.format("%.4f", entry.consumedOutputFluidAmount) or "")
            }, "|")
            local existing = byKey[key]
            if existing then
                existing.qty = existing.qty + entry.qty
            else
                byKey[key] = entry
                stacked[#stacked + 1] = entry
            end
        end
    end

    return stacked
end

function Data.StackEquipmentEntries(entries)
    local normalizedEntries = {}
    for _, raw in ipairs(entries or {}) do
        local entry = Data.NormalizeEquipmentEntry(raw)
        if entry then
            normalizedEntries[#normalizedEntries + 1] = entry
        end
    end

    return normalizedEntries
end

function Data.StackOutputEntries(entries)
    local stacked = {}
    local byKey = {}

    for _, raw in ipairs(entries or {}) do
        local entry = Data.NormalizeOutputEntry(raw)
        if entry then
            local key = Registry.Internal.GetOutputEntryStateSignature and Registry.Internal.GetOutputEntryStateSignature(entry)
                or entry.fullType
            local existing = byKey[key]
            if existing then
                existing.qty = existing.qty + entry.qty
            else
                byKey[key] = entry
                stacked[#stacked + 1] = entry
            end
        end
    end

    return stacked
end

Internal.NormalizeProvisionEntry = Data.NormalizeProvisionEntry
Internal.NormalizeEquipmentEntry = Data.NormalizeEquipmentEntry
Internal.NormalizeOutputEntry = Data.NormalizeOutputEntry

return Warehouse
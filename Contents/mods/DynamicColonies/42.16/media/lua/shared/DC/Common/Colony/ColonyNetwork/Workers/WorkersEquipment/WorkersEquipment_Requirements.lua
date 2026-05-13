DC_Colony = DC_Colony or {}
DC_Colony.Network = DC_Colony.Network or {}
DC_Colony.Network.Workers = DC_Colony.Network.Workers or {}

local Config = DC_Colony.Config
local Registry = DC_Colony.Registry
local Network = DC_Colony.Network
local Equipment = (Network.Workers or {}).Equipment or {}

Equipment.WeaponMetadataCache = Equipment.WeaponMetadataCache or {}

function Equipment.getWeaponMetadata(fullType)
    local key = tostring(fullType or "")
    if key == "" or not getScriptManager then
        return nil
    end

    if Equipment.WeaponMetadataCache[key] ~= nil then
        return Equipment.WeaponMetadataCache[key]
    end

    local scriptItem = getScriptManager():getItem(key)
    local ammoType = scriptItem and scriptItem.getAmmoType and scriptItem:getAmmoType() or nil
    ammoType = tostring(ammoType or "")

    local metadata = {
        ammoType = ammoType ~= "" and ammoType or nil,
        clipSize = math.max(0, tonumber(scriptItem and scriptItem.getClipSize and scriptItem:getClipSize() or 0) or 0),
    }
    Equipment.WeaponMetadataCache[key] = metadata
    return metadata
end

function Equipment.getAmmoTypeForWeapon(fullType)
    local metadata = Equipment.getWeaponMetadata(fullType)
    return metadata and metadata.ammoType or nil
end

function Equipment.normalizeItemTypeToken(fullType)
    local token = tostring(fullType or "")
    if token == "" then
        return ""
    end

    token = token:match("([^%.:]+)$") or token
    token = token:gsub("_", "")
    token = token:gsub("Box$", "")
    return string.lower(token)
end

function Equipment.getWorkerRangedAmmoType(worker)
    for _, entry in ipairs(worker and worker.toolLedger or {}) do
        if tostring(entry and entry.assignedRequirementKey or "") == "Colony.Combat.Ranged" then
            return Equipment.getAmmoTypeForWeapon(entry.fullType)
        end
    end
    for _, entry in ipairs(worker and worker.toolLedger or {}) do
        if Config.ItemMatchesWorkerEquipmentRequirement
            and Config.ItemMatchesWorkerEquipmentRequirement(entry and entry.fullType, "Colony.Combat.Ranged", worker) then
            return Equipment.getAmmoTypeForWeapon(entry.fullType)
        end
    end
    return nil
end

function Equipment.itemMatchesWorkerRangedAmmo(worker, fullType)
    local ammoType = tostring(Equipment.getWorkerRangedAmmoType(worker) or "")
    local itemType = tostring(fullType or "")
    if ammoType == "" or itemType == "" then
        return false
    end

    if itemType == ammoType or itemType == ammoType .. "Box" or itemType:gsub("Box$", "") == ammoType then
        return true
    end

    return Equipment.normalizeItemTypeToken(itemType) == Equipment.normalizeItemTypeToken(ammoType)
end

function Equipment.canAssignRequirement(worker, fullType, requirementKey)
    local targetKey = tostring(requirementKey or "")
    if targetKey == "Colony.Combat.Ammo" then
        return Equipment.itemMatchesWorkerRangedAmmo(worker, fullType)
    end
    if targetKey ~= "" then
        return Config.ItemMatchesWorkerEquipmentRequirement
            and Config.ItemMatchesWorkerEquipmentRequirement(fullType, targetKey, worker)
    end

    return Config.IsRequiredEquipmentFullTypeForWorker
        and Config.IsRequiredEquipmentFullTypeForWorker(fullType, worker)
        or (Config.IsRequiredEquipmentFullType and Config.IsRequiredEquipmentFullType(fullType, worker and worker.jobType))
end

function Equipment.resolveAssignmentRequirementKey(worker, fullType, preferredRequirementKey)
    local preferredKey = tostring(preferredRequirementKey or "")

    if preferredKey ~= "" and Equipment.canAssignRequirement(worker, fullType, preferredKey) then
        return preferredKey
    end

    if Equipment.itemMatchesWorkerRangedAmmo(worker, fullType) then
        return "Colony.Combat.Ammo"
    end

    if Config.ResolveWorkerEquipmentRequirementKey then
        local resolvedKey = tostring(Config.ResolveWorkerEquipmentRequirementKey(worker, fullType, preferredKey ~= "" and preferredKey or nil) or "")
        if resolvedKey ~= "" and Equipment.canAssignRequirement(worker, fullType, resolvedKey) then
            return resolvedKey
        end
    end

    local matches = Config.GetMatchingEquipmentRequirementDefinitionsForWorker
        and Config.GetMatchingEquipmentRequirementDefinitionsForWorker(fullType, worker)
        or {}
    for _, definition in ipairs(matches) do
        local requirementKey = tostring(definition and definition.requirementKey or "")
        if requirementKey ~= "" and Equipment.canAssignRequirement(worker, fullType, requirementKey) then
            return requirementKey
        end
    end

    return preferredKey ~= "" and preferredKey or nil
end

function Equipment.storeWorkerToolEntry(worker, toolEntry, requirementKey)
    local targetKey = tostring(requirementKey or "")
    if targetKey ~= "" and Registry.AddToolEntryForRequirement then
        return Registry.AddToolEntryForRequirement(worker, toolEntry, targetKey)
    end

    return Registry.AddToolEntry(worker, toolEntry)
end

return Equipment
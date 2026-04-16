DC_SupplyWindow = DC_SupplyWindow or {}
DC_SupplyWindow.Internal = DC_SupplyWindow.Internal or {}

local Internal = DC_SupplyWindow.Internal

local function getRegistryInternal()
    return DC_Colony and DC_Colony.Registry and DC_Colony.Registry.Internal or nil
end

local function getWorkerWarehouseEquipmentLedger(worker)
    local warehouse = worker and worker.warehouse or nil
    local ledger = warehouse and warehouse.ledgers and warehouse.ledgers.equipment or nil
    if type(ledger) == "table" then
        return ledger
    end

    local cache = DC_MainWindow and DC_MainWindow.cachedDetails or nil
    local cachedWorker = cache and worker and worker.workerID and cache[worker.workerID] or nil
    return cachedWorker and cachedWorker.warehouse and cachedWorker.warehouse.ledgers and cachedWorker.warehouse.ledgers.equipment or nil
end

local function sortCandidates(a, b)
    local sourceA = tostring(a and a.source or "")
    local sourceB = tostring(b and b.source or "")
    if sourceA ~= sourceB then
        return sourceA < sourceB
    end

    local nameA = tostring(a and a.displayName or a and a.fullType or "")
    local nameB = tostring(b and b.displayName or b and b.fullType or "")
    if nameA ~= nameB then
        return nameA < nameB
    end

    return tostring(a and a.fullType or "") < tostring(b and b.fullType or "")
end

function Internal.getDynamicTradingLockedItems(player)
    local targetPlayer = player or (Internal.getLocalPlayer and Internal.getLocalPlayer() or nil)
    local modData = targetPlayer and targetPlayer.getModData and targetPlayer:getModData() or nil
    return type(modData) == "table" and type(modData.DT_LockedItems) == "table" and modData.DT_LockedItems or nil
end

function Internal.isDynamicTradingLockedItemID(itemID, player)
    local lockedItems = Internal.getDynamicTradingLockedItems(player)
    if type(lockedItems) ~= "table" or itemID == nil then
        return false
    end

    return lockedItems[itemID] == true or lockedItems[tostring(itemID)] == true
end

function Internal.applyDynamicTradingLockState(entry)
    if not entry or entry.kind ~= "player" then
        return entry
    end

    entry.isDynamicTradingLocked = Internal.isDynamicTradingLockedItemID(entry.itemID)
    return entry
end

function Internal.getWorkerRequirementMatches(fullType, worker)
    local config = Internal.Config or {}
    if config.GetMatchingEquipmentRequirementDefinitionsForWorker then
        return config.GetMatchingEquipmentRequirementDefinitionsForWorker(fullType, worker) or {}
    end
    if config.GetMatchingEquipmentRequirementDefinitions then
        return config.GetMatchingEquipmentRequirementDefinitions(fullType, worker and worker.jobType or nil) or {}
    end
    return {}
end

function Internal.entryMatchesEquipmentRequirement(entry, requirementKey, worker)
    local targetKey = tostring(requirementKey or "")
    if targetKey == "" or not entry or not entry.fullType then
        return false
    end

    if tostring(entry.assignedRequirementKey or "") == targetKey then
        return true
    end

    for _, definition in ipairs(Internal.getWorkerRequirementMatches(entry.fullType, worker)) do
        if tostring(definition and definition.requirementKey or "") == targetKey then
            return true
        end
    end

    return false
end

function Internal.resolveWorkerEquipmentRequirementKey(entry, worker)
    if not entry or not entry.fullType then
        return nil
    end

    local config = Internal.Config or {}
    if config.ResolveWorkerEquipmentRequirementKey then
        return config.ResolveWorkerEquipmentRequirementKey(worker, entry.fullType, entry.assignedRequirementKey)
    end

    if tostring(entry.assignedRequirementKey or "") ~= "" then
        return tostring(entry.assignedRequirementKey)
    end

    local matches = Internal.getWorkerRequirementMatches(entry.fullType, worker)
    return matches[1] and tostring(matches[1].requirementKey or "") or nil
end

function Internal.getEquipmentPendingDedupeSignature(entry)
    local registryInternal = getRegistryInternal()
    local signature = registryInternal and registryInternal.GetEquipmentDurabilitySignature
        and registryInternal.GetEquipmentDurabilitySignature(entry)
        or tostring(entry and entry.fullType or "")
    return tostring(entry and entry.assignedRequirementKey or "") .. "|" .. tostring(signature or "")
end

function Internal.getAmmoTypeForWeaponFullType(fullType)
    local key = tostring(fullType or "")
    if key == "" or not getScriptManager then
        return nil
    end

    local cache = Internal.WeaponMetadataCache or {}
    if cache[key] ~= nil then
        return cache[key].ammoType
    end

    local scriptItem = getScriptManager():getItem(key)
    local ammoType = scriptItem and scriptItem.getAmmoType and scriptItem:getAmmoType() or nil
    ammoType = tostring(ammoType or "")

    cache[key] = {
        ammoType = ammoType ~= "" and ammoType or nil,
        clipSize = math.max(0, tonumber(scriptItem and scriptItem.getClipSize and scriptItem:getClipSize() or 0) or 0),
    }
    Internal.WeaponMetadataCache = cache
    return cache[key].ammoType
end

local function normalizeItemTypeToken(fullType)
    local token = tostring(fullType or "")
    if token == "" then
        return ""
    end

    token = token:match("([^%.:]+)$") or token
    token = token:gsub("_", "")
    token = token:gsub("Box$", "")
    return string.lower(token)
end

function Internal.getWorkerAssignedRangedWeaponEntry(worker)
    for _, entry in ipairs(worker and worker.toolLedger or {}) do
        if tostring(entry and entry.assignedRequirementKey or "") == "Colony.Combat.Ranged" then
            return entry
        end
    end

    for _, entry in ipairs(worker and worker.toolLedger or {}) do
        if Internal.entryMatchesEquipmentRequirement(entry, "Colony.Combat.Ranged", worker) then
            return entry
        end
    end

    return nil
end

function Internal.getWorkerRangedAmmoFullType(worker)
    local ranged = Internal.getWorkerAssignedRangedWeaponEntry(worker)
    return Internal.getAmmoTypeForWeaponFullType(ranged and ranged.fullType)
end

function Internal.isAmmoRequirementActive(worker)
    return tostring(Internal.getWorkerRangedAmmoFullType(worker) or "") ~= ""
end

function Internal.entryMatchesRangedAmmo(entry, worker)
    local ammoFullType = tostring(Internal.getWorkerRangedAmmoFullType(worker) or "")
    local entryFullType = tostring(entry and entry.fullType or "")
    if ammoFullType == "" or entryFullType == "" then
        return false
    end

    if entryFullType == ammoFullType or entryFullType == ammoFullType .. "Box" then
        return true
    end

    local boxedBase = entryFullType:gsub("Box$", "")
    if boxedBase == ammoFullType then
        return true
    end

    return normalizeItemTypeToken(entryFullType) == normalizeItemTypeToken(ammoFullType)
end

function Internal.buildEquipmentPickerCandidates(window, requirementKey)
    local candidates = {}
    local worker = window and window.workerData or nil
    local registryInternal = getRegistryInternal()
    local seenPlayerItems = {}

    for _, entry in ipairs(window and window.playerEntries or {}) do
        local targetRequirementKey = tostring(requirementKey or "")
        local matchesRequirement = targetRequirementKey == "Colony.Combat.Ammo"
            and Internal.entryMatchesRangedAmmo(entry, worker)
            or Internal.entryMatchesEquipmentRequirement(entry, requirementKey, worker)
        if entry
            and entry.kind == "player"
            and entry.canAssignTool == true
            and entry.isDynamicTradingLocked ~= true
            and matchesRequirement then
            local itemID = entry.itemID
            if itemID ~= nil and not seenPlayerItems[itemID] then
                seenPlayerItems[itemID] = true
                candidates[#candidates + 1] = {
                    source = "player",
                    sourceLabel = "Player",
                    displayName = entry.displayName,
                    fullType = entry.fullType,
                    texture = entry.texture,
                    itemID = entry.itemID,
                    entryID = entry.entryID,
                    assignedRequirementKey = tostring(requirementKey or ""),
                    statText = Internal.getEquipmentDurabilityText and Internal.getEquipmentDurabilityText(entry) or "",
                    sourceEntry = entry,
                }
            end
        end
    end

    local warehouseLedger = getWorkerWarehouseEquipmentLedger(worker)
    for index, ledgerEntry in ipairs(warehouseLedger or {}) do
        local targetRequirementKey = tostring(requirementKey or "")
        local matchesRequirement = targetRequirementKey == "Colony.Combat.Ammo"
            and Internal.entryMatchesRangedAmmo(ledgerEntry, worker)
            or Internal.entryMatchesEquipmentRequirement(ledgerEntry, requirementKey, worker)
        if (not registryInternal or not registryInternal.IsEquipmentEntryUsable or registryInternal.IsEquipmentEntryUsable(ledgerEntry))
            and matchesRequirement then
            local entry = Internal.buildWorkerToolEntry and Internal.buildWorkerToolEntry(ledgerEntry, index) or ledgerEntry
            if entry then
                candidates[#candidates + 1] = {
                    source = "warehouse",
                    sourceLabel = "Warehouse",
                    displayName = entry.displayName,
                    fullType = entry.fullType,
                    texture = entry.texture,
                    ledgerIndex = index,
                    entryID = entry.entryID,
                    assignedRequirementKey = tostring(requirementKey or ""),
                    statText = Internal.getEquipmentDurabilityText and Internal.getEquipmentDurabilityText(entry) or "",
                    sourceEntry = entry,
                }
            end
        end
    end

    table.sort(candidates, sortCandidates)
    return candidates
end

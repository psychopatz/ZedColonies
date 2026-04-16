DC_Colony = DC_Colony or {}
DC_Colony.Companion = DC_Colony.Companion or {}

local Internal = DC_Colony.Companion.Internal

function Internal.GetAmmoTypeForWeapon(fullType)
    local scriptItem = fullType and getScriptManager and getScriptManager():getItem(fullType) or nil
    if scriptItem and scriptItem.getAmmoType then
        local ammoType = scriptItem:getAmmoType()
        if ammoType and ammoType ~= "" then
            return tostring(ammoType)
        end
    end
    return nil
end

function Internal.GetWorkerAmmoEntry(worker)
    local selected = Internal.SelectEquipmentEntries and Internal.SelectEquipmentEntries(worker) or nil
    local targetEntry = selected and selected.ammo or nil
    if not targetEntry then
        return nil, nil
    end

    for index, entry in ipairs(worker and worker.toolLedger or {}) do
        if entry == targetEntry or tostring(entry and entry.entryID or "") == tostring(targetEntry and targetEntry.entryID or "") then
            return entry, index
        end
    end

    return targetEntry, nil
end

function Internal.GetWorkerAmmoCount(worker)
    local entry = Internal.GetWorkerAmmoEntry(worker)
    return math.max(0, math.floor(tonumber(entry and entry.qty) or 0))
end

function Internal.ConsumeWorkerRangedAmmo(worker, npcData, roundsUsed)
    local registry = Internal.GetRegistry and Internal.GetRegistry() or nil
    local entry, index = Internal.GetWorkerAmmoEntry(worker)
    local amount = math.max(1, math.floor(tonumber(roundsUsed) or 1))
    local remaining = math.max(0, math.floor(tonumber(entry and entry.qty) or 0) - amount)

    if not entry then
        if npcData and npcData.loadout then
            npcData.loadout.ammoCount = 0
        end
        return false, 0
    end

    if remaining <= 0 then
        if index and worker and worker.toolLedger then
            table.remove(worker.toolLedger, index)
        end
    else
        entry.qty = remaining
        if index and worker and worker.toolLedger then
            worker.toolLedger[index] = entry
        end
    end

    if registry and registry.Internal and registry.Internal.MarkToolCacheDirty then
        registry.Internal.MarkToolCacheDirty(worker)
    end

    if npcData and npcData.loadout then
        npcData.loadout.ammoCount = remaining
    end

    return true, remaining
end

function Internal.GetFallbackAmmoCount(weaponType)
    local scriptItem = weaponType and getScriptManager and getScriptManager():getItem(weaponType) or nil
    local clipSize = scriptItem and scriptItem.getClipSize and tonumber(scriptItem:getClipSize()) or 0
    clipSize = math.max(1, math.floor(clipSize or 0))
    return clipSize * 3
end
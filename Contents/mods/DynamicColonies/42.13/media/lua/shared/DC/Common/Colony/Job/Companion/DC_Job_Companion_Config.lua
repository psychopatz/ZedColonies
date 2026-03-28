DC_Colony = DC_Colony or {}
DC_Colony.Config = DC_Colony.Config or {}

local Config = DC_Colony.Config
local Registry = DC_Colony.Registry

local function lower(value)
    return string.lower(tostring(value or ""))
end

local function getRegistryInternal()
    return Registry and Registry.Internal or nil
end

local function getScriptItem(fullType)
    if not fullType or tostring(fullType) == "" or not getScriptManager then
        return nil
    end

    local manager = getScriptManager()
    return manager and manager:getItem(tostring(fullType)) or nil
end

local function entryHasTag(entry, requiredTag)
    local target = tostring(requiredTag or "")
    if target == "" then
        return false
    end

    for _, itemTag in ipairs(entry and entry.tags or {}) do
        local key = tostring(itemTag or "")
        if key == target then
            return true
        end
        if Config.TagMatches and Config.TagMatches(key, target) then
            return true
        end
    end

    return false
end

local function isUsableEquipmentEntry(entry)
    local registryInternal = getRegistryInternal()
    return registryInternal
        and registryInternal.IsEquipmentEntryUsable
        and registryInternal.IsEquipmentEntryUsable(entry)
        or false
end

local function isRangedWeaponEntry(entry)
    if not isUsableEquipmentEntry(entry) then
        return false
    end

    if entryHasTag(entry, "Weapon.Ranged.Firearm") then
        return true
    end

    local scriptItem = getScriptItem(entry and entry.fullType)
    if not scriptItem then
        return false
    end

    return (scriptItem.isRanged and scriptItem:isRanged())
        or (scriptItem.isAimedFirearm and scriptItem:isAimedFirearm())
        or (scriptItem.getAmmoType and scriptItem:getAmmoType() and scriptItem:getAmmoType() ~= "")
        or false
end

local function isMeleeWeaponEntry(entry)
    if not isUsableEquipmentEntry(entry) then
        return false
    end

    if entryHasTag(entry, "Weapon.Melee") and not entryHasTag(entry, "Weapon.Ranged.Ammo") then
        return true
    end

    local scriptItem = getScriptItem(entry and entry.fullType)
    if not scriptItem then
        return false
    end

    local swingAnim = scriptItem.getSwingAnim and scriptItem:getSwingAnim() or nil
    local displayCategory = lower(scriptItem.getDisplayCategory and scriptItem:getDisplayCategory() or nil)
    return (swingAnim and lower(swingAnim) ~= "") or displayCategory:find("melee", 1, true) ~= nil
end

local function isLooseAmmoEntry(entry)
    if not isUsableEquipmentEntry(entry) or not entryHasTag(entry, "Weapon.Ranged.Ammo") then
        return false
    end

    local fullType = lower(entry and entry.fullType)
    if fullType:find("box", 1, true) or fullType:find("carton", 1, true) then
        return false
    end

    return true
end

local function getLooseAmmoQty(entry)
    return math.max(1, math.floor(tonumber(entry and entry.qty) or 1))
end

local function getWeaponAmmoType(fullType)
    local scriptItem = getScriptItem(fullType)
    if scriptItem and scriptItem.getAmmoType then
        local ammoType = scriptItem:getAmmoType()
        if ammoType and tostring(ammoType) ~= "" then
            return tostring(ammoType)
        end
    end

    return nil
end

local function isBagEntry(entry)
    if not isUsableEquipmentEntry(entry) then
        return false
    end

    if entryHasTag(entry, "Colony.Carry.Backpack") then
        return true
    end

    local fullType = tostring(entry and entry.fullType or "")
    local scriptItem = getScriptItem(fullType)
    local equipSlot = scriptItem and scriptItem.canBeEquipped and scriptItem:canBeEquipped() or nil
    local capacity = tonumber(scriptItem and scriptItem.getCapacity and scriptItem:getCapacity() or 0) or 0
    local reduction = tonumber(scriptItem and scriptItem.getWeightReduction and scriptItem:getWeightReduction() or 0) or 0
    local lowered = lower(fullType)

    return equipSlot == "Back"
        or (capacity > 0 and reduction > 0 and (
            lowered:find("bag_", 1, true)
            or lowered:find("backpack", 1, true)
            or lowered:find("satchel", 1, true)
            or lowered:find("duffel", 1, true)
            or lowered:find("slingbag", 1, true)
            or lowered:find("schoolbag", 1, true)
            or lowered:find("hikingbag", 1, true)
        ))
end

local function buildLoadoutSignature(loadout)
    loadout = type(loadout) == "table" and loadout or {}
    return table.concat({
        tostring(loadout.rangedWeapon or ""),
        tostring(loadout.rangedAmmoType or ""),
        tostring(math.max(0, tonumber(loadout.ammoCount) or 0)),
        tostring(loadout.meleeWeapon or ""),
        tostring(loadout.bag or ""),
    }, "|")
end

function Config.IsDynamicTradingV2Active()
    if DynamicTrading and DynamicTrading.Manuals and DynamicTrading.Manuals.GetActiveAudienceState then
        local active = DynamicTrading.Manuals.GetActiveAudienceState()
        return active and active.v2 == true or false
    end

    local activated = getActivatedMods and getActivatedMods() or nil
    return activated and activated.contains and activated:contains("DynamicTradingV2") or false
end

function Config.GetOnlineOwnerPlayer(ownerUsername)
    local owner = Config.GetOwnerUsername and Config.GetOwnerUsername(ownerUsername) or tostring(ownerUsername or "local")

    local onlinePlayers = getOnlinePlayers and getOnlinePlayers() or nil
    if onlinePlayers then
        for index = 0, onlinePlayers:size() - 1 do
            local player = onlinePlayers:get(index)
            if player and Config.GetOwnerUsername and Config.GetOwnerUsername(player) == owner then
                return player
            end
        end
    end

    local player = Config.GetPlayerObject and Config.GetPlayerObject() or nil
    if player and Config.GetOwnerUsername and Config.GetOwnerUsername(player) == owner then
        return player
    end

    return nil
end

local function normalizeUUID(value)
    local text = value and tostring(value) or ""
    return text ~= "" and text or nil
end

local function getSoulRecord(uuid)
    local normalizedUUID = normalizeUUID(uuid)
    if not normalizedUUID then
        return nil
    end

    local runtimeData = DTNPCManager and DTNPCManager.Data and DTNPCManager.Data[normalizedUUID] or nil
    if runtimeData then
        return runtimeData
    end

    if DynamicTrading_Roster and DynamicTrading_Roster.GetSoul then
        local soul = DynamicTrading_Roster.GetSoul(normalizedUUID)
        if soul then
            return soul
        end
    end

    if DynamicTrading_Roster and DynamicTrading_Roster.GetSoulRegistry then
        return DynamicTrading_Roster.GetSoulRegistry(normalizedUUID)
    end

    return nil
end

local function getStoredWorkerCompanionUUID(worker)
    if not worker then
        return nil
    end

    local candidates = {
        worker.companionNPCUUID,
        worker.tradeSoulUUID,
        worker.sourceNPCUUID,
        worker.recruitedTraderUUID,
        worker.sourceNPCID,
    }

    for _, candidate in ipairs(candidates) do
        local normalizedUUID = normalizeUUID(candidate)
        if normalizedUUID and getSoulRecord(normalizedUUID) then
            return normalizedUUID
        end
    end

    return nil
end

local function getWorkerCompanionFaction(worker)
    if not worker or not DynamicTrading_Factions then
        return nil, nil
    end

    local ownerUsername = Config.GetOwnerUsername and Config.GetOwnerUsername(worker.ownerUsername) or tostring(worker.ownerUsername or "local")
    local faction = DynamicTrading_Factions.GetPlayerFaction and DynamicTrading_Factions.GetPlayerFaction(ownerUsername) or nil
    if faction and faction.id and DynamicTrading_Factions.RefreshPlayerFaction then
        faction = DynamicTrading_Factions.RefreshPlayerFaction(faction.id) or faction
    end

    if faction and faction.id then
        return faction.id, faction
    end

    local pseudoFactionID = "ColonyCompanion_" .. tostring(ownerUsername):gsub("[^%w_]", "_")
    return pseudoFactionID, nil
end

local function syncWorkerCompanionIdentity(worker, uuid)
    local normalizedUUID = normalizeUUID(uuid)
    if not worker or not normalizedUUID then
        return nil
    end

    worker.companionNPCUUID = normalizedUUID
    worker.tradeSoulUUID = normalizedUUID
    if not worker.sourceNPCUUID then
        worker.sourceNPCUUID = normalizedUUID
    end

    return normalizedUUID
end

local function updateSoulFromWorker(worker, uuid, factionID)
    if not worker or not uuid or not DynamicTrading_Roster or not DynamicTrading_Roster.SaveSoul then
        return nil
    end

    local soul = getSoulRecord(uuid)
    if not soul then
        return nil
    end

    soul.name = worker.name or soul.name
    soul.isFemale = worker.isFemale
    soul.identitySeed = worker.identitySeed or soul.identitySeed
    soul.archetypeID = worker.archetypeID or worker.profession or soul.archetypeID or "General"
    soul.factionID = factionID or soul.factionID
    soul.homeCoords = {
        x = tonumber(worker.homeX) or (soul.homeCoords and soul.homeCoords.x) or 0,
        y = tonumber(worker.homeY) or (soul.homeCoords and soul.homeCoords.y) or 0,
        z = tonumber(worker.homeZ) or (soul.homeCoords and soul.homeCoords.z) or 0,
    }
    soul.linkedWorkerID = worker.workerID
    soul.ownerUsername = worker.ownerUsername
    soul.isPlayerFactionTrader = true
    soul.status = soul.status or "Resting"

    DynamicTrading_Roster.SaveSoul(uuid, soul)
    syncWorkerCompanionIdentity(worker, uuid)
    return soul
end

local function isProtectState(state)
    return state == "ProtectRanged" or state == "ProtectMelee" or state == "ProtectAuto"
end

local function getCompanionTravelHours(worker, npcData)
    local travelHours = tonumber(Config.GetScavengeTravelHours and Config.GetScavengeTravelHours()) or 0.5
    if travelHours <= 0 then
        travelHours = 0.5
    end

    local startX = tonumber(npcData and npcData.lastX) or tonumber(worker and worker.homeX) or 0
    local startY = tonumber(npcData and npcData.lastY) or tonumber(worker and worker.homeY) or 0
    local homeX = tonumber(worker and worker.homeX) or startX
    local homeY = tonumber(worker and worker.homeY) or startY
    local dx = homeX - startX
    local dy = homeY - startY
    local dist = math.sqrt((dx * dx) + (dy * dy))

    if dist > 0 then
        travelHours = math.max(0.15, math.min(travelHours, dist / 250))
    end

    return travelHours
end

local function clearCompanionControlData(npcData)
    if not npcData then
        return
    end

    npcData.master = nil
    npcData.masterID = nil
    npcData.combatOrder = nil
    npcData.combatTargetID = nil
    npcData.requestedReturnStatus = "Resting"
    npcData.tasks = {}
    npcData.anchorX = nil
    npcData.anchorY = nil
    npcData.anchorZ = nil
end

local function persistCompanionSoulState(uuid, worker, npcData, returnTime)
    if not uuid or not npcData or not DynamicTrading_Roster or not DynamicTrading_Roster.SaveSoul then
        return false
    end

    clearCompanionControlData(npcData)
    npcData.status = "Away"
    npcData.returnTime = returnTime
    npcData.returnStatus = "Resting"
    npcData.state = "Idle"
    npcData.lastX = tonumber(worker and worker.homeX) or npcData.lastX
    npcData.lastY = tonumber(worker and worker.homeY) or npcData.lastY
    npcData.lastZ = tonumber(worker and worker.homeZ) or npcData.lastZ or 0

    DynamicTrading_Roster.SaveSoul(uuid, npcData)
    return true
end

local function getDepartureRemainingHours(npcData)
    local gameTime = getGameTime and getGameTime() or nil
    local currentHours = gameTime and gameTime:getWorldAgeHours() or 0
    local returnTime = tonumber(npcData and npcData.returnTime) or 0
    if returnTime <= currentHours then
        return math.max(0, tonumber(npcData and npcData.departureTravelHours) or 0)
    end
    return math.max(0, returnTime - currentHours)
end

local function finalizeWorkerCompanionReturn(worker, worldHour, message)
    if not worker then
        return false
    end

    local wasPending = worker.companionReturnPending == true
    worker.companionReturnPending = false
    worker.companionReturnUUID = nil
    worker.state = Config.States and Config.States.Idle or "Idle"
    worker.presenceState = Config.PresenceStates and Config.PresenceStates.Home or "Home"
    worker.travelHoursRemaining = 0
    worker.returnReason = nil

    if wasPending and message and message ~= "" then
        local registryInternal = getRegistryInternal()
        if registryInternal and registryInternal.AppendActivityLog then
            registryInternal.AppendActivityLog(worker, message, worldHour, "job")
        end
    end

    return true
end

function Config.UpdateWorkerCompanionReturnState(worker)
    if not worker or worker.companionReturnPending ~= true then
        return false
    end

    local uuid = normalizeUUID(worker.companionReturnUUID) or Config.ResolveWorkerCompanionUUID(worker)
    if not uuid then
        return finalizeWorkerCompanionReturn(worker, Config.GetCurrentWorldHours and Config.GetCurrentWorldHours() or 0, "Returned home from companion duty.")
    end

    local liveData = DTNPCManager and DTNPCManager.Data and DTNPCManager.Data[uuid] or nil
    local soul = getSoulRecord(uuid)

    if liveData and tostring(liveData.state or "") == "Departure" then
        worker.state = Config.States and Config.States.Working or "Working"
        worker.presenceState = Config.PresenceStates and Config.PresenceStates.AwayToHome or "AwayToHome"
        worker.travelHoursRemaining = getDepartureRemainingHours(liveData)
        return true
    end

    if not liveData then
        if not soul then
            return finalizeWorkerCompanionReturn(worker, Config.GetCurrentWorldHours and Config.GetCurrentWorldHours() or 0, "Returned home from companion duty.")
        end

        local status = tostring(soul.status or "")
        local returnStatus = tostring(soul.returnStatus or soul.requestedReturnStatus or "")
        if status == "Away" and (returnStatus == "" or returnStatus == "Resting") then
            return finalizeWorkerCompanionReturn(worker, Config.GetCurrentWorldHours and Config.GetCurrentWorldHours() or 0, "Returned home from companion duty.")
        end
    end

    worker.state = Config.States and Config.States.Working or "Working"
    worker.presenceState = Config.PresenceStates and Config.PresenceStates.AwayToHome or "AwayToHome"
    worker.travelHoursRemaining = getDepartureRemainingHours(soul)
    return true
end

function Config.ResolveWorkerCompanionUUID(worker)
    local resolvedUUID = getStoredWorkerCompanionUUID(worker)
    if resolvedUUID then
        return syncWorkerCompanionIdentity(worker, resolvedUUID)
    end

    if worker and worker.workerID and DynamicTrading_Factions and DynamicTrading_Factions.GetPlayerFaction then
        local _, faction = getWorkerCompanionFaction(worker)
        local mappedUUID = faction
            and type(faction.tradeWorkerSouls) == "table"
            and normalizeUUID(faction.tradeWorkerSouls[worker.workerID])
            or nil
        if mappedUUID and getSoulRecord(mappedUUID) then
            return syncWorkerCompanionIdentity(worker, mappedUUID)
        end
    end

    return nil
end

function Config.EnsureWorkerCompanionUUID(worker)
    local resolvedUUID = Config.ResolveWorkerCompanionUUID(worker)
    if resolvedUUID then
        return resolvedUUID
    end

    if not worker or not worker.workerID or not DynamicTrading_Roster or not DynamicTrading_Roster.AddSoul then
        return nil
    end

    local factionID, faction = getWorkerCompanionFaction(worker)
    local ensuredUUID = nil

    if faction and faction.id and DynamicTrading_Factions and DynamicTrading_Factions.EnsureTradeSoul then
        ensuredUUID = DynamicTrading_Factions.EnsureTradeSoul(faction.id, worker.workerID)
    end

    if not ensuredUUID then
        ensuredUUID = DynamicTrading_Roster.AddSoul(
            factionID,
            worker.archetypeID or worker.profession or "General",
            {
                x = tonumber(worker.homeX) or 0,
                y = tonumber(worker.homeY) or 0,
                z = tonumber(worker.homeZ) or 0,
            }
        )
    end

    if not ensuredUUID then
        return nil
    end

    if faction and type(faction.tradeWorkerSouls) == "table" then
        faction.tradeWorkerSouls[worker.workerID] = ensuredUUID
    end

    worker.companionFactionID = factionID
    updateSoulFromWorker(worker, ensuredUUID, factionID)
    if Registry and Registry.Save then
        Registry.Save()
    end
    return syncWorkerCompanionIdentity(worker, ensuredUUID)
end

function Config.HasRecruitedV2NPC(worker)
    if Config.ResolveWorkerCompanionUUID(worker) then
        return true
    end

    return normalizeUUID(worker and worker.sourceNPCID) ~= nil
        or normalizeUUID(worker and worker.sourceNPCUUID) ~= nil
        or normalizeUUID(worker and worker.recruitedTraderUUID) ~= nil
        or normalizeUUID(worker and worker.companionNPCUUID) ~= nil
end

function Config.IsCompanionControlJob(jobType)
    local normalizedJobType = Config.NormalizeJobType and Config.NormalizeJobType(jobType) or tostring(jobType or "")
    return normalizedJobType == tostring((Config.JobTypes or {}).FollowPlayer or "FollowPlayer")
end

function Config.IsJobTypeVisible(jobType, worker)
    if Config.IsCompanionControlJob and Config.IsCompanionControlJob(jobType) then
        return Config.IsDynamicTradingV2Active() and Config.HasRecruitedV2NPC(worker)
    end

    return true
end

function Config.CanWorkerTakeFollowPlayerJob(worker)
    if not Config.IsDynamicTradingV2Active() then
        return false, "Follow Player requires DynamicTrading V2."
    end

    if not Config.HasRecruitedV2NPC(worker) then
        return false, "Only recruited V2 NPC workers can use Follow Player."
    end

    return true, nil
end

function Config.BuildWorkerCompanionLoadout(worker)
    local meleeWeapon = nil
    local rangedWeapon = nil
    local bag = nil
    local firstLooseAmmoType = nil
    local ammoCountsByType = {}

    for _, entry in ipairs(worker and worker.toolLedger or {}) do
        if isUsableEquipmentEntry(entry) then
            if not meleeWeapon and isMeleeWeaponEntry(entry) then
                meleeWeapon = tostring(entry.fullType)
            end
            if not rangedWeapon and isRangedWeaponEntry(entry) then
                rangedWeapon = tostring(entry.fullType)
            end
            if not bag and isBagEntry(entry) then
                bag = tostring(entry.fullType)
            end
            if isLooseAmmoEntry(entry) then
                local fullType = tostring(entry.fullType or "")
                ammoCountsByType[fullType] = (ammoCountsByType[fullType] or 0) + getLooseAmmoQty(entry)
                if not firstLooseAmmoType then
                    firstLooseAmmoType = fullType
                end
            end
        end
    end

    local rangedAmmoType = getWeaponAmmoType(rangedWeapon) or firstLooseAmmoType

    return {
        rangedWeapon = rangedWeapon,
        rangedAmmoType = rangedAmmoType,
        ammoCount = rangedAmmoType and math.max(0, tonumber(ammoCountsByType[rangedAmmoType]) or 0) or 0,
        meleeWeapon = meleeWeapon,
        bag = bag,
    }
end

function Config.SyncWorkerCompanionLoadout(worker)
    if (isClient() and not isServer()) or not Config.IsDynamicTradingV2Active() then
        return false
    end

    local uuid = Config.EnsureWorkerCompanionUUID(worker)
    if not uuid or not DTNPCServerCore or not DTNPCServerCore.UpdateNPCByUUID then
        return false
    end

    local loadout = Config.BuildWorkerCompanionLoadout(worker)
    local currentData = DTNPCManager and DTNPCManager.Data and DTNPCManager.Data[uuid] or nil
    if currentData and DTNPCProtect and DTNPCProtect.EnsureDataDefaults then
        DTNPCProtect.EnsureDataDefaults(currentData)
    end

    if buildLoadoutSignature(currentData and currentData.loadout or nil) == buildLoadoutSignature(loadout) then
        return false
    end

    DTNPCServerCore.UpdateNPCByUUID(uuid, {
        loadout = loadout
    }, false)
    return true
end

function Config.ReleaseWorkerCompanionControl(worker)
    if (isClient() and not isServer()) or not Config.IsDynamicTradingV2Active() then
        return false
    end

    if Config.UpdateWorkerCompanionReturnState and Config.UpdateWorkerCompanionReturnState(worker) then
        if worker and worker.companionReturnPending == true then
            return true
        end
    end

    local uuid = Config.ResolveWorkerCompanionUUID(worker)
    if not uuid then
        return false
    end

    local currentData = getSoulRecord(uuid)
    if currentData and DTNPCProtect and DTNPCProtect.EnsureDataDefaults then
        DTNPCProtect.EnsureDataDefaults(currentData)
        if currentData.state == "Departure" then
            if worker then
                worker.companionReturnPending = true
                worker.companionReturnUUID = uuid
                worker.state = Config.States and Config.States.Working or "Working"
                worker.presenceState = Config.PresenceStates and Config.PresenceStates.AwayToHome or "AwayToHome"
                worker.travelHoursRemaining = getDepartureRemainingHours(currentData)
            end
            return true
        end
        if currentData.state == "Idle"
            and currentData.master == nil
            and currentData.masterID == nil
            and currentData.combatOrder == nil then
            return false
        end
    end

    local gameTime = getGameTime and getGameTime() or nil
    local currentHours = gameTime and gameTime:getWorldAgeHours() or 0
    local travelHours = getCompanionTravelHours(worker, currentData)
    local returnTime = currentHours + travelHours
    local targetX = tonumber(worker and worker.homeX) or (currentData and currentData.homeCoords and currentData.homeCoords.x) or nil
    local targetY = tonumber(worker and worker.homeY) or (currentData and currentData.homeCoords and currentData.homeCoords.y) or nil
    local targetZ = tonumber(worker and worker.homeZ) or (currentData and currentData.homeCoords and currentData.homeCoords.z) or 0

    if currentData then
        clearCompanionControlData(currentData)
    end

    local departed = DTNPCManager
        and DTNPCManager.TryStartLiveDeparture
        and DTNPCManager.TryStartLiveDeparture(uuid, "Resting", travelHours, targetX, targetY, targetZ)

    if not departed then
        persistCompanionSoulState(uuid, worker, currentData, returnTime)

        if DTNPCManager and DTNPCManager.Data and DTNPCManager.Data[uuid] then
            DTNPCManager.RemoveData(uuid, "Away", returnTime, "Resting")
        elseif DynamicTrading_Roster and DynamicTrading_Roster.UpdateSoulStatus then
            DynamicTrading_Roster.UpdateSoulStatus(uuid, "Away", returnTime, "Resting")
        end

        if DTNPCServerCore and DTNPCServerCore.FindZombieByUUID then
            local zombie = DTNPCServerCore.FindZombieByUUID(uuid)
            if zombie then
                zombie:removeFromWorld()
                zombie:removeFromSquare()
            end
        end
        finalizeWorkerCompanionReturn(worker, currentHours, nil)
    elseif worker then
        local wasPending = worker.companionReturnPending == true
        worker.companionReturnPending = true
        worker.companionReturnUUID = uuid
        worker.state = Config.States and Config.States.Working or "Working"
        worker.presenceState = Config.PresenceStates and Config.PresenceStates.AwayToHome or "AwayToHome"
        worker.travelHoursRemaining = travelHours
        worker.returnReason = nil
        if not wasPending then
            local registryInternal = getRegistryInternal()
            if registryInternal and registryInternal.AppendActivityLog then
                registryInternal.AppendActivityLog(worker, "Heading home from companion duty.", currentHours, "job")
            end
        end
    end

    return true
end

function Config.SyncWorkerCompanionFollow(worker)
    if (isClient() and not isServer()) then
        return false, "ClientOnly"
    end

    local canFollow, reason = Config.CanWorkerTakeFollowPlayerJob(worker)
    if not canFollow then
        return false, reason
    end

    if not DTNPCServerCore or not DTNPCServerCore.IssueOrderByUUID then
        return false, "MissingV2Bridge"
    end

    local ownerPlayer = Config.GetOnlineOwnerPlayer and Config.GetOnlineOwnerPlayer(worker and worker.ownerUsername) or nil
    if not ownerPlayer then
        return false, "OwnerOffline"
    end

    local uuid = Config.EnsureWorkerCompanionUUID(worker)
    if not uuid then
        return false, "MissingCompanionUUID"
    end

    Config.SyncWorkerCompanionLoadout(worker)

    if DTNPCServerCore.SpawnOffscreenCompanionByUUID then
        local spawned = DTNPCServerCore.SpawnOffscreenCompanionByUUID(uuid, ownerPlayer)
        if not spawned then
            return false, "SpawnFailed"
        end
    end

    local currentData = getSoulRecord(uuid)
    if currentData and DTNPCProtect and DTNPCProtect.EnsureDataDefaults then
        DTNPCProtect.EnsureDataDefaults(currentData)
    end

    local expectedMaster = Config.GetOwnerUsername and Config.GetOwnerUsername(ownerPlayer) or ownerPlayer:getUsername()
    local expectedMasterID = ownerPlayer.getOnlineID and ownerPlayer:getOnlineID() or nil

    local desiredState = "Follow"
    local desiredCombatOrder = nil
    if currentData and isProtectState(currentData.combatOrder) then
        desiredState = currentData.combatOrder
        desiredCombatOrder = currentData.combatOrder
    elseif currentData and isProtectState(currentData.state) then
        desiredState = currentData.state
        desiredCombatOrder = currentData.combatOrder or currentData.state
    end

    if currentData
        and currentData.state == desiredState
        and currentData.master == expectedMaster
        and currentData.masterID == expectedMasterID
        and currentData.combatOrder == desiredCombatOrder then
        return true, nil
    end

    DTNPCServerCore.IssueOrderByUUID(uuid, ownerPlayer, {
        state = desiredState,
        combatOrder = desiredCombatOrder
    })
    return true, nil
end

return Config

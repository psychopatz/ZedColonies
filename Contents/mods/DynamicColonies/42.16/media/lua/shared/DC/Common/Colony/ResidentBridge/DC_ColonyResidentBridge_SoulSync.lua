DC_Colony = DC_Colony or {}
DC_Colony.ResidentBridge = DC_Colony.ResidentBridge or {}

local Bridge = DC_Colony.ResidentBridge
local Internal = Bridge.Internal or {}

local function logResident(message)
    if DynamicTrading and DynamicTrading.Log then
        DynamicTrading.Log("DColony", "Resident", "Bridge", tostring(message or ""))
    end
end

local function copyPointToWorker(worker, fieldPrefix, point)
    if type(worker) ~= "table" or not Internal.HasPoint(point) then
        return false
    end

    local xKey = tostring(fieldPrefix) .. "X"
    local yKey = tostring(fieldPrefix) .. "Y"
    local zKey = tostring(fieldPrefix) .. "Z"
    local nextX = math.floor(tonumber(point.x) or 0)
    local nextY = math.floor(tonumber(point.y) or 0)
    local nextZ = math.floor(tonumber(point.z) or 0)
    local changed = worker[xKey] ~= nextX or worker[yKey] ~= nextY or worker[zKey] ~= nextZ
    worker[xKey] = nextX
    worker[yKey] = nextY
    worker[zKey] = nextZ
    return changed
end

local function chooseFallbackHome(anchorSnapshot, existingSoul)
    if anchorSnapshot and Internal.HasPoint(anchorSnapshot.home) then
        return Internal.CopyPoint(anchorSnapshot.home)
    end

    if existingSoul and Internal.HasPoint(existingSoul.homeCoords) then
        return Internal.CopyPoint(existingSoul.homeCoords)
    end

    return nil
end

local function chooseFallbackWork(anchorSnapshot, existingSoul, fallbackHome)
    if anchorSnapshot and Internal.HasPoint(anchorSnapshot.work) then
        return Internal.CopyPoint(anchorSnapshot.work)
    end

    if existingSoul and Internal.HasPoint(existingSoul.workCoords) then
        return Internal.CopyPoint(existingSoul.workCoords)
    end

    return Internal.CopyPoint(fallbackHome)
end

local function setResidentFields(worker, npcData, anchorSnapshot)
    npcData.dcResident = true
    npcData.dcResidentOwnerUsername = tostring(worker.ownerUsername or npcData.ownerUsername or "")
    npcData.dcResidentColonyId = tostring(worker.colonyID or npcData.dcResidentColonyId or "")
    npcData.dcResidentWorkerID = tostring(worker.workerID or npcData.dcResidentWorkerID or "")
    npcData.dcResidentRole = Internal.GetResidentRole(worker)
    npcData.dcResidentHomeMode = tostring(anchorSnapshot and anchorSnapshot.homeMode or "base")
    npcData.abstractResident = false
end

local function applyWorkerIdentity(worker, npcData)
    npcData.name = worker.name or npcData.name
    npcData.isFemale = worker.isFemale
    npcData.identitySeed = worker.identitySeed or npcData.identitySeed
    npcData.visualID = worker.visualID or npcData.visualID
    npcData.archetypeID = worker.archetypeID or npcData.archetypeID or worker.profession or "General"
    npcData.ownerUsername = worker.ownerUsername
    npcData.linkedWorkerID = worker.workerID
    npcData.isPlayerFactionTrader = false
    npcData.factionID = npcData.factionID or "Independent"
end

local function applyCompanionDerivedData(worker, npcData)
    local companionInternal = Internal.GetCompanionInternal()
    if not companionInternal then
        return
    end

    if companionInternal.BuildLoadoutFromWorker then
        npcData.loadout = companionInternal.BuildLoadoutFromWorker(worker)
    end
    if companionInternal.BuildHealthSeed then
        companionInternal.BuildHealthSeed(worker, npcData)
    end

    if Internal.IsTravelCompanionWorker(worker) and companionInternal.SetSoulCompanionFlags then
        local config = Internal.GetConfig()
        local activeState = config and config.PresenceStates and config.PresenceStates.CompanionActive or "CompanionActive"
        companionInternal.SetSoulCompanionFlags(worker, npcData, tostring(worker.presenceState or "") == tostring(activeState))
    elseif not Internal.IsTravelCompanionWorker(worker) then
        npcData.dcCompanionActive = false
        npcData.dcCompanionStage = nil
    end
end

local function applyResidentPosition(worker, npcData, homeCoords, workCoords)
    local config = Internal.GetConfig()
    local states = config and config.States or {}
    local presenceStates = config and config.PresenceStates or {}
    local presenceState = tostring(worker.presenceState or "")
    local state = tostring(worker.state or "")

    if Internal.IsTravelCompanionWorker(worker)
        and presenceState ~= tostring(presenceStates.Home or "Home") then
        return
    end

    local useWork = state ~= tostring(states.Resting or "Resting")
        and state ~= tostring(states.Idle or "Idle")
        and state ~= tostring(states.Incapacitated or "Incapacitated")
        and Internal.HasPoint(workCoords)
    local anchor = useWork and workCoords or homeCoords

    if not Internal.HasPoint(anchor) then
        return
    end

    npcData.status = useWork and "Working" or "Resting"
    npcData.returnTime = 0
    npcData.returnStatus = nil
    npcData.lastX = math.floor(tonumber(anchor.x) or 0)
    npcData.lastY = math.floor(tonumber(anchor.y) or 0)
    npcData.lastZ = math.floor(tonumber(anchor.z) or 0)
end

local function ensureResidentSoul(worker, homeCoords)
    if not DynamicTrading_Roster or not DynamicTrading_Roster.AddSoul or not Internal.HasPoint(homeCoords) then
        return nil
    end

    local uuid = DynamicTrading_Roster.AddSoul(
        "Independent",
        worker.archetypeID or worker.profession or "General",
        homeCoords,
        {
            forceFaction = true,
            suppressRecruitLog = true
        }
    )
    if not uuid then
        return nil
    end

    worker.residentSoulUUID = uuid
    if Internal.IsTravelCompanionWorker(worker) then
        local companionData = Internal.GetCompanionData(worker)
        if companionData then
            companionData.uuid = companionData.uuid or uuid
        end
    end

    return uuid
end

function Bridge.SyncWorker(worker)
    if not Internal.IsAuthority() or not Internal.IsWorkerLiving(worker) then
        return false, nil
    end

    local anchorSnapshot = Bridge.BuildAnchorSnapshot(worker)
    local existingUUID, existingSoul = Internal.FindResidentSoul(worker)
    local homeCoords = chooseFallbackHome(anchorSnapshot, existingSoul)
    local workCoords = chooseFallbackWork(anchorSnapshot, existingSoul, homeCoords)
    if not Internal.HasPoint(homeCoords) then
        logResident("Skipping resident sync; no valid home coords for workerID=" .. tostring(worker and worker.workerID))
        return false, nil
    end

    local workerChanged = false
    workerChanged = copyPointToWorker(worker, "home", homeCoords) or workerChanged
    if Internal.HasPoint(workCoords) then
        workerChanged = copyPointToWorker(worker, "work", workCoords) or workerChanged
    end

    local uuid = existingUUID
    local npcData = existingSoul
    if not uuid then
        uuid = ensureResidentSoul(worker, homeCoords)
        if not uuid or not DynamicTrading_Roster or not DynamicTrading_Roster.GetSoul then
            return workerChanged, nil
        end
        npcData = DynamicTrading_Roster.GetSoul(uuid)
        workerChanged = true
    end

    if type(npcData) ~= "table" then
        return workerChanged, uuid
    end

    applyWorkerIdentity(worker, npcData)
    setResidentFields(worker, npcData, anchorSnapshot)
    npcData.homeCoords = homeCoords
    npcData.workCoords = workCoords or npcData.workCoords or homeCoords
    applyResidentPosition(worker, npcData, homeCoords, workCoords)
    applyCompanionDerivedData(worker, npcData)

    if DynamicTrading_Roster and DynamicTrading_Roster.SaveSoul then
        DynamicTrading_Roster.SaveSoul(uuid, npcData)
    end

    if worker.residentSoulUUID ~= uuid then
        worker.residentSoulUUID = uuid
        workerChanged = true
    end

    return workerChanged, uuid
end

function Bridge.RemoveWorker(worker)
    if not Internal.IsAuthority() or type(worker) ~= "table" then
        return false
    end

    local uuid = tostring(worker.residentSoulUUID or Internal.GetCompanionUUID(worker) or "")
    if uuid == "" then
        return false
    end

    if DTNPCManager and DTNPCManager.RemoveData then
        DTNPCManager.RemoveData(uuid, nil, nil, nil, "resident-worker-removed")
    end
    if DynamicTrading_Roster and DynamicTrading_Roster.RemoveSpecificSoul then
        DynamicTrading_Roster.RemoveSpecificSoul(uuid)
    end

    worker.residentSoulUUID = nil
    local companionData = Internal.GetCompanionData(worker)
    if companionData and tostring(companionData.uuid or "") == uuid then
        companionData.uuid = nil
    end

    return true
end

return Bridge

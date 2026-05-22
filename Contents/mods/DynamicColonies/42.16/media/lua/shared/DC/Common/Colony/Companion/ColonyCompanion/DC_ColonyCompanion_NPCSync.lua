DC_Colony = DC_Colony or {}
DC_Colony.Companion = DC_Colony.Companion or {}

local Internal = DC_Colony.Companion.Internal
local Config = Internal.Config

local function resolveWorkerFactionID(worker)
    if not worker then
        return nil
    end

    if DC_Colony and DC_Colony.ResidentBridge and DC_Colony.ResidentBridge.Internal
        and DC_Colony.ResidentBridge.Internal.ResolvePlayerFactionID then
        return DC_Colony.ResidentBridge.Internal.ResolvePlayerFactionID(worker.ownerUsername)
    end

    return nil
end

local function syncWorkerMetadata(worker, npcData, factionID)
    if not worker or not npcData then
        return false
    end

    local health = Internal.GetHealth and Internal.GetHealth() or nil

    npcData.name = worker.name or npcData.name
    npcData.isFemale = worker.isFemale
    npcData.identitySeed = worker.identitySeed or npcData.identitySeed
    npcData.archetypeID = worker.archetypeID or npcData.archetypeID or worker.profession or "General"
    npcData.ownerUsername = worker.ownerUsername
    npcData.linkedWorkerID = worker.workerID
    npcData.isPlayerFactionTrader = false
    npcData.factionID = factionID or "Independent"
    npcData.homeCoords = {
        x = worker.homeX or 0,
        y = worker.homeY or 0,
        z = worker.homeZ or 0,
    }
    npcData.dcLootConfig = Internal.CloneCompanionLootConfig and Internal.CloneCompanionLootConfig(Internal.GetCompanionLootConfig(worker))
        or Internal.GetCompanionLootConfig(worker)
    npcData.loadout = Internal.BuildLoadoutFromWorker(worker)
    npcData.restingRegenMultiplier = health and health.GetSleepHealingRate and health.GetSleepHealingRate(worker) or nil
    Internal.SetSoulCompanionFlags(worker, npcData, worker.presenceState == Config.PresenceStates.CompanionActive)
    return true
end

local function buildActiveLiveUpdates(npcData)
    if not npcData then
        return nil
    end

    return {
        name = npcData.name,
        isFemale = npcData.isFemale,
        identitySeed = npcData.identitySeed,
        archetypeID = npcData.archetypeID,
        ownerUsername = npcData.ownerUsername,
        linkedWorkerID = npcData.linkedWorkerID,
        isPlayerFactionTrader = npcData.isPlayerFactionTrader,
        factionID = npcData.factionID,
        loadout = npcData.loadout,
        restingRegenMultiplier = npcData.restingRegenMultiplier,
        dcLootConfig = npcData.dcLootConfig,
        dcCompanionJob = npcData.dcCompanionJob,
        dcCompanionOwner = npcData.dcCompanionOwner,
        dcCompanionStage = npcData.dcCompanionStage,
        dcCompanionActive = npcData.dcCompanionActive,
        dcCommanderUsername = npcData.dcCommanderUsername,
        dcCommanderOnlineID = npcData.dcCommanderOnlineID,
        dcCommandVersion = npcData.dcCommandVersion,
    }
end

function Internal.SyncNPCFromWorker(worker, uuid)
    if not worker or not uuid then
        return false
    end

    local npcData = Internal.GetSoul(uuid)
    if not npcData then
        return false
    end

    local factionID = resolveWorkerFactionID(worker)
    syncWorkerMetadata(worker, npcData, factionID)
    Internal.BuildHealthSeed(worker, npcData)
    Internal.SaveSoul(uuid, npcData)
    return true
end

function Internal.SyncActiveNPCFromWorker(worker, shouldBroadcast)
    if not worker or not Internal.IsTravelCompanionWorker(worker) then
        return false
    end

    local uuid = Internal.GetCompanionUUID(worker)
    if not uuid then
        return false
    end

    if isClient() and not isServer() then
        return Internal.SyncNPCFromWorker(worker, uuid) == true
    end

    local liveZombie = nil
    local liveNPCData = nil
    if DTNPCServerCore and DTNPCServerCore.GetNPCDataByUUID then
        liveZombie, liveNPCData = DTNPCServerCore.GetNPCDataByUUID(uuid)
    end

    if not liveZombie or liveZombie:isDead() or not liveNPCData then
        return Internal.SyncNPCFromWorker(worker, uuid) == true
    end

    local npcData = Internal.GetSoul(uuid) or liveNPCData
    if not npcData then
        return false
    end

    local factionID = resolveWorkerFactionID(worker)
    syncWorkerMetadata(worker, npcData, factionID)
    Internal.SaveSoul(uuid, npcData)

    local liveSynced = false
    if DTNPCServerCore and DTNPCServerCore.UpdateNPCByUUID then
        local changed = DTNPCServerCore.UpdateNPCByUUID(
            uuid,
            buildActiveLiveUpdates(npcData),
            shouldBroadcast ~= false
        )
        liveSynced = changed == true
        Internal.Debug(
            "SyncActiveNPCFromWorker workerID=" .. tostring(worker.workerID)
                .. " uuid=" .. tostring(uuid)
                .. " liveSynced=" .. tostring(liveSynced)
                .. " liveHealthAuthoritative=true"
                .. " melee=" .. tostring(npcData.loadout and npcData.loadout.meleeWeapon or "nil")
                .. " ranged=" .. tostring(npcData.loadout and npcData.loadout.rangedWeapon or "nil")
                .. " bag=" .. tostring(npcData.loadout and npcData.loadout.bag or "nil")
        )
    end

    return true
end

DC_Colony = DC_Colony or {}
DC_Colony.Companion = DC_Colony.Companion or {}

local Internal = DC_Colony.Companion.Internal
local Config = Internal.Config

function Internal.SyncNPCFromWorker(worker, uuid)
    if not worker or not uuid then
        return false
    end

    local npcData = Internal.GetSoul(uuid)
    if not npcData then
        return false
    end

    npcData.name = worker.name or npcData.name
    npcData.isFemale = worker.isFemale
    npcData.identitySeed = worker.identitySeed or npcData.identitySeed
    npcData.archetypeID = worker.archetypeID or npcData.archetypeID or worker.profession or "General"
    npcData.ownerUsername = worker.ownerUsername
    npcData.linkedWorkerID = worker.workerID
    npcData.isPlayerFactionTrader = false
    npcData.factionID = npcData.factionID or "Independent"
    npcData.homeCoords = {
        x = worker.homeX or 0,
        y = worker.homeY or 0,
        z = worker.homeZ or 0,
    }
    npcData.loadout = Internal.BuildLoadoutFromWorker(worker)
    Internal.BuildHealthSeed(worker, npcData)
    Internal.SetSoulCompanionFlags(worker, npcData, worker.presenceState == Config.PresenceStates.CompanionActive)
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

    local syncedSoul = Internal.SyncNPCFromWorker(worker, uuid) == true
    local npcData = Internal.GetSoul(uuid)
    if not npcData then
        return syncedSoul
    end

    if isClient() and not isServer() then
        return syncedSoul
    end

    local liveSynced = false
    if DTNPCServerCore and DTNPCServerCore.UpdateNPCByUUID then
        local changed = DTNPCServerCore.UpdateNPCByUUID(uuid, {
            loadout = npcData.loadout,
            combatHealth = npcData.combatHealth,
            restingRegenMultiplier = npcData.restingRegenMultiplier,
        }, shouldBroadcast ~= false)
        liveSynced = changed == true
        Internal.Debug(
            "SyncActiveNPCFromWorker workerID=" .. tostring(worker.workerID)
                .. " uuid=" .. tostring(uuid)
                .. " liveSynced=" .. tostring(liveSynced)
                .. " hp=" .. tostring(npcData.combatHealth and npcData.combatHealth.current or "nil")
                .. "/" .. tostring(npcData.combatHealth and npcData.combatHealth.max or "nil")
                .. " melee=" .. tostring(npcData.loadout and npcData.loadout.meleeWeapon or "nil")
                .. " ranged=" .. tostring(npcData.loadout and npcData.loadout.rangedWeapon or "nil")
                .. " bag=" .. tostring(npcData.loadout and npcData.loadout.bag or "nil")
        )
    end

    return syncedSoul or liveSynced
end
DC_Colony = DC_Colony or {}
DC_Colony.ResidentBridge = DC_Colony.ResidentBridge or {}

local Bridge = DC_Colony.ResidentBridge
local Internal = Bridge.Internal or {}

Bridge.Internal = Internal

function Internal.IsAuthority()
    if isClient and isClient() and not (isServer and isServer()) then
        return false
    end

    return true
end

function Internal.GetConfig()
    return DC_Colony and DC_Colony.Config or nil
end

function Internal.GetRegistry()
    return DC_Colony and DC_Colony.Registry or nil
end

function Internal.GetCompanion()
    return DC_Colony and DC_Colony.Companion or nil
end

function Internal.GetCompanionInternal()
    local companion = Internal.GetCompanion()
    return companion and companion.Internal or nil
end

function Internal.GetCompanionData(worker)
    local companionInternal = Internal.GetCompanionInternal()
    if companionInternal and companionInternal.GetCompanionData then
        return companionInternal.GetCompanionData(worker)
    end

    if type(worker) ~= "table" then
        return nil
    end

    worker.companion = type(worker.companion) == "table" and worker.companion or {}
    return worker.companion
end

function Internal.GetCompanionUUID(worker)
    local companionInternal = Internal.GetCompanionInternal()
    if companionInternal and companionInternal.GetCompanionUUID then
        return companionInternal.GetCompanionUUID(worker)
    end

    local companionData = Internal.GetCompanionData(worker)
    local uuid = companionData and tostring(companionData.uuid or "") or ""
    if uuid ~= "" then
        return uuid
    end

    return nil
end

function Internal.IsTravelCompanionWorker(worker)
    local companion = Internal.GetCompanion()
    if companion and companion.IsTravelCompanionWorker then
        return companion.IsTravelCompanionWorker(worker) == true
    end

    local config = Internal.GetConfig()
    local jobTypes = config and config.JobTypes or {}
    local normalized = config and config.NormalizeJobType
        and config.NormalizeJobType(worker and worker.jobType)
        or tostring(worker and worker.jobType or "")
    return normalized == tostring(jobTypes.TravelCompanion or "TravelCompanion")
end

function Internal.IsWorkerLiving(worker)
    if type(worker) ~= "table" then
        return false
    end

    local config = Internal.GetConfig()
    local states = config and config.States or {}
    local state = tostring(worker.state or "")
    if state == tostring(states.Dead or "Dead") then
        return false
    end

    if tonumber(worker.hp) ~= nil and tonumber(worker.hp) <= 0 then
        return false
    end

    return true
end

function Internal.CopyPoint(point)
    if type(point) ~= "table" then
        return nil
    end

    return {
        x = math.floor(tonumber(point.x) or 0),
        y = math.floor(tonumber(point.y) or 0),
        z = math.floor(tonumber(point.z) or 0)
    }
end

function Internal.HasPoint(point)
    return type(point) == "table"
        and tonumber(point.x) ~= nil
        and tonumber(point.y) ~= nil
end

function Internal.GetPointDistanceSquared(a, b)
    if not Internal.HasPoint(a) or not Internal.HasPoint(b) then
        return nil
    end

    local dx = (tonumber(a.x) or 0) - (tonumber(b.x) or 0)
    local dy = (tonumber(a.y) or 0) - (tonumber(b.y) or 0)
    return (dx * dx) + (dy * dy)
end

function Internal.GetResidentRole(worker)
    local config = Internal.GetConfig()
    local normalized = config and config.NormalizeJobType
        and config.NormalizeJobType(worker and worker.jobType)
        or tostring(worker and worker.jobType or "")
    return tostring(normalized ~= "" and normalized or worker and worker.profession or "worker")
end

function Internal.GetRosterData()
    if not DynamicTrading_Roster or not DynamicTrading_Roster.MOD_DATA_KEY or not ModData then
        return nil
    end

    return ModData.get(DynamicTrading_Roster.MOD_DATA_KEY)
end

function Internal.ResolvePlayerFactionID(ownerUsername)
    if not DynamicTrading_Factions or not DynamicTrading_Factions.GetPlayerFaction then
        return nil, nil
    end

    local faction = DynamicTrading_Factions.GetPlayerFaction(ownerUsername)
    if type(faction) == "table" and faction.playerOwned == true then
        return faction.id, faction
    end

    return nil, nil
end

function Internal.FindResidentSoul(worker)
    if type(worker) ~= "table" then
        return nil
    end

    local knownUUID = tostring(worker.residentSoulUUID or "")
    if knownUUID ~= "" and DynamicTrading_Roster and DynamicTrading_Roster.GetSoul then
        local knownSoul = DynamicTrading_Roster.GetSoul(knownUUID)
        if knownSoul then
            return knownUUID, knownSoul
        end
    end

    local companionUUID = Internal.GetCompanionUUID(worker)
    if companionUUID and DynamicTrading_Roster and DynamicTrading_Roster.GetSoul then
        local companionSoul = DynamicTrading_Roster.GetSoul(companionUUID)
        if companionSoul then
            worker.residentSoulUUID = companionUUID
            return companionUUID, companionSoul
        end
    end

    local rosterData = Internal.GetRosterData()
    local souls = rosterData and rosterData.Souls or nil
    if type(souls) ~= "table" or not DynamicTrading_Roster or not DynamicTrading_Roster.GetSoul then
        return nil
    end

    local owner = tostring(worker.ownerUsername or "")
    local colonyId = tostring(worker.colonyID or "")
    local workerID = tostring(worker.workerID or "")

    for uuid, soul in pairs(souls) do
        if type(soul) == "table"
            and tostring(soul.ownerUsername or soul.dcResidentOwnerUsername or "") == owner
            and tostring(soul.dcResidentColonyId or "") == colonyId
            and tostring(soul.dcResidentWorkerID or soul.linkedWorkerID or "") == workerID then
            local liveSoul = DynamicTrading_Roster.GetSoul(uuid)
            if liveSoul then
                worker.residentSoulUUID = uuid
                return uuid, liveSoul
            end
        end
    end

    return nil
end

return Bridge

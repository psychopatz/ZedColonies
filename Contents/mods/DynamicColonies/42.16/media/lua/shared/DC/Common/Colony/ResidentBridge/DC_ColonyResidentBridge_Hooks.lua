DC_Colony = DC_Colony or {}
DC_Colony.ResidentBridge = DC_Colony.ResidentBridge or {}

local Bridge = DC_Colony.ResidentBridge
local Internal = Bridge.Internal or {}

function Bridge.OnWorkerStateApplied(worker)
    local changed = false
    if not Internal.IsAuthority() or type(worker) ~= "table" then
        return changed
    end

    changed = Bridge.SyncWorker(worker) == true or false
    if changed then
        local registry = Internal.GetRegistry()
        local persistedWorker = registry and registry.GetWorkerRaw and registry.GetWorkerRaw(worker.workerID) or nil
        if registry and registry.Save and persistedWorker == worker then
            registry.Save()
        end
    end

    return changed
end

function Bridge.RefreshOwnerWorkers(ownerUsername)
    if not Internal.IsAuthority() then
        return false
    end

    local registry = Internal.GetRegistry()
    if not registry or not registry.GetWorkersForOwnerRaw then
        return false
    end

    local changed = false
    for _, worker in ipairs(registry.GetWorkersForOwnerRaw(ownerUsername) or {}) do
        if worker then
            if registry.RecalculateWorker then
                registry.RecalculateWorker(worker)
            end
            changed = Bridge.SyncWorker(worker) == true or changed
        end
    end

    if changed and registry.Save then
        registry.Save()
    end
    if changed and DTNPCManager and DTNPCManager.CheckRosterSpawns then
        DTNPCManager.CheckRosterSpawns()
    end

    return changed
end

function Bridge.ShouldKeepHomeResidentBody(worker)
    if not Internal.IsAuthority() or type(worker) ~= "table" then
        return false
    end

    local uuid = tostring(worker.residentSoulUUID or Internal.GetCompanionUUID(worker) or "")
    if uuid == "" then
        return false
    end

    local homeCoords = {
        x = worker.homeX,
        y = worker.homeY,
        z = worker.homeZ or 0
    }
    if not Internal.HasPoint(homeCoords) then
        return false
    end

    if DTNPC_ColonyResidents and DTNPC_ColonyResidents.IsLiveResidentAtHome then
        return DTNPC_ColonyResidents.IsLiveResidentAtHome(uuid, homeCoords, 8) == true
    end

    return false
end

return Bridge

DC_Buildings = DC_Buildings or {}
DC_Buildings.Internal = DC_Buildings.Internal or {}

local Buildings = DC_Buildings
local Housing = Buildings.Internal.Housing or {}

Buildings.Internal.Housing = Housing

function Housing.GetRegistry()
    return DC_Colony and DC_Colony.Registry or nil
end

function Housing.GetWarehouse()
    return DC_Colony and DC_Colony.Warehouse or nil
end

function Housing.IsLivingWorker(worker)
    local deadState = DC_Colony
        and DC_Colony.Config
        and DC_Colony.Config.States
        and DC_Colony.Config.States.Dead
        or "Dead"
    return worker and tostring(worker.state or "") ~= tostring(deadState)
end

function Housing.GetLivingWorkers(ownerUsername)
    local registry = Housing.GetRegistry()
    local workers = registry and registry.GetWorkersForOwnerRaw and registry.GetWorkersForOwnerRaw(ownerUsername)
        or registry and registry.GetWorkersForOwner and registry.GetWorkersForOwner(ownerUsername)
        or {}
    local living = {}
    for _, worker in ipairs(workers or {}) do
        if Housing.IsLivingWorker(worker) then
            living[#living + 1] = worker
        end
    end

    table.sort(living, function(a, b)
        return tostring(a.workerID or "") < tostring(b.workerID or "")
    end)
    return living
end

function Housing.GetBarracksInstances(ownerUsername)
    local instances = {}
    for _, instance in ipairs(Buildings.GetBuildingsForOwner(ownerUsername)) do
        if tostring(instance.buildingType or "") == "Barracks" and tonumber(instance.level) and tonumber(instance.level) > 0 then
            instances[#instances + 1] = instance
        end
    end

    table.sort(instances, function(a, b)
        if tonumber(a.level) == tonumber(b.level) then
            return tostring(a.buildingID or "") < tostring(b.buildingID or "")
        end
        return tonumber(a.level) > tonumber(b.level)
    end)
    return instances
end

function Housing.GetInfirmaryInstances(ownerUsername)
    local instances = {}
    for _, instance in ipairs(Buildings.GetBuildingsForOwner(ownerUsername)) do
        if tostring(instance.buildingType or "") == "Infirmary" and tonumber(instance.level) and tonumber(instance.level) > 0 then
            instances[#instances + 1] = instance
        end
    end

    table.sort(instances, function(a, b)
        if tonumber(a.level) == tonumber(b.level) then
            return tostring(a.buildingID or "") < tostring(b.buildingID or "")
        end
        return tonumber(a.level) > tonumber(b.level)
    end)
    return instances
end

return Buildings
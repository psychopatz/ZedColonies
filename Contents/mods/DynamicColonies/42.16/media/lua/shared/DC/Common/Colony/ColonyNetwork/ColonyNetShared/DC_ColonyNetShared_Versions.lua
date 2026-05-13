DC_Colony = DC_Colony or {}
DC_Colony.Network = DC_Colony.Network or {}

local Network = DC_Colony.Network
local Internal = Network.Internal or {}
local Shared = Internal.ColonyNetShared or {}
local Registry = Shared.Registry or {}

function Shared.buildVersionToken(value, seen)
    local valueType = type(value)
    if valueType ~= "table" then
        return tostring(valueType) .. ":" .. tostring(value)
    end

    seen = seen or {}
    if seen[value] then
        return "<cycle>"
    end
    seen[value] = true

    local keys = {}
    for key, _ in pairs(value) do
        keys[#keys + 1] = key
    end
    table.sort(keys, function(a, b)
        return tostring(a) < tostring(b)
    end)

    local parts = { "{" }
    for _, key in ipairs(keys) do
        parts[#parts + 1] = tostring(key)
        parts[#parts + 1] = "="
        parts[#parts + 1] = Shared.buildVersionToken(value[key], seen)
        parts[#parts + 1] = ";"
    end
    parts[#parts + 1] = "}"
    seen[value] = nil
    return table.concat(parts)
end

function Shared.getWorkerListVersion(ownerUsername)
    local workersData = Registry.GetWorkersData and Registry.GetWorkersData(ownerUsername, false) or nil
    if workersData and workersData.version then
        return "workers:" .. tostring(workersData.version)
    end

    local colonyData = Registry.GetColonyData and Registry.GetColonyData(ownerUsername, false) or nil
    local versions = colonyData and colonyData.versions or nil
    return "workers:" .. tostring(versions and versions.workers or 1)
end

function Shared.getWorkerLedgerCount(worker, key)
    local ledger = worker and worker[key] or nil
    return type(ledger) == "table" and #ledger or 0
end

function Shared.buildWorkerDetailVersion(worker, workerID, includeWorkerLedgers)
    if not worker then
        return table.concat({
            "worker",
            tostring(workerID or "missing"),
            "missing",
            includeWorkerLedgers == true and "full" or "summary"
        }, ":")
    end

    local parts = {
        "worker",
        tostring(worker.workerID or workerID or ""),
        tostring(math.max(1, math.floor(tonumber(worker.detailVersion) or 1))),
        tostring(worker.state or ""),
        tostring(worker.presenceState or ""),
        tostring(worker.jobType or ""),
        tostring(worker.jobEnabled == true),
        tostring(worker.assignedSiteID or ""),
        tostring(worker.travelHoursRemaining or 0),
        tostring(worker.workProgress or 0),
        tostring(worker.moneyStored or 0),
        tostring(worker.toolState or ""),
    }

    if includeWorkerLedgers == true then
        parts[#parts + 1] = "full"
        parts[#parts + 1] = tostring(Shared.getWorkerLedgerCount(worker, "nutritionLedger"))
        parts[#parts + 1] = tostring(Shared.getWorkerLedgerCount(worker, "toolLedger"))
        parts[#parts + 1] = tostring(Shared.getWorkerLedgerCount(worker, "haulLedger"))
        parts[#parts + 1] = tostring(Shared.getWorkerLedgerCount(worker, "outputLedger"))
    else
        parts[#parts + 1] = "summary"
    end

    return table.concat(parts, ":")
end

function Shared.buildWarehouseVersion(warehouse, ownerUsername, includeLedgers)
    if not warehouse then
        return table.concat({
            "warehouse",
            tostring(ownerUsername or "missing"),
            "missing",
            includeLedgers == true and "full" or "summary"
        }, ":")
    end

    local base = {
        "warehouse",
        tostring(warehouse.ownerUsername or ownerUsername or ""),
        tostring(math.max(1, math.floor(tonumber(warehouse.version) or 1))),
    }

    if includeLedgers == true then
        base[#base + 1] = tostring(math.max(1, math.floor(tonumber(warehouse.itemsVersion) or 1)))
        base[#base + 1] = "full"
    else
        base[#base + 1] = "summary"
    end

    return table.concat(base, ":")
end

return Shared
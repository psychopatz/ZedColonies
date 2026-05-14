DC_Colony = DC_Colony or {}
DC_Colony.Network = DC_Colony.Network or {}

local Network = DC_Colony.Network
local Internal = Network.Internal or {}
local Shared = Internal.ColonyNetShared or {}
local Registry = Shared.Registry or {}

function Shared.normalizeWorkerLedgerMask(includeWorkerLedgers, workerLedgerMask)
    local source = type(workerLedgerMask) == "table" and workerLedgerMask
        or (type(includeWorkerLedgers) == "table" and includeWorkerLedgers or nil)

    if source then
        local normalized = {}
        if source.nutrition == true then
            normalized.nutrition = true
        end
        if source.tool == true then
            normalized.tool = true
        end
        if source.haul == true then
            normalized.haul = true
        end
        if source.output == true then
            normalized.output = true
        end
        for _key, _value in pairs(normalized) do
            return normalized
        end
    end

    if includeWorkerLedgers == true then
        return {
            nutrition = true,
            tool = true,
            haul = true,
            output = true,
        }
    end

    return nil
end

function Shared.normalizeWarehouseLedgerMask(includeWarehouseLedgers, warehouseLedgerMask)
    local source = type(warehouseLedgerMask) == "table" and warehouseLedgerMask
        or (type(includeWarehouseLedgers) == "table" and includeWarehouseLedgers or nil)

    if source then
        local normalized = {}
        if source.provisions == true then
            normalized.provisions = true
        end
        if source.equipment == true then
            normalized.equipment = true
        end
        if source.output == true then
            normalized.output = true
        end
        for _key, _value in pairs(normalized) do
            return normalized
        end
    end

    if includeWarehouseLedgers == true then
        return {
            provisions = true,
            equipment = true,
            output = true,
        }
    end

    return nil
end

local function buildLedgerMaskSignature(normalizedMask, orderedKeys)
    if type(normalizedMask) ~= "table" then
        return "summary"
    end

    local parts = {}
    for _, key in ipairs(orderedKeys or {}) do
        if normalizedMask[key] == true then
            parts[#parts + 1] = key
        end
    end

    if #parts <= 0 then
        return "summary"
    end

    return table.concat(parts, "+")
end

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

function Shared.buildWorkerDetailVersion(worker, workerID, includeWorkerLedgers, workerLedgerMask, warehouseLedgerMask)
    local normalizedWorkerMask = Shared.normalizeWorkerLedgerMask(includeWorkerLedgers, workerLedgerMask)
    local normalizedWarehouseMask = Shared.normalizeWarehouseLedgerMask(false, warehouseLedgerMask)
    if not worker then
        return table.concat({
            "worker",
            tostring(workerID or "missing"),
            "missing",
            buildLedgerMaskSignature(normalizedWorkerMask, { "nutrition", "tool", "haul", "output" }),
            buildLedgerMaskSignature(normalizedWarehouseMask, { "provisions", "equipment", "output" })
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

    parts[#parts + 1] = buildLedgerMaskSignature(normalizedWorkerMask, { "nutrition", "tool", "haul", "output" })
    if normalizedWorkerMask and normalizedWorkerMask.nutrition == true then
        parts[#parts + 1] = tostring(Shared.getWorkerLedgerCount(worker, "nutritionLedger"))
    end
    if normalizedWorkerMask and normalizedWorkerMask.tool == true then
        parts[#parts + 1] = tostring(Shared.getWorkerLedgerCount(worker, "toolLedger"))
    end
    if normalizedWorkerMask and normalizedWorkerMask.haul == true then
        parts[#parts + 1] = tostring(Shared.getWorkerLedgerCount(worker, "haulLedger"))
    end
    if normalizedWorkerMask and normalizedWorkerMask.output == true then
        parts[#parts + 1] = tostring(Shared.getWorkerLedgerCount(worker, "outputLedger"))
    end

    parts[#parts + 1] = buildLedgerMaskSignature(normalizedWarehouseMask, { "provisions", "equipment", "output" })
    if type(worker.warehouse) == "table" and type(worker.warehouse.ledgers) == "table" then
        if normalizedWarehouseMask and normalizedWarehouseMask.provisions == true then
            parts[#parts + 1] = tostring(#(worker.warehouse.ledgers.provisions or {}))
        end
        if normalizedWarehouseMask and normalizedWarehouseMask.equipment == true then
            parts[#parts + 1] = tostring(#(worker.warehouse.ledgers.equipment or {}))
        end
        if normalizedWarehouseMask and normalizedWarehouseMask.output == true then
            parts[#parts + 1] = tostring(#(worker.warehouse.ledgers.output or {}))
        end
    end

    return table.concat(parts, ":")
end

function Shared.buildWarehouseVersion(warehouse, ownerUsername, includeLedgers, ledgerMask)
    local normalizedMask = Shared.normalizeWarehouseLedgerMask(includeLedgers, ledgerMask)
    if not warehouse then
        return table.concat({
            "warehouse",
            tostring(ownerUsername or "missing"),
            "missing",
            buildLedgerMaskSignature(normalizedMask, { "provisions", "equipment", "output" })
        }, ":")
    end

    local base = {
        "warehouse",
        tostring(warehouse.ownerUsername or ownerUsername or ""),
        tostring(math.max(1, math.floor(tonumber(warehouse.version) or 1))),
    }

    base[#base + 1] = buildLedgerMaskSignature(normalizedMask, { "provisions", "equipment", "output" })

    if normalizedMask then
        base[#base + 1] = tostring(math.max(1, math.floor(tonumber(warehouse.itemsVersion) or 1)))
        if type(warehouse.ledgers) == "table" then
            if normalizedMask.provisions == true then
                base[#base + 1] = tostring(#(warehouse.ledgers.provisions or {}))
            end
            if normalizedMask.equipment == true then
                base[#base + 1] = tostring(#(warehouse.ledgers.equipment or {}))
            end
            if normalizedMask.output == true then
                base[#base + 1] = tostring(#(warehouse.ledgers.output or {}))
            end
        end
    end

    return table.concat(base, ":")
end

return Shared

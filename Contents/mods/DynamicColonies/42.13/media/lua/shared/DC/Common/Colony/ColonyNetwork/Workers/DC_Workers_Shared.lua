DC_Colony = DC_Colony or {}
DC_Colony.Network = DC_Colony.Network or {}

local Network = DC_Colony.Network
local Workers = Network.Workers or {}
local Internal = Network.Internal or {}

Workers.Shared = Workers.Shared or {}
Network.Workers = Workers
Network.Internal = Internal
Network.Handlers = Network.Handlers or {}

local Shared = Workers.Shared

local function getRegistry()
    return DC_Colony and DC_Colony.Registry or nil
end

local function getConfig()
    return DC_Colony and DC_Colony.Config or nil
end

local function getSim()
    return DC_Colony and DC_Colony.Sim or nil
end

local function getPresentation()
    return DC_Colony and DC_Colony.Presentation or nil
end

function Shared.normalizeLedgerIndexes(args)
    local indexes = {}
    local seen = {}

    for _, index in ipairs(args and args.ledgerIndexes or {}) do
        local normalized = math.floor(tonumber(index) or 0)
        if normalized > 0 and not seen[normalized] then
            seen[normalized] = true
            indexes[#indexes + 1] = normalized
        end
    end

    if args and args.ledgerIndex then
        local normalized = math.floor(tonumber(args.ledgerIndex) or 0)
        if normalized > 0 and not seen[normalized] then
            indexes[#indexes + 1] = normalized
        end
    end

    table.sort(indexes, function(a, b)
        return a > b
    end)

    return indexes
end

function Shared.getCurrentWorldHours()
    local Config = getConfig()
    if not Config then
        return 0
    end

    return (Config.GetCurrentWorldHours and Config.GetCurrentWorldHours()) or Config.GetCurrentHour()
end

function Shared.saveAndRefreshProcessed(player, worker, syncProjection)
    local Registry = getRegistry()
    local Sim = getSim()
    local Presentation = getPresentation()

    if Registry and Registry.Save then
        Registry.Save()
    end
    if Sim and Sim.ProcessWorker then
        Sim.ProcessWorker(worker, Shared.getCurrentWorldHours())
    end
    if Presentation and Presentation.SyncWorker then
        Presentation.SyncWorker(worker, { player })
    end
    Internal.syncWorkerDetail(player, worker.workerID, nil, true)
    Internal.syncWorkerList(player)
    if syncProjection then
        Internal.syncWarehouse(player, nil, true)
    end
end

function Shared.saveAndRefreshBasic(player, worker, syncProjection)
    local Registry = getRegistry()

    if Registry and Registry.Save then
        Registry.Save()
    end
    Internal.syncWorkerDetail(player, worker.workerID, nil, true)
    Internal.syncWorkerList(player)
    if syncProjection then
        Internal.syncWarehouse(player, nil, true)
    end
end

return Network

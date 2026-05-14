require "DC/UI/Colony/Utils/DC_UIStringUtils"

DC_SupplyWindow = DC_SupplyWindow or {}
DC_SupplyWindow.Internal = DC_SupplyWindow.Internal or {}
DC_Colony = DC_Colony or {}
DC_Colony.UI = DC_Colony.UI or {}

local Internal = DC_SupplyWindow.Internal

local function copyTable(source)
    if type(source) ~= "table" then
        return nil
    end

    local copy = {}
    for key, value in pairs(source) do
        copy[key] = value
    end
    return copy
end

local function mergeWarehouseDetail(previousWarehouse, incomingWarehouse)
    if type(incomingWarehouse) ~= "table" then
        return copyTable(previousWarehouse) or incomingWarehouse
    end

    local merged = copyTable(previousWarehouse) or {}
    for key, value in pairs(incomingWarehouse) do
        merged[key] = value
    end

    if incomingWarehouse.ledgers == nil and type(previousWarehouse) == "table" and type(previousWarehouse.ledgers) == "table" then
        merged.ledgers = copyTable(previousWarehouse.ledgers)
    elseif type(incomingWarehouse.ledgers) == "table" then
        local previousLedgers = type(previousWarehouse) == "table" and type(previousWarehouse.ledgers) == "table" and previousWarehouse.ledgers or {}
        merged.ledgers = {
            provisions = type(incomingWarehouse.ledgers.provisions) == "table"
                and incomingWarehouse.ledgers.provisions
                or previousLedgers.provisions,
            equipment = type(incomingWarehouse.ledgers.equipment) == "table"
                and incomingWarehouse.ledgers.equipment
                or previousLedgers.equipment,
            output = type(incomingWarehouse.ledgers.output) == "table"
                and incomingWarehouse.ledgers.output
                or previousLedgers.output,
        }
    end

    return merged
end

local function onServerCommand(module, command, args)
    if module ~= Internal.getCommandModule() then
        return
    end
    if not DC_SupplyWindow.instance or not DC_SupplyWindow.instance:getIsVisible() then
        return
    end
    if command == "SyncWorkerDetails" then
        if args and args.unchanged == true then
            if args.includeWorkerLedgers == true or type(args and args.workerLedgerMask) == "table" or type(args and args.warehouseLedgerMask) == "table" then
                DC_SupplyWindow.instance.workerDetailVersionsByKey = DC_SupplyWindow.instance.workerDetailVersionsByKey or {}
                DC_SupplyWindow.instance.workerDetailVersionsByKey[Internal.getWorkerSyncVersionKey and Internal.getWorkerSyncVersionKey(args and args.workerLedgerMask, args and args.warehouseLedgerMask) or "worker|summary|summary"] = args and args.version or nil
            else
                DC_SupplyWindow.instance.workerSummaryVersion = args and args.version or DC_SupplyWindow.instance.workerSummaryVersion
            end
            if DC_SupplyWindow.instance.autoRefreshPending then
                DC_SupplyWindow.instance.autoRefreshPending = nil
            end
            return
        end
        local worker = args and args.worker or nil
        if worker and worker.workerID == DC_SupplyWindow.instance.workerID then
            local cache = DC_MainWindow and DC_MainWindow.cachedDetails or nil
            local includeWorkerLedgers = args and (args.includeWorkerLedgers == true or type(args.workerLedgerMask) == "table" or type(args.warehouseLedgerMask) == "table")
            if DC_MainWindow then
                DC_MainWindow.cachedDetailVersions = DC_MainWindow.cachedDetailVersions or {}
                if not includeWorkerLedgers then
                    DC_MainWindow.cachedDetailVersions[worker.workerID] = args and args.version or nil
                end
            end
            local cachedWorker = cache and cache[worker.workerID] or nil
            local currentWorker = DC_SupplyWindow.instance.workerData
            local mergeWorkerDetail = DC_MainWindow and DC_MainWindow.MergeWorkerDetail or nil
            local mergedWorker = worker

            if mergeWorkerDetail then
                mergedWorker = mergeWorkerDetail(cachedWorker or currentWorker, worker)
            end

            if cache then
                cache[worker.workerID] = mergedWorker
            end

            if includeWorkerLedgers then
                DC_SupplyWindow.instance.workerDetailVersionsByKey = DC_SupplyWindow.instance.workerDetailVersionsByKey or {}
                DC_SupplyWindow.instance.workerDetailVersionsByKey[Internal.getWorkerSyncVersionKey and Internal.getWorkerSyncVersionKey(args and args.workerLedgerMask, args and args.warehouseLedgerMask) or "worker|summary|summary"] = args and args.version or nil
            else
                DC_SupplyWindow.instance.workerSummaryVersion = args and args.version or nil
            end
            DC_SupplyWindow.instance:setWorkerData(mergedWorker)
            if DC_SupplyWindow.instance.refreshPlayerMoneyCache then
                DC_SupplyWindow.instance:refreshPlayerMoneyCache(true)
            end
            if DC_SupplyWindow.instance.autoRefreshPending then
                DC_SupplyWindow.instance.autoRefreshPending = nil
            else
                DC_SupplyWindow.instance:updateStatus("Supply reserves refreshed for " .. tostring(worker.name or worker.workerID) .. ".")
            end
        elseif args and args.workerID and args.workerID == DC_SupplyWindow.instance.workerID then
            DC_SupplyWindow.instance:updateStatus("This worker record was removed.")
            DC_SupplyWindow.instance:close()
        end
    elseif command == "SyncWarehouse" then
        if args and args.unchanged == true then
            if args.includeLedgers == true or type(args and args.ledgerMask) == "table" then
                DC_SupplyWindow.instance.warehouseVersionsByKey = DC_SupplyWindow.instance.warehouseVersionsByKey or {}
                DC_SupplyWindow.instance.warehouseVersionsByKey[Internal.getWarehouseSyncVersionKey and Internal.getWarehouseSyncVersionKey(args and args.ledgerMask) or "warehouse|summary"] = args and args.version or nil
            else
                DC_SupplyWindow.instance.warehouseSummaryVersion = args and args.version or DC_SupplyWindow.instance.warehouseSummaryVersion
            end
            if DC_SupplyWindow.instance.autoRefreshPending then
                DC_SupplyWindow.instance.autoRefreshPending = nil
            end
            return
        end
        local currentWorker = DC_SupplyWindow.instance.workerData or {}
        currentWorker.warehouse = mergeWarehouseDetail(currentWorker.warehouse, args and args.warehouse or nil)
        if args and (args.includeLedgers == true or type(args.ledgerMask) == "table") then
            DC_SupplyWindow.instance.warehouseVersionsByKey = DC_SupplyWindow.instance.warehouseVersionsByKey or {}
            DC_SupplyWindow.instance.warehouseVersionsByKey[Internal.getWarehouseSyncVersionKey and Internal.getWarehouseSyncVersionKey(args and args.ledgerMask) or "warehouse|summary"] = args and args.version or nil
        else
            DC_SupplyWindow.instance.warehouseSummaryVersion = args and args.version or nil
        end
        DC_SupplyWindow.instance:setWorkerData(currentWorker)
        if DC_SupplyWindow.instance.refreshPlayerMoneyCache then
            DC_SupplyWindow.instance:refreshPlayerMoneyCache(true)
        end
        if not DC_SupplyWindow.instance.autoRefreshPending then
            DC_SupplyWindow.instance:updateStatus("Warehouse reserves refreshed.")
        end
    elseif command == "ColonyNotice" then
        if args and args.message then
            DC_SupplyWindow.instance:updateStatus(args.message)
        end
        if args and args.popup == true and DC_Colony.UI and DC_Colony.UI.ShowNoticeModal then
            DC_Colony.UI.ShowNoticeModal(args.message)
        end
    elseif command == "SupplyTransferResult" then
        if DC_SupplyWindow.instance.onSupplyTransferResult then
            DC_SupplyWindow.instance:onSupplyTransferResult(args)
        end
    end
end

if not DC_SupplyWindow.EventsAdded then
    Events.OnServerCommand.Add(onServerCommand)
    DC_SupplyWindow.EventsAdded = true
end

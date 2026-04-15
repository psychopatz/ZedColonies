require "DC/UI/Colony/Utils/DC_UIStringUtils"

DC_SupplyWindow = DC_SupplyWindow or {}
DC_SupplyWindow.Internal = DC_SupplyWindow.Internal or {}
DC_Colony = DC_Colony or {}
DC_Colony.UI = DC_Colony.UI or {}

local Internal = DC_SupplyWindow.Internal

local function onServerCommand(module, command, args)
    if module ~= Internal.getCommandModule() then
        return
    end
    if not DC_SupplyWindow.instance or not DC_SupplyWindow.instance:getIsVisible() then
        return
    end
    if command == "SyncWorkerDetails" then
        if args and args.unchanged == true then
            if DC_SupplyWindow.instance.autoRefreshPending then
                DC_SupplyWindow.instance.autoRefreshPending = nil
            end
            return
        end
        local worker = args and args.worker or nil
        if worker and worker.workerID == DC_SupplyWindow.instance.workerID then
            local cache = DC_MainWindow and DC_MainWindow.cachedDetails or nil
            if DC_MainWindow then
                DC_MainWindow.cachedDetailVersions = DC_MainWindow.cachedDetailVersions or {}
                DC_MainWindow.cachedDetailVersions[worker.workerID] = args and args.version or nil
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

            DC_SupplyWindow.instance:setWorkerData(mergedWorker)
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
            if DC_SupplyWindow.instance.autoRefreshPending then
                DC_SupplyWindow.instance.autoRefreshPending = nil
            end
            return
        end
        local currentWorker = DC_SupplyWindow.instance.workerData or {}
        currentWorker.warehouse = args and args.warehouse or nil
        DC_SupplyWindow.instance.warehouseVersion = args and args.version or nil
        DC_SupplyWindow.instance:setWorkerData(currentWorker)
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

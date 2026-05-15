DC_SupplyWindow = DC_SupplyWindow or {}
DC_SupplyWindow.Internal = DC_SupplyWindow.Internal or {}

local Internal = DC_SupplyWindow.Internal

function Internal.handleCompanionSync(window, args)
    local startedAt = Internal.getPerfNowMs and Internal.getPerfNowMs() or nil
    if args and args.unchanged == true then
        if args.includeWorkerLedgers == true or type(args and args.workerLedgerMask) == "table" or type(args and args.warehouseLedgerMask) == "table" then
            window.workerDetailVersionsByKey = window.workerDetailVersionsByKey or {}
            window.workerDetailVersionsByKey[Internal.getWorkerSyncVersionKey and Internal.getWorkerSyncVersionKey(args and args.workerLedgerMask, args and args.warehouseLedgerMask) or "worker|summary|summary"] = args and args.version or nil
        else
            window.workerSummaryVersion = args and args.version or window.workerSummaryVersion
        end
        if window.autoRefreshPending then
            window.autoRefreshPending = nil
        end
        if Internal.debugPerf then
            Internal.debugPerf("CompanionSync", startedAt, 1, {
                token = window.debugOpenToken,
                unchanged = true,
                version = args and args.version or "nil",
            })
        end
        return true
    end

    local worker = args and args.worker or nil
    if worker and worker.workerID == window.workerID then
        local cache = DC_MainWindow and DC_MainWindow.cachedDetails or nil
        local includeWorkerLedgers = args and (args.includeWorkerLedgers == true or type(args.workerLedgerMask) == "table" or type(args.warehouseLedgerMask) == "table")
        if DC_MainWindow then
            DC_MainWindow.cachedDetailVersions = DC_MainWindow.cachedDetailVersions or {}
            if not includeWorkerLedgers then
                DC_MainWindow.cachedDetailVersions[worker.workerID] = args and args.version or nil
            end
        end
        local cachedWorker = cache and cache[worker.workerID] or nil
        local currentWorker = window.workerData
        local mergeWorkerDetail = DC_MainWindow and DC_MainWindow.MergeWorkerDetail or nil
        local mergedWorker = worker

        if mergeWorkerDetail then
            mergedWorker = mergeWorkerDetail(cachedWorker or currentWorker, worker)
        end

        if cache then
            cache[worker.workerID] = mergedWorker
        end

        if includeWorkerLedgers then
            window.workerDetailVersionsByKey = window.workerDetailVersionsByKey or {}
            window.workerDetailVersionsByKey[Internal.getWorkerSyncVersionKey and Internal.getWorkerSyncVersionKey(args and args.workerLedgerMask, args and args.warehouseLedgerMask) or "worker|summary|summary"] = args and args.version or nil
        else
            window.workerSummaryVersion = args and args.version or nil
        end
        window:setWorkerData(mergedWorker)
        if window.refreshPlayerMoneyCache then
            window:refreshPlayerMoneyCache(true)
        end
        if window.autoRefreshPending then
            window.autoRefreshPending = nil
        else
            window:updateStatus("Supply reserves refreshed for " .. tostring(worker.name or worker.workerID) .. ".")
        end
        if Internal.debugPerf then
            Internal.debugPerf("CompanionSync", startedAt, 5, {
                token = window.debugOpenToken,
                unchanged = false,
                version = args and args.version or "nil",
                workerID = worker.workerID,
                includeLedgers = includeWorkerLedgers == true,
            })
        end
    elseif args and args.workerID and args.workerID == window.workerID then
        window:updateStatus("This worker record was removed.")
        window:close()
    end
    return true
end


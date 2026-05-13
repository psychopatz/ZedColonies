DC_MainWindow = DC_MainWindow or {}
DC_MainWindow.Internal = DC_MainWindow.Internal or {}
DC_Colony = DC_Colony or {}
DC_Colony.UI = DC_Colony.UI or {}

local EventSync = DC_MainWindow.Internal.Events or {}
local FlavorText = DC_Colony.UI.MainWindowEventsFlavorText or {}

local function updateVisibleMainWindowStatus(message)
    if DC_MainWindow.instance and DC_MainWindow.instance:getIsVisible() then
        DC_MainWindow.instance:updateStatus(message)
    end
end

local function updateVisibleMainWindowStatusIfUnmuted(message)
    if DC_MainWindow.instance and DC_MainWindow.instance:getIsVisible() then
        if (tonumber(DC_MainWindow.instance.syncStatusMutedFrames) or 0) <= 0 then
            DC_MainWindow.instance:updateStatus(message)
        end
    end
end

function EventSync.onServerCommand(module, command, args)
    local expectedModule = ((DC_Colony and DC_Colony.Config and DC_Colony.Config.COMMAND_MODULE) or "DColony")
    local isFactionCommand = command == "SyncOwnedFactionStatus" or command == "OwnedFactionActionResult"
    if module ~= expectedModule
        and not (isFactionCommand and DC_System and DC_System.Internal and DC_System.Internal.GetFactionCommandModule
            and module == DC_System.Internal.GetFactionCommandModule()) then
        return
    end

    if command == "SyncPlayerWorkers" then
        if args and args.unchanged == true then
            return
        end
        DC_MainWindow.cachedWorkers = EventSync.hydrateWorkerSummariesFromDetails(args and args.workers or {})
        DC_MainWindow.cachedWorkersVersion = args and args.version or nil
        if DC_MainWindow.instance and DC_MainWindow.instance:getIsVisible() then
            DC_MainWindow.instance:populateWorkerList(DC_MainWindow.cachedWorkers)
            updateVisibleMainWindowStatusIfUnmuted(tostring(FlavorText.workerListSynced or "Worker list synced."))
        end
    elseif command == "SyncWorkerDetails" then
        if args and args.unchanged == true then
            return
        end
        if args and args.worker and args.worker.workerID then
            DC_MainWindow.cachedDetails = DC_MainWindow.cachedDetails or {}
            DC_MainWindow.cachedDetailVersions = DC_MainWindow.cachedDetailVersions or {}
            local workerID = args.worker.workerID
            local mergedWorker = EventSync.mergeWorkerDetail(DC_MainWindow.cachedDetails[workerID], args.worker)
            DC_MainWindow.cachedDetails[workerID] = mergedWorker
            DC_MainWindow.cachedDetailVersions[workerID] = args.version or nil
            EventSync.syncCachedWorkerSummaryFromDetails(workerID)
            if DC_MainWindow.instance
                and DC_MainWindow.instance:getIsVisible()
                and DC_MainWindow.instance.selectedWorkerSummary
                and DC_MainWindow.instance.selectedWorkerSummary.workerID == workerID then
                DC_MainWindow.instance:populateWorkerList(DC_MainWindow.cachedWorkers or {})
                DC_MainWindow.instance:updateWorkerDetail(mergedWorker)
                updateVisibleMainWindowStatusIfUnmuted(tostring(FlavorText.workerDetailsSynced or "Worker details synced."))
            end
            if DC_ColonyCharacterWindow
                and DC_ColonyCharacterWindow.instance
                and DC_ColonyCharacterWindow.instance:getIsVisible()
                and DC_ColonyCharacterWindow.instance.workerID == workerID then
                DC_ColonyCharacterWindow.instance:setWorkerData(mergedWorker)
            end
        elseif args and args.workerID then
            DC_MainWindow.cachedDetails = DC_MainWindow.cachedDetails or {}
            DC_MainWindow.cachedDetailVersions = DC_MainWindow.cachedDetailVersions or {}
            DC_MainWindow.cachedDetails[args.workerID] = nil
            DC_MainWindow.cachedDetailVersions[args.workerID] = nil
            if DC_MainWindow.instance
                and DC_MainWindow.instance:getIsVisible()
                and DC_MainWindow.instance.selectedWorkerSummary
                and DC_MainWindow.instance.selectedWorkerSummary.workerID == args.workerID then
                DC_MainWindow.instance.selectedWorkerSummary = nil
                DC_MainWindow.instance.selectedWorker = nil
                DC_MainWindow.instance:updateWorkerDetail(nil)
            end
            if DC_ColonyCharacterWindow
                and DC_ColonyCharacterWindow.instance
                and DC_ColonyCharacterWindow.instance.workerID == args.workerID then
                DC_ColonyCharacterWindow.instance:setWorkerData(nil)
                DC_ColonyCharacterWindow.instance:close()
            end
        end
    elseif command == "SyncWarehouse" then
        if args and args.unchanged == true then
            return
        end

        local selectedWorkerID = DC_MainWindow.instance and DC_MainWindow.instance.selectedWorkerSummary and DC_MainWindow.instance.selectedWorkerSummary.workerID or nil
        if selectedWorkerID and DC_MainWindow.cachedDetails and DC_MainWindow.cachedDetails[selectedWorkerID] then
            local mergedWorker = EventSync.mergeWorkerDetail(DC_MainWindow.cachedDetails[selectedWorkerID], {
                workerID = selectedWorkerID,
                warehouse = args and args.warehouse or nil
            })
            DC_MainWindow.cachedDetails[selectedWorkerID] = mergedWorker
            if DC_MainWindow.instance and DC_MainWindow.instance:getIsVisible() and DC_MainWindow.instance.selectedWorkerSummary and DC_MainWindow.instance.selectedWorkerSummary.workerID == selectedWorkerID then
                DC_MainWindow.instance:updateWorkerDetail(mergedWorker)
            end
        end
    elseif command == "ColonyNotice" then
        updateVisibleMainWindowStatus(tostring(args and args.message or FlavorText.colonyUpdateReceived or "Colony update received."))
        if args and args.popup == true and DC_Colony.UI and DC_Colony.UI.ShowNoticeModal then
            local supplyWindow = DC_SupplyWindow and DC_SupplyWindow.instance or nil
            local supplyVisible = supplyWindow and supplyWindow.getIsVisible and supplyWindow:getIsVisible()
            if not supplyVisible then
                DC_Colony.UI.ShowNoticeModal(args.message)
            end
        end
    elseif command == "SyncOwnedFactionStatus" then
        DC_MainWindow.cachedOwnedFactionStatus = args and args.status or nil
        if DC_System then
            DC_System.ownedFactionStatusCache = DC_MainWindow.cachedOwnedFactionStatus
        end
        if DC_MainWindow.instance and DC_MainWindow.instance.updateFactionButton then
            DC_MainWindow.instance:updateFactionButton()
        end
    elseif command == "ColonyBootstrap" then
        local versions = args and args.versions or {}
        if args and args.workers then
            DC_MainWindow.cachedWorkers = EventSync.hydrateWorkerSummariesFromDetails(args.workers)
        end
        if args and args.warehouse then
            DC_MainWindow.cachedWarehouseSummary = args.warehouse
        end
        if args and args.resourcesSummary then
            DC_MainWindow.cachedResourcesSummary = args.resourcesSummary
        end
        if args and args.factionStatus then
            DC_MainWindow.cachedOwnedFactionStatus = args.factionStatus
            if DC_System then
                DC_System.ownedFactionStatusCache = args.factionStatus
            end
        end
        DC_MainWindow.cachedWorkersVersion = versions.workerList or DC_MainWindow.cachedWorkersVersion
        DC_MainWindow.cachedWarehouseSummaryVersion = versions.warehouseSummary or DC_MainWindow.cachedWarehouseSummaryVersion
        DC_MainWindow.cachedResourcesSummaryVersion = versions.resources or DC_MainWindow.cachedResourcesSummaryVersion
        DC_MainWindow.cachedFactionStatusVersion = versions.factionStatus or DC_MainWindow.cachedFactionStatusVersion
        if args and args.buildingsSnapshot and DC_BuildingsWindow then
            DC_BuildingsWindow.cachedSnapshot = args.buildingsSnapshot
            DC_BuildingsWindow.cachedVersion = versions.building or args.version or DC_BuildingsWindow.cachedVersion
            if DC_BuildingsWindow.instance and DC_BuildingsWindow.instance.getIsVisible and DC_BuildingsWindow.instance:getIsVisible() then
                DC_BuildingsWindow.instance:refreshFromSnapshot()
            end
        end
        if DC_MainWindow.instance and DC_MainWindow.instance:getIsVisible() then
            DC_MainWindow.instance:populateWorkerList(DC_MainWindow.cachedWorkers or {})
            if DC_MainWindow.instance.updateFactionButton then
                DC_MainWindow.instance:updateFactionButton()
            end
            updateVisibleMainWindowStatusIfUnmuted(tostring(FlavorText.colonyStateSynced or "Colony state synced."))
        end
    elseif command == "WorkerListUpdated" then
        DC_MainWindow.cachedWorkers = EventSync.hydrateWorkerSummariesFromDetails(args and args.workers or {})
        DC_MainWindow.cachedWorkersVersion = args and args.version or nil
        if DC_MainWindow.instance and DC_MainWindow.instance:getIsVisible() then
            DC_MainWindow.instance:populateWorkerList(DC_MainWindow.cachedWorkers)
            updateVisibleMainWindowStatusIfUnmuted(tostring(FlavorText.workerListUpdated or "Worker list updated."))
        end
    elseif command == "WorkerUpdated" then
        DC_MainWindow.cachedDetails = DC_MainWindow.cachedDetails or {}
        DC_MainWindow.cachedDetailVersions = DC_MainWindow.cachedDetailVersions or {}
        if args and args.listVersion then
            DC_MainWindow.cachedWorkersVersion = args.listVersion
        end
        if args and args.workerSummary then
            EventSync.replaceCachedWorkerSummary(args.workerSummary)
        end
        if args and args.worker and args.worker.workerID then
            local workerID = args.worker.workerID
            DC_MainWindow.cachedDetails[workerID] = EventSync.mergeWorkerDetail(DC_MainWindow.cachedDetails[workerID], args.worker)
            DC_MainWindow.cachedDetailVersions[workerID] = args.version or nil
            EventSync.syncCachedWorkerSummaryFromDetails(workerID)
            if DC_MainWindow.instance and DC_MainWindow.instance:getIsVisible() then
                DC_MainWindow.instance:populateWorkerList(DC_MainWindow.cachedWorkers or {})
                if DC_MainWindow.instance.selectedWorkerSummary and DC_MainWindow.instance.selectedWorkerSummary.workerID == workerID then
                    DC_MainWindow.instance:updateWorkerDetail(DC_MainWindow.cachedDetails[workerID])
                end
            end
            if DC_ColonyCharacterWindow
                and DC_ColonyCharacterWindow.instance
                and DC_ColonyCharacterWindow.instance:getIsVisible()
                and DC_ColonyCharacterWindow.instance.workerID == workerID then
                DC_ColonyCharacterWindow.instance:setWorkerData(DC_MainWindow.cachedDetails[workerID])
            end
        end
    elseif command == "WarehouseSummaryUpdated" then
        DC_MainWindow.cachedWarehouseSummary = args and args.warehouse or nil
        DC_MainWindow.cachedWarehouseSummaryVersion = args and args.version or nil
    elseif command == "ResourcesSummaryUpdated" then
        DC_MainWindow.cachedResourcesSummary = args and args.snapshot or nil
        DC_MainWindow.cachedResourcesSummaryVersion = args and args.version or nil
    elseif command == "FactionStatusSummary" then
        DC_MainWindow.cachedOwnedFactionStatus = args and args.status or nil
        DC_MainWindow.cachedFactionStatusVersion = args and args.version or nil
        if DC_System then
            DC_System.ownedFactionStatusCache = DC_MainWindow.cachedOwnedFactionStatus
        end
        if DC_MainWindow.instance and DC_MainWindow.instance.updateFactionButton then
            DC_MainWindow.instance:updateFactionButton()
        end
    elseif command == "OwnedFactionActionResult" then
        if args and args.success and args.discoverTrader and args.traderID
            and DynamicTrading and DynamicTrading.Manager and DynamicTrading.Manager.DiscoverTrader then
            local player = getSpecificPlayer and getSpecificPlayer(0) or getPlayer and getPlayer() or nil
            if player then
                DynamicTrading.Manager.DiscoverTrader(args.traderID, player)
            end
        end
        updateVisibleMainWindowStatus(tostring(args and args.message or FlavorText.factionUpdateReceived or "Faction update received."))
    end
end

return EventSync
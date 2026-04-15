require "DC/UI/Colony/Utils/DC_UIStringUtils"

DC_MainWindow = DC_MainWindow or {}
DC_MainWindow.Internal = DC_MainWindow.Internal or {}
DC_Colony = DC_Colony or {}
DC_Colony.UI = DC_Colony.UI or {}

local Internal = DC_MainWindow.Internal

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
    end

    return merged
end

local function mergeWorkerDetail(previousWorker, incomingWorker)
    if type(incomingWorker) ~= "table" then
        return incomingWorker
    end

    local merged = copyTable(previousWorker) or {}
    for key, value in pairs(incomingWorker) do
        merged[key] = value
    end

    if incomingWorker.nutritionLedger == nil and type(previousWorker) == "table" then
        merged.nutritionLedger = previousWorker.nutritionLedger
    end
    if incomingWorker.skills == nil and type(previousWorker) == "table" then
        merged.skills = previousWorker.skills
    end
    if incomingWorker.toolLedger == nil and type(previousWorker) == "table" then
        merged.toolLedger = previousWorker.toolLedger
    end
    if incomingWorker.haulLedger == nil and type(previousWorker) == "table" then
        merged.haulLedger = previousWorker.haulLedger
    end
    if incomingWorker.outputLedger == nil and type(previousWorker) == "table" then
        merged.outputLedger = previousWorker.outputLedger
    end

    if incomingWorker.warehouse == nil then
        if type(previousWorker) == "table" and previousWorker.warehouse ~= nil then
            merged.warehouse = copyTable(previousWorker.warehouse) or previousWorker.warehouse
        end
    else
        merged.warehouse = mergeWarehouseDetail(previousWorker and previousWorker.warehouse, incomingWorker.warehouse)
    end

    return merged
end

DC_MainWindow.MergeWorkerDetail = mergeWorkerDetail

local function onServerCommand(module, command, args)
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
        DC_MainWindow.cachedWorkers = args and args.workers or {}
        DC_MainWindow.cachedWorkersVersion = args and args.version or nil
        if DC_MainWindow.instance and DC_MainWindow.instance:getIsVisible() then
            DC_MainWindow.instance:populateWorkerList(DC_MainWindow.cachedWorkers)
            if (tonumber(DC_MainWindow.instance.syncStatusMutedFrames) or 0) <= 0 then
                DC_MainWindow.instance:updateStatus("Worker list synced.")
            end
        end
    elseif command == "SyncWorkerDetails" then
        if args and args.unchanged == true then
            return
        end
        if args and args.worker and args.worker.workerID then
            DC_MainWindow.cachedDetails = DC_MainWindow.cachedDetails or {}
            DC_MainWindow.cachedDetailVersions = DC_MainWindow.cachedDetailVersions or {}
            local workerID = args.worker.workerID
            local mergedWorker = mergeWorkerDetail(DC_MainWindow.cachedDetails[workerID], args.worker)
            DC_MainWindow.cachedDetails[workerID] = mergedWorker
            DC_MainWindow.cachedDetailVersions[workerID] = args.version or nil
            if DC_MainWindow.instance
                and DC_MainWindow.instance:getIsVisible()
                and DC_MainWindow.instance.selectedWorkerSummary
                and DC_MainWindow.instance.selectedWorkerSummary.workerID == workerID then
                DC_MainWindow.instance:updateWorkerDetail(mergedWorker)
                if (tonumber(DC_MainWindow.instance.syncStatusMutedFrames) or 0) <= 0 then
                    DC_MainWindow.instance:updateStatus("Worker details synced.")
                end
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
            local mergedWorker = mergeWorkerDetail(DC_MainWindow.cachedDetails[selectedWorkerID], {
                workerID = selectedWorkerID,
                warehouse = args and args.warehouse or nil
            })
            DC_MainWindow.cachedDetails[selectedWorkerID] = mergedWorker
            if DC_MainWindow.instance and DC_MainWindow.instance:getIsVisible() and DC_MainWindow.instance.selectedWorkerSummary and DC_MainWindow.instance.selectedWorkerSummary.workerID == selectedWorkerID then
                DC_MainWindow.instance:updateWorkerDetail(mergedWorker)
            end
        end
    elseif command == "ColonyNotice" then
        if DC_MainWindow.instance and DC_MainWindow.instance:getIsVisible() then
            DC_MainWindow.instance:updateStatus(args and args.message or "Colony update received.")
        end
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
    elseif command == "OwnedFactionActionResult" then
        if args and args.success and args.discoverTrader and args.traderID
            and DynamicTrading and DynamicTrading.Manager and DynamicTrading.Manager.DiscoverTrader then
            local player = getSpecificPlayer and getSpecificPlayer(0) or getPlayer and getPlayer() or nil
            if player then
                DynamicTrading.Manager.DiscoverTrader(args.traderID, player)
            end
        end
        if DC_MainWindow.instance and DC_MainWindow.instance:getIsVisible() then
            DC_MainWindow.instance:updateStatus(args and args.message or "Faction update received.")
        end
    end
end

if not DC_MainWindow.EventsAdded then
    Events.OnServerCommand.Add(onServerCommand)
    Events.OnReceiveGlobalModData.Add(function(key, data)
        if not DC_MainWindow.instance or not DC_MainWindow.instance:getIsVisible() then
            return
        end

        if key == (Internal.Config.MOD_DATA_INDEX_KEY or Internal.Config.MOD_DATA_KEY or "DColony_Index") then
            DC_MainWindow.instance:populateWorkerList(Internal.resolveWorkerSummaries())
            if (tonumber(DC_MainWindow.instance.syncStatusMutedFrames) or 0) <= 0 then
                DC_MainWindow.instance:updateStatus("Colony data refreshed from ModData.")
            end
        end
    end)
    DC_MainWindow.EventsAdded = true
end

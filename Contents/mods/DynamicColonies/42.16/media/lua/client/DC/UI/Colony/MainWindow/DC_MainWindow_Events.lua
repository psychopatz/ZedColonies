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

local function copyArrayEntries(source)
    if type(source) ~= "table" then
        return nil
    end

    local copy = {}
    for index, value in ipairs(source) do
        if type(value) == "table" then
            copy[index] = copyTable(value)
        else
            copy[index] = value
        end
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
        if type(previousWarehouse.ledgers.provisions) == "table" then
            merged.ledgers.provisions = copyArrayEntries(previousWarehouse.ledgers.provisions)
        end
        if type(previousWarehouse.ledgers.equipment) == "table" then
            merged.ledgers.equipment = copyArrayEntries(previousWarehouse.ledgers.equipment)
        end
        if type(previousWarehouse.ledgers.output) == "table" then
            merged.ledgers.output = copyArrayEntries(previousWarehouse.ledgers.output)
        end
    elseif type(incomingWarehouse.ledgers) == "table" then
        merged.ledgers = {
            provisions = copyArrayEntries(incomingWarehouse.ledgers.provisions) or {},
            equipment = copyArrayEntries(incomingWarehouse.ledgers.equipment) or {},
            output = copyArrayEntries(incomingWarehouse.ledgers.output) or {},
        }
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

    if incomingWorker.moneyStored == nil and type(previousWorker) == "table" then
        merged.moneyStored = previousWorker.moneyStored
    end
    if incomingWorker.ownerUsername == nil and type(previousWorker) == "table" then
        merged.ownerUsername = previousWorker.ownerUsername
    end

    if incomingWorker.nutritionLedger == nil and type(previousWorker) == "table" then
        merged.nutritionLedger = copyArrayEntries(previousWorker.nutritionLedger)
    end
    if incomingWorker.skills == nil and type(previousWorker) == "table" then
        merged.skills = previousWorker.skills
    end
    if incomingWorker.toolLedger == nil and type(previousWorker) == "table" then
        merged.toolLedger = copyArrayEntries(previousWorker.toolLedger)
    end
    if incomingWorker.haulLedger == nil and type(previousWorker) == "table" then
        merged.haulLedger = copyArrayEntries(previousWorker.haulLedger)
    end
    if incomingWorker.outputLedger == nil and type(previousWorker) == "table" then
        merged.outputLedger = copyArrayEntries(previousWorker.outputLedger)
    end
    if type(incomingWorker.nutritionLedger) == "table" then
        merged.nutritionLedger = copyArrayEntries(incomingWorker.nutritionLedger)
    end
    if type(incomingWorker.toolLedger) == "table" then
        merged.toolLedger = copyArrayEntries(incomingWorker.toolLedger)
    end
    if type(incomingWorker.haulLedger) == "table" then
        merged.haulLedger = copyArrayEntries(incomingWorker.haulLedger)
    end
    if type(incomingWorker.outputLedger) == "table" then
        merged.outputLedger = copyArrayEntries(incomingWorker.outputLedger)
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

local function mergeWorkerSummaryWithDetail(summary, detail)
    if type(summary) ~= "table" then
        return summary
    end
    if type(detail) ~= "table" then
        return summary
    end

    local merged = copyTable(summary) or {}
    if detail.skills ~= nil then
        merged.skills = detail.skills
    end
    if detail.skillModelVersion ~= nil then
        merged.skillModelVersion = detail.skillModelVersion
    end
    if detail.primarySkillID ~= nil then
        merged.primarySkillID = detail.primarySkillID
    end
    if detail.jobSkillID ~= nil then
        merged.jobSkillID = detail.jobSkillID
    end
    if detail.jobSkillLabel ~= nil then
        merged.jobSkillLabel = detail.jobSkillLabel
    end
    if detail.jobSkillLevel ~= nil then
        merged.jobSkillLevel = detail.jobSkillLevel
    end
    if detail.jobSkillSpeedMultiplier ~= nil then
        merged.jobSkillSpeedMultiplier = detail.jobSkillSpeedMultiplier
    end
    return merged
end

local function syncCachedWorkerSummaryFromDetails(workerID)
    if not workerID or type(DC_MainWindow.cachedWorkers) ~= "table" then
        return
    end

    local detail = DC_MainWindow.cachedDetails and DC_MainWindow.cachedDetails[workerID] or nil
    if type(detail) ~= "table" then
        return
    end

    for index, worker in ipairs(DC_MainWindow.cachedWorkers) do
        if worker and worker.workerID == workerID then
            DC_MainWindow.cachedWorkers[index] = mergeWorkerSummaryWithDetail(worker, detail)
            return
        end
    end
end

local function hydrateWorkerSummariesFromDetails(workers)
    if type(workers) ~= "table" then
        return workers
    end

    for index, worker in ipairs(workers) do
        local workerID = worker and worker.workerID or nil
        local detail = workerID and DC_MainWindow.cachedDetails and DC_MainWindow.cachedDetails[workerID] or nil
        if type(detail) == "table" then
            workers[index] = mergeWorkerSummaryWithDetail(worker, detail)
        end
    end

    return workers
end

local function replaceCachedWorkerSummary(summary)
    if type(summary) ~= "table" or not summary.workerID then
        return
    end

    summary = mergeWorkerSummaryWithDetail(summary, DC_MainWindow.cachedDetails and DC_MainWindow.cachedDetails[summary.workerID] or nil)
    DC_MainWindow.cachedWorkers = DC_MainWindow.cachedWorkers or {}
    for index, worker in ipairs(DC_MainWindow.cachedWorkers) do
        if worker and worker.workerID == summary.workerID then
            DC_MainWindow.cachedWorkers[index] = summary
            return
        end
    end

    DC_MainWindow.cachedWorkers[#DC_MainWindow.cachedWorkers + 1] = summary
end

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
        DC_MainWindow.cachedWorkers = hydrateWorkerSummariesFromDetails(args and args.workers or {})
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
            syncCachedWorkerSummaryFromDetails(workerID)
            if DC_MainWindow.instance
                and DC_MainWindow.instance:getIsVisible()
                and DC_MainWindow.instance.selectedWorkerSummary
                and DC_MainWindow.instance.selectedWorkerSummary.workerID == workerID then
                DC_MainWindow.instance:populateWorkerList(DC_MainWindow.cachedWorkers or {})
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
    elseif command == "ColonyBootstrap" then
        local versions = args and args.versions or {}
        if args and args.workers then
            DC_MainWindow.cachedWorkers = hydrateWorkerSummariesFromDetails(args.workers)
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
            if (tonumber(DC_MainWindow.instance.syncStatusMutedFrames) or 0) <= 0 then
                DC_MainWindow.instance:updateStatus("Colony state synced.")
            end
        end
    elseif command == "WorkerListUpdated" then
        DC_MainWindow.cachedWorkers = hydrateWorkerSummariesFromDetails(args and args.workers or {})
        DC_MainWindow.cachedWorkersVersion = args and args.version or nil
        if DC_MainWindow.instance and DC_MainWindow.instance:getIsVisible() then
            DC_MainWindow.instance:populateWorkerList(DC_MainWindow.cachedWorkers)
            if (tonumber(DC_MainWindow.instance.syncStatusMutedFrames) or 0) <= 0 then
                DC_MainWindow.instance:updateStatus("Worker list updated.")
            end
        end
    elseif command == "WorkerUpdated" then
        DC_MainWindow.cachedDetails = DC_MainWindow.cachedDetails or {}
        DC_MainWindow.cachedDetailVersions = DC_MainWindow.cachedDetailVersions or {}
        if args and args.listVersion then
            DC_MainWindow.cachedWorkersVersion = args.listVersion
        end
        if args and args.workerSummary then
            replaceCachedWorkerSummary(args.workerSummary)
        end
        if args and args.worker and args.worker.workerID then
            local workerID = args.worker.workerID
            DC_MainWindow.cachedDetails[workerID] = mergeWorkerDetail(DC_MainWindow.cachedDetails[workerID], args.worker)
            DC_MainWindow.cachedDetailVersions[workerID] = args.version or nil
            syncCachedWorkerSummaryFromDetails(workerID)
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

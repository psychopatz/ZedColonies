require "ISUI/ISModalDialog"

DT_MainWindow = DT_MainWindow or {}
DT_MainWindow.Internal = DT_MainWindow.Internal or {}
DT_Labour = DT_Labour or {}
DT_Labour.UI = DT_Labour.UI or {}

local Internal = DT_MainWindow.Internal

if not DT_Labour.UI.ShowNoticeModal then
    function DT_Labour.UI.ShowNoticeModal(message)
        local text = tostring(message or "")
        if text == "" then
            return
        end

        if DT_Labour.UI.activeNoticeText == text then
            return
        end

        DT_Labour.UI.activeNoticeText = text

        local function onClose()
            DT_Labour.UI.activeNoticeText = nil
        end

        local modal = ISModalDialog:new(0, 0, 420, 180, text, true, nil, onClose, nil)
        modal:initialise()
        modal:addToUIManager()
        modal:setX((getCore():getScreenWidth() - modal:getWidth()) / 2)
        modal:setY((getCore():getScreenHeight() - modal:getHeight()) / 2)
        modal:bringToTop()
    end
end

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

DT_MainWindow.MergeWorkerDetail = mergeWorkerDetail

local function onServerCommand(module, command, args)
    if module ~= "DynamicTrading_V2" then
        return
    end

    if command == "SyncPlayerWorkers" then
        DT_MainWindow.cachedWorkers = args and args.workers or {}
        if DT_MainWindow.instance and DT_MainWindow.instance:getIsVisible() then
            DT_MainWindow.instance:populateWorkerList(DT_MainWindow.cachedWorkers)
            if (tonumber(DT_MainWindow.instance.syncStatusMutedFrames) or 0) <= 0 then
                DT_MainWindow.instance:updateStatus("Worker list synced.")
            end
        end
    elseif command == "SyncWorkerDetails" then
        if args and args.worker and args.worker.workerID then
            DT_MainWindow.cachedDetails = DT_MainWindow.cachedDetails or {}
            local workerID = args.worker.workerID
            local mergedWorker = mergeWorkerDetail(DT_MainWindow.cachedDetails[workerID], args.worker)
            DT_MainWindow.cachedDetails[workerID] = mergedWorker
            if DT_MainWindow.instance
                and DT_MainWindow.instance:getIsVisible()
                and DT_MainWindow.instance.selectedWorkerSummary
                and DT_MainWindow.instance.selectedWorkerSummary.workerID == workerID then
                DT_MainWindow.instance:updateWorkerDetail(mergedWorker)
                if (tonumber(DT_MainWindow.instance.syncStatusMutedFrames) or 0) <= 0 then
                    DT_MainWindow.instance:updateStatus("Worker details synced.")
                end
            end
            if DT_LabourCharacterWindow
                and DT_LabourCharacterWindow.instance
                and DT_LabourCharacterWindow.instance:getIsVisible()
                and DT_LabourCharacterWindow.instance.workerID == workerID then
                DT_LabourCharacterWindow.instance:setWorkerData(mergedWorker)
            end
        elseif args and args.workerID then
            DT_MainWindow.cachedDetails = DT_MainWindow.cachedDetails or {}
            DT_MainWindow.cachedDetails[args.workerID] = nil
            if DT_MainWindow.instance
                and DT_MainWindow.instance:getIsVisible()
                and DT_MainWindow.instance.selectedWorkerSummary
                and DT_MainWindow.instance.selectedWorkerSummary.workerID == args.workerID then
                DT_MainWindow.instance.selectedWorkerSummary = nil
                DT_MainWindow.instance.selectedWorker = nil
                DT_MainWindow.instance:updateWorkerDetail(nil)
            end
            if DT_LabourCharacterWindow
                and DT_LabourCharacterWindow.instance
                and DT_LabourCharacterWindow.instance.workerID == args.workerID then
                DT_LabourCharacterWindow.instance:setWorkerData(nil)
                DT_LabourCharacterWindow.instance:close()
            end
        end
    elseif command == "LabourNotice" then
        if DT_MainWindow.instance and DT_MainWindow.instance:getIsVisible() then
            DT_MainWindow.instance:updateStatus(args and args.message or "Labour update received.")
        end
        if args and args.popup == true and DT_Labour.UI and DT_Labour.UI.ShowNoticeModal then
            local supplyWindow = DT_SupplyWindow and DT_SupplyWindow.instance or nil
            local supplyVisible = supplyWindow and supplyWindow.getIsVisible and supplyWindow:getIsVisible()
            if not supplyVisible then
                DT_Labour.UI.ShowNoticeModal(args.message)
            end
        end
    elseif command == "SyncOwnedFactionStatus" then
        DT_MainWindow.cachedOwnedFactionStatus = args and args.status or nil
        if DT_System then
            DT_System.ownedFactionStatusCache = DT_MainWindow.cachedOwnedFactionStatus
        end
        if DT_MainWindow.instance and DT_MainWindow.instance.updateFactionButton then
            DT_MainWindow.instance:updateFactionButton()
        end
    elseif command == "OwnedFactionActionResult" then
        if args and args.success and args.discoverTrader and args.traderID
            and DynamicTrading and DynamicTrading.Manager and DynamicTrading.Manager.DiscoverTrader then
            local player = getSpecificPlayer and getSpecificPlayer(0) or getPlayer and getPlayer() or nil
            if player then
                DynamicTrading.Manager.DiscoverTrader(args.traderID, player)
            end
        end
        if DT_MainWindow.instance and DT_MainWindow.instance:getIsVisible() then
            DT_MainWindow.instance:updateStatus(args and args.message or "Faction update received.")
        end
    end
end

if not DT_MainWindow.EventsAdded then
    Events.OnServerCommand.Add(onServerCommand)
    Events.OnReceiveGlobalModData.Add(function(key, data)
        if not DT_MainWindow.instance or not DT_MainWindow.instance:getIsVisible() then
            return
        end

        if key == (Internal.Config.MOD_DATA_KEY or "DynamicTrading_Labour") then
            DT_MainWindow.instance:populateWorkerList(Internal.resolveWorkerSummaries())
            if (tonumber(DT_MainWindow.instance.syncStatusMutedFrames) or 0) <= 0 then
                DT_MainWindow.instance:updateStatus("Labour data refreshed from ModData.")
            end
        end
    end)
    DT_MainWindow.EventsAdded = true
end

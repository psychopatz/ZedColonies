DC_SupplyWindow = DC_SupplyWindow or {}
DC_SupplyWindow.Internal = DC_SupplyWindow.Internal or {}

local function closeVisibleWindow(window)
    if window and window.getIsVisible and window:getIsVisible() and window.close then
        window:close()
    end
end

local function closeConflictingWindows()
    closeVisibleWindow(DT_RadioScannerWindow and DT_RadioScannerWindow.instance or nil)
    closeVisibleWindow(DT_FactionInfoWindow and DT_FactionInfoWindow.instance or nil)
    closeVisibleWindow(DC_FactionInfoWindow and DC_FactionInfoWindow.instance or nil)
end

local function copyWarehouseSummary(warehouse)
    if type(warehouse) ~= "table" then
        return nil
    end

    local summary = {}
    for key, value in pairs(warehouse) do
        if key ~= "ledgers" then
            summary[key] = value
        end
    end
    return summary
end

local function copyArrayEntries(source)
    if type(source) ~= "table" then
        return nil
    end

    local copy = {}
    for index, value in ipairs(source) do
        if type(value) == "table" then
            local itemCopy = {}
            for key, entryValue in pairs(value) do
                itemCopy[key] = entryValue
            end
            copy[index] = itemCopy
        else
            copy[index] = value
        end
    end
    return copy
end

local function buildWorkerShell(worker)
    if type(worker) ~= "table" then
        return worker
    end

    local shell = {}
    for key, value in pairs(worker) do
        if key == "warehouse" then
            shell.warehouse = copyWarehouseSummary(value)
        elseif key ~= "nutritionLedger"
            and key ~= "toolLedger"
            and key ~= "haulLedger"
            and key ~= "outputLedger"
            and key ~= "skills"
            and key ~= "jobSkillEffects" then
            shell[key] = value
        end
    end
    return shell
end

local function mergeWorkerData(previousWorker, incomingWorker)
    if type(incomingWorker) ~= "table" then
        return previousWorker or incomingWorker
    end

    local merged = {}
    if type(previousWorker) == "table" then
        for key, value in pairs(previousWorker) do
            merged[key] = value
        end
    end
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
    elseif type(incomingWorker.nutritionLedger) == "table" then
        merged.nutritionLedger = copyArrayEntries(incomingWorker.nutritionLedger)
    end
    if incomingWorker.toolLedger == nil and type(previousWorker) == "table" then
        merged.toolLedger = copyArrayEntries(previousWorker.toolLedger)
    elseif type(incomingWorker.toolLedger) == "table" then
        merged.toolLedger = copyArrayEntries(incomingWorker.toolLedger)
    end
    if incomingWorker.haulLedger == nil and type(previousWorker) == "table" then
        merged.haulLedger = copyArrayEntries(previousWorker.haulLedger)
    elseif type(incomingWorker.haulLedger) == "table" then
        merged.haulLedger = copyArrayEntries(incomingWorker.haulLedger)
    end
    if incomingWorker.outputLedger == nil and type(previousWorker) == "table" then
        merged.outputLedger = copyArrayEntries(previousWorker.outputLedger)
    elseif type(incomingWorker.outputLedger) == "table" then
        merged.outputLedger = copyArrayEntries(incomingWorker.outputLedger)
    end
    if incomingWorker.warehouse == nil and type(previousWorker) == "table" and type(previousWorker.warehouse) == "table" then
        local warehouseCopy = copyWarehouseSummary(previousWorker.warehouse) or {}
        if type(previousWorker.warehouse.ledgers) == "table" then
            warehouseCopy.ledgers = {
                provisions = copyArrayEntries(previousWorker.warehouse.ledgers.provisions) or {},
                equipment = copyArrayEntries(previousWorker.warehouse.ledgers.equipment) or {},
                output = copyArrayEntries(previousWorker.warehouse.ledgers.output) or {},
            }
        end
        merged.warehouse = warehouseCopy
    elseif type(incomingWorker.warehouse) == "table" then
        local warehouseCopy = copyWarehouseSummary(incomingWorker.warehouse) or {}
        local previousLedgers = type(previousWorker) == "table"
            and type(previousWorker.warehouse) == "table"
            and type(previousWorker.warehouse.ledgers) == "table"
            and previousWorker.warehouse.ledgers
            or {}
        if type(incomingWorker.warehouse.ledgers) == "table" then
            warehouseCopy.ledgers = {
                provisions = type(incomingWorker.warehouse.ledgers.provisions) == "table"
                    and copyArrayEntries(incomingWorker.warehouse.ledgers.provisions)
                    or copyArrayEntries(previousLedgers.provisions)
                    or {},
                equipment = type(incomingWorker.warehouse.ledgers.equipment) == "table"
                    and copyArrayEntries(incomingWorker.warehouse.ledgers.equipment)
                    or copyArrayEntries(previousLedgers.equipment)
                    or {},
                output = type(incomingWorker.warehouse.ledgers.output) == "table"
                    and copyArrayEntries(incomingWorker.warehouse.ledgers.output)
                    or copyArrayEntries(previousLedgers.output)
                    or {},
            }
        elseif type(previousLedgers) == "table" then
            warehouseCopy.ledgers = {
                provisions = copyArrayEntries(previousLedgers.provisions) or {},
                equipment = copyArrayEntries(previousLedgers.equipment) or {},
                output = copyArrayEntries(previousLedgers.output) or {},
            }
        end
        merged.warehouse = warehouseCopy
    end
    return merged
end

function DC_SupplyWindow.Preload()
    local window = DC_SupplyWindow.instance
    if window then
        return window
    end

    local width = 980
    local height = 620
    local x = (getCore():getScreenWidth() - width) / 2
    local y = (getCore():getScreenHeight() - height) / 2

    window = DC_SupplyWindow:new(x, y, width, height)
    window:initialise()
    window:instantiate()
    window:setVisible(false)
    DC_SupplyWindow.instance = window
    return window
end

function DC_SupplyWindow.Open(worker, viewMode, options)
    if not worker or not worker.workerID then
        return
    end

    closeConflictingWindows()

    local window = DC_SupplyWindow.Preload()
    options = type(options) == "table" and options or {}

    window.workerID = worker.workerID
    window.workerName = worker.name or worker.workerID
    window.viewMode = viewMode or (DC_SupplyWindow.Internal.ViewModes and DC_SupplyWindow.Internal.ViewModes.Inventory) or "inventory"
    window.openContext = options
    window.isCompanionOpen = options.companionOpen == true
    window.requireCanonicalWorkerDetail = options.requireCanonicalWorkerDetail == true
    window.forceRefresh = options.forceRefresh == true
    window.activeTab = DC_SupplyWindow.Internal and DC_SupplyWindow.Internal.Tabs and DC_SupplyWindow.Internal.Tabs.Provisions or "provisions"
    window.selectedPlayerEntry = nil
    window.selectedWorkerEntry = nil
    window.playerExpandedGroups = {}
    window.workerExpandedGroups = {}
    local subjectName = tostring(window.workerName)
    if window.viewMode == ((DC_SupplyWindow.Internal.ViewModes or {}).Warehouse)
        and DC_SupplyWindow.Internal
        and DC_SupplyWindow.Internal.getWarehouseDisplayName then
        subjectName = DC_SupplyWindow.Internal.getWarehouseDisplayName(window)
    end
    window.title = (window.viewMode == ((DC_SupplyWindow.Internal.ViewModes or {}).Warehouse) and "Warehouse - " or "NPC Inventory - ")
        .. subjectName
    window.workerData = nil
    window.detailRefreshTicks = 0
    window.autoRefreshPending = nil
    window.workerSummaryVersion = nil
    window.workerDetailVersion = nil
    window.workerDetailVersionsByKey = {}
    window.warehouseSummaryVersion = nil
    window.warehouseVersion = nil
    window.warehouseVersionsByKey = {}
    window.initialSummarySyncPending = true
    window.deferredEquipmentPreloadPending = true
    window.deferredEquipmentPreloadTicks = 0
    local cachedWorker = DC_SupplyWindow.Internal
        and DC_SupplyWindow.Internal.resolveWorkerDetail
        and DC_SupplyWindow.Internal.resolveWorkerDetail(worker.workerID)
        or (DC_MainWindow and DC_MainWindow.cachedDetails and DC_MainWindow.cachedDetails[worker.workerID] or nil)
    window:setVisible(true)
    window:addToUIManager()
    window:bringToTop()
    window:setWorkerData(mergeWorkerData(cachedWorker, buildWorkerShell(worker)))
    window:startInventoryScan()
    window:updateStatus(
        window.isCompanionOpen == true
            and ("Loading companion inventory for " .. subjectName .. "...")
            or ((window.viewMode == ((DC_SupplyWindow.Internal.ViewModes or {}).Warehouse) and "Opening warehouse for " or "Opening inventory for ")
                .. subjectName .. "...")
    )
end

function DC_SupplyWindow:close()
    self:setVisible(false)
    self:removeFromUIManager()
end

function DC_SupplyWindow:new(x, y, width, height)
    local o = ISCollapsableWindow:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.title = "Colony Supplies"
    o.resizable = true
    o.playerEntries = {}
    o.playerEntriesByID = {}
    o.playerEntrySets = {}
    o.playerEntryMaps = {}
    o.playerDataReady = {}
    o.scannedInventoryItems = {}
    o.scanTargetTabKey = nil
    o.playerHydrationState = nil
    o.playerFinalizeState = nil
    o.workerEntries = {}
    o.activeTab = DC_SupplyWindow.Internal and DC_SupplyWindow.Internal.Tabs and DC_SupplyWindow.Internal.Tabs.Provisions or "provisions"
    o.selectedPlayerEntry = nil
    o.selectedWorkerEntry = nil
    o.activeSelectionSide = "player"
    o.workerID = nil
    o.workerName = nil
    o.viewMode = DC_SupplyWindow.Internal and DC_SupplyWindow.Internal.ViewModes and DC_SupplyWindow.Internal.ViewModes.Inventory or "inventory"
    o.detailRefreshTicks = 0
    o.lastPlayerFilter = ""
    o.lastWorkerFilter = ""
    o.playerExpandedGroups = {}
    o.workerExpandedGroups = {}
    o.playerVisibleEntries = {}
    o.workerVisibleEntries = {}
    o.pendingPlayerListRows = nil
    o.pendingPlayerListNextIndex = nil
    o.pendingPlayerListSelectedKey = nil
    o.pendingPlayerListSelectedRowIndex = nil
    o.pendingWorkerListRows = nil
    o.pendingWorkerListNextIndex = nil
    o.pendingWorkerListSelectedKey = nil
    o.pendingWorkerListSelectedRowIndex = nil
    o.pendingSupplyTransfers = {}
    o.supplyTransferSequence = 0
    o.presentationCacheVersion = 0
    return o
end

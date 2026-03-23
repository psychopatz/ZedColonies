DT_SupplyWindow = DT_SupplyWindow or {}
DT_SupplyWindow.Internal = DT_SupplyWindow.Internal or {}

function DT_SupplyWindow.Open(worker, viewMode)
    if not worker or not worker.workerID then
        return
    end

    local window = DT_SupplyWindow.instance
    if not window then
        local width = 980
        local height = 620
        local x = (getCore():getScreenWidth() - width) / 2
        local y = (getCore():getScreenHeight() - height) / 2

        window = DT_SupplyWindow:new(x, y, width, height)
        window:initialise()
        window:instantiate()
        DT_SupplyWindow.instance = window
    end

    window.workerID = worker.workerID
    window.workerName = worker.name or worker.workerID
    window.viewMode = viewMode or (DT_SupplyWindow.Internal.ViewModes and DT_SupplyWindow.Internal.ViewModes.Inventory) or "inventory"
    window.activeTab = DT_SupplyWindow.Internal and DT_SupplyWindow.Internal.Tabs and DT_SupplyWindow.Internal.Tabs.Provisions or "provisions"
    window.selectedPlayerEntry = nil
    window.selectedWorkerEntry = nil
    local subjectName = tostring(window.workerName)
    if window.viewMode == ((DT_SupplyWindow.Internal.ViewModes or {}).Warehouse)
        and DT_SupplyWindow.Internal
        and DT_SupplyWindow.Internal.getWarehouseDisplayName then
        subjectName = DT_SupplyWindow.Internal.getWarehouseDisplayName(window)
    end
    window.title = (window.viewMode == ((DT_SupplyWindow.Internal.ViewModes or {}).Warehouse) and "Warehouse - " or "NPC Inventory - ")
        .. subjectName
    window:setVisible(true)
    window:addToUIManager()
    window:bringToTop()
    window:setWorkerData(DT_SupplyWindow.Internal.resolveWorkerDetail(worker.workerID) or worker)
    window:startInventoryScan()
    window:requestWorkerDetails()
    window:updateStatus(
        (window.viewMode == ((DT_SupplyWindow.Internal.ViewModes or {}).Warehouse) and "Opening warehouse for " or "Opening inventory for ")
            .. subjectName .. "."
    )
end

function DT_SupplyWindow:close()
    self:setVisible(false)
    self:removeFromUIManager()
end

function DT_SupplyWindow:new(x, y, width, height)
    local o = ISCollapsableWindow:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.title = "Labour Supplies"
    o.resizable = true
    o.playerEntries = {}
    o.playerEntriesByID = {}
    o.workerEntries = {}
    o.activeTab = DT_SupplyWindow.Internal and DT_SupplyWindow.Internal.Tabs and DT_SupplyWindow.Internal.Tabs.Provisions or "provisions"
    o.selectedPlayerEntry = nil
    o.selectedWorkerEntry = nil
    o.activeSelectionSide = "player"
    o.workerID = nil
    o.workerName = nil
    o.viewMode = DT_SupplyWindow.Internal and DT_SupplyWindow.Internal.ViewModes and DT_SupplyWindow.Internal.ViewModes.Inventory or "inventory"
    o.detailRefreshTicks = 0
    o.lastPlayerFilter = ""
    o.lastWorkerFilter = ""
    return o
end

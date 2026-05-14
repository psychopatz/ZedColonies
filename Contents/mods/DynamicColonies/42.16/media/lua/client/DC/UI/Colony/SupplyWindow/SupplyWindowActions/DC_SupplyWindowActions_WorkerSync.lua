DC_SupplyWindow = DC_SupplyWindow or {}
DC_SupplyWindow.Internal = DC_SupplyWindow.Internal or {}

local Internal = DC_SupplyWindow.Internal

local function copyMask(source, orderedKeys)
    if type(source) ~= "table" then
        return nil
    end

    local normalized = {}
    for _, key in ipairs(orderedKeys or {}) do
        if source[key] == true then
            normalized[key] = true
        end
    end

    for _key, _value in pairs(normalized) do
        return normalized
    end

    return nil
end

local function buildMaskSignature(source, orderedKeys)
    if type(source) ~= "table" then
        return "summary"
    end

    local parts = {}
    for _, key in ipairs(orderedKeys or {}) do
        if source[key] == true then
            parts[#parts + 1] = key
        end
    end

    if #parts <= 0 then
        return "summary"
    end

    return table.concat(parts, "+")
end

function Internal.getWorkerLedgerMaskForTab(window, tabID)
    local activeTab = tabID or (window and window.activeTab) or Internal.Tabs.Provisions
    if activeTab == Internal.Tabs.Equipment then
        return { tool = true }
    end
    if activeTab == Internal.Tabs.Output then
        if Internal.isWarehouseView and Internal.isWarehouseView(window) then
            return nil
        end
        return {
            haul = true,
            output = true,
        }
    end
    if Internal.isWarehouseView and Internal.isWarehouseView(window) then
        return nil
    end
    return { nutrition = true }
end

function Internal.getWarehouseLedgerMaskForTab(window, tabID)
    local activeTab = tabID or (window and window.activeTab) or Internal.Tabs.Provisions
    if activeTab == Internal.Tabs.Equipment then
        return { equipment = true }
    end
    if activeTab == Internal.Tabs.Output then
        if Internal.isWarehouseView and Internal.isWarehouseView(window) then
            return { output = true }
        end
        return nil
    end
    if Internal.isWarehouseView and Internal.isWarehouseView(window) then
        return { provisions = true }
    end
    return { provisions = true }
end

function Internal.getWorkerSyncVersionKey(workerLedgerMask, warehouseLedgerMask)
    local workerKey = buildMaskSignature(workerLedgerMask, { "nutrition", "tool", "haul", "output" })
    local warehouseKey = buildMaskSignature(warehouseLedgerMask, { "provisions", "equipment", "output" })
    return table.concat({ "worker", workerKey, warehouseKey }, "|")
end

function Internal.getWarehouseSyncVersionKey(warehouseLedgerMask)
    return table.concat({ "warehouse", buildMaskSignature(warehouseLedgerMask, { "provisions", "equipment", "output" }) }, "|")
end

local function getKnownWorkerVersion(window, includeWorkerLedgers, workerLedgerMask, warehouseLedgerMask, bypassKnownVersion)
    if bypassKnownVersion then
        return nil
    end

    if includeWorkerLedgers == true or type(workerLedgerMask) == "table" or type(warehouseLedgerMask) == "table" then
        local key = Internal.getWorkerSyncVersionKey(workerLedgerMask, warehouseLedgerMask)
        return window.workerDetailVersionsByKey and window.workerDetailVersionsByKey[key] or nil
    end

    return window.workerSummaryVersion
end

local function getKnownWarehouseVersion(window, includeLedgers, warehouseLedgerMask, bypassKnownVersion)
    if bypassKnownVersion then
        return nil
    end

    if includeLedgers == true or type(warehouseLedgerMask) == "table" then
        local key = Internal.getWarehouseSyncVersionKey(warehouseLedgerMask)
        return window.warehouseVersionsByKey and window.warehouseVersionsByKey[key] or nil
    end

    return window.warehouseSummaryVersion
end

local function hasWorkerLedgerMask(worker, workerLedgerMask)
    if type(workerLedgerMask) ~= "table" then
        return true
    end

    if type(worker) ~= "table" then
        return false
    end

    if workerLedgerMask.nutrition == true and type(worker.nutritionLedger) ~= "table" then
        return false
    end
    if workerLedgerMask.tool == true and type(worker.toolLedger) ~= "table" then
        return false
    end
    if workerLedgerMask.haul == true and type(worker.haulLedger) ~= "table" then
        return false
    end
    if workerLedgerMask.output == true and type(worker.outputLedger) ~= "table" then
        return false
    end

    return true
end

local function hasWarehouseLedgerMask(worker, warehouseLedgerMask)
    if type(warehouseLedgerMask) ~= "table" then
        return true
    end

    local warehouse = type(worker) == "table" and worker.warehouse or nil
    local ledgers = type(warehouse) == "table" and warehouse.ledgers or nil
    if type(ledgers) ~= "table" then
        return false
    end
    if warehouseLedgerMask.provisions == true and type(ledgers.provisions) ~= "table" then
        return false
    end
    if warehouseLedgerMask.equipment == true and type(ledgers.equipment) ~= "table" then
        return false
    end
    if warehouseLedgerMask.output == true and type(ledgers.output) ~= "table" then
        return false
    end
    return true
end

function DC_SupplyWindow:getActiveLedgerMasks(tabID)
    return copyMask(Internal.getWorkerLedgerMaskForTab(self, tabID), { "nutrition", "tool", "haul", "output" }),
        copyMask(Internal.getWarehouseLedgerMaskForTab(self, tabID), { "provisions", "equipment", "output" })
end

function DC_SupplyWindow:requestActiveTabDetails(bypassKnownVersions)
    local workerLedgerMask, warehouseLedgerMask = self:getActiveLedgerMasks()
    self:requestWorkerDetails({
        workerLedgerMask = workerLedgerMask,
        warehouseLedgerMask = warehouseLedgerMask,
        bypassWorkerKnownVersion = bypassKnownVersions == true,
        bypassWarehouseKnownVersion = bypassKnownVersions == true,
    })
end

function DC_SupplyWindow:hasActiveTabWorkerDetail(tabID)
    local workerLedgerMask, warehouseLedgerMask = self:getActiveLedgerMasks(tabID)
    if hasWorkerLedgerMask(self.workerData, workerLedgerMask) and hasWarehouseLedgerMask(self.workerData, warehouseLedgerMask) then
        return true
    end

    local resolver = DC_SupplyWindow.Internal and DC_SupplyWindow.Internal.resolveWorkerDetail or nil
    local resolvedWorker = resolver and resolver(self.workerID) or nil
    if resolvedWorker and hasWorkerLedgerMask(resolvedWorker, workerLedgerMask) and hasWarehouseLedgerMask(resolvedWorker, warehouseLedgerMask) then
        if self.workerData ~= resolvedWorker then
            self:setWorkerData(resolvedWorker)
        end
        return true
    end

    return false
end

function DC_SupplyWindow:onRefresh()
    self:startInventoryScan()
    self.autoRefreshPending = true
    self.initialSummarySyncPending = nil
    self:requestWorkerDetails({
        includeWorkerLedgers = false,
        includeWarehouseLedgers = false
    })
    self:requestActiveTabDetails(true)
end

function DC_SupplyWindow:requestWorkerDetails(options)
    if not self.workerID then
        return
    end

    options = options or {}
    local workerLedgerMask = copyMask(options.workerLedgerMask, { "nutrition", "tool", "haul", "output" })
    local warehouseLedgerMask = copyMask(options.warehouseLedgerMask or options.ledgerMask, { "provisions", "equipment", "output" })
    local includeWorkerLedgers = workerLedgerMask ~= nil or options.includeWorkerLedgers == true
    local includeWarehouseLedgers = warehouseLedgerMask ~= nil or options.includeWarehouseLedgers == true

    self:sendColonyCommand("RequestWorkerDetails", {
        workerID = self.workerID,
        knownVersion = getKnownWorkerVersion(self, includeWorkerLedgers, workerLedgerMask, nil, options.bypassWorkerKnownVersion == true),
        includeWorkerLedgers = includeWorkerLedgers,
        includeWarehouseLedgers = false,
        workerLedgerMask = workerLedgerMask,
    })
    self:sendColonyCommand("RequestWarehouse", {
        knownVersion = getKnownWarehouseVersion(self, includeWarehouseLedgers, warehouseLedgerMask, options.bypassWarehouseKnownVersion == true),
        includeLedgers = includeWarehouseLedgers,
        ledgerMask = warehouseLedgerMask
    })
end

function DC_SupplyWindow:hasCanonicalWorkerDetail()
    return self:hasActiveTabWorkerDetail(self.activeTab)
end

function DC_SupplyWindow:isPlayerInventoryReady()
    return self.scanning ~= true
end

function DC_SupplyWindow:ensureCanonicalWorkerDetail(showStatus, bypassKnownVersions)
    if self:hasActiveTabWorkerDetail(self.activeTab) then
        return true
    end

    if self.requestWorkerDetails then
        self:requestActiveTabDetails(bypassKnownVersions == true)
    end

    if showStatus ~= false then
        self:updateStatus("Companion inventory is still loading. Please wait a moment.")
    end
    return false
end

function DC_SupplyWindow:refreshAfterMissingTransfer()
    self:startInventoryScan()
    self:requestWorkerDetails({
        includeWorkerLedgers = false,
        includeWarehouseLedgers = false,
        bypassWorkerKnownVersion = true,
        bypassWarehouseKnownVersion = true,
    })
    self:requestActiveTabDetails(true)
end

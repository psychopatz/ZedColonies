DT_SupplyWindow = DT_SupplyWindow or {}
DT_SupplyWindow.Internal = DT_SupplyWindow.Internal or {}

local Internal = DT_SupplyWindow.Internal

local function canDropCurrentHaul(window)
    if not window or not window.workerID then
        return false
    end

    if Internal.isWarehouseView and Internal.isWarehouseView(window) then
        return false
    end

    if (window.activeTab or Internal.Tabs.Provisions) ~= Internal.Tabs.Output then
        return false
    end

    local config = Internal.Config or {}
    local normalizedJob = config.NormalizeJobType and config.NormalizeJobType(window.workerData and window.workerData.jobType)
        or tostring(window.workerData and window.workerData.jobType or "")
    return normalizedJob == ((config.JobTypes or {}).Scavenge)
end

function DT_SupplyWindow:dropWorkerEntries(entries)
    if not canDropCurrentHaul(self) then
        self:updateStatus("Drop is only available for scavenger haul in NPC inventory.")
        return
    end

    local selectedEntries = {}
    local seenIndexes = {}
    for _, entry in ipairs(entries or {}) do
        local ledgerIndex = math.floor(tonumber(entry and entry.ledgerIndex) or 0)
        if ledgerIndex > 0 and not seenIndexes[ledgerIndex] then
            seenIndexes[ledgerIndex] = true
            selectedEntries[#selectedEntries + 1] = entry
        end
    end

    if #selectedEntries <= 0 then
        self:updateStatus("Select a hauled item to drop first.")
        return
    end

    local payload = {}
    for _, entry in ipairs(selectedEntries) do
        payload[#payload + 1] = entry.ledgerIndex
    end

    if not self:sendLabourCommand("DropWorkerHaulEntries", {
            workerID = self.workerID,
            ledgerIndexes = payload
        }) then
        self:updateStatus("Unable to drop hauled items.")
        return
    end

    if #selectedEntries == 1 then
        self:updateStatus("Dropping " .. tostring(selectedEntries[1].displayName or selectedEntries[1].fullType or "hauled item") .. "...")
    else
        self:updateStatus("Dropping " .. tostring(#selectedEntries) .. " hauled entries...")
    end
end

function DT_SupplyWindow:onDropSelected()
    if not canDropCurrentHaul(self) then
        self:updateStatus("Drop is only available for scavenger haul in NPC inventory.")
        return
    end

    local selectedEntry = self.selectedWorkerEntry
    if not selectedEntry then
        self:updateStatus("Select a hauled item on the worker side first.")
        return
    end

    self:dropWorkerEntries({ selectedEntry })
end

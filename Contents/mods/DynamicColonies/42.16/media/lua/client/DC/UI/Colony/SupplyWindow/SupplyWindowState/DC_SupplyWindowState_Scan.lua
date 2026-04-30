DC_SupplyWindow = DC_SupplyWindow or {}
DC_SupplyWindow.Internal = DC_SupplyWindow.Internal or {}

local Internal = DC_SupplyWindow.Internal

function DC_SupplyWindow:startInventoryScan()
    local player = Internal.getLocalPlayer()
    local rootContainer = player and player.getInventory and player:getInventory() or nil
    local targetTab = self.activeTab or Internal.Tabs.Provisions

    self.playerEntrySets = {}
    self.playerEntryMaps = {}
    self.playerDataReady = {}
    self.playerProvisionGroups = {}
    self.scannedInventoryItems = {}
    self.cachedLooseMoneyCount = 0
    self.cachedMoneyBundleCount = 0
    self.playerVisibleEntries = {}
    self.selectedPlayerEntry = nil
    self.scanStack = {}
    self.scanProcessed = 0
    self.scanning = false
    self.scanTargetTabKey = targetTab
    self.playerHydrationState = nil
    self.playerFinalizeState = nil
    self:bindPlayerEntrySet(targetTab)
    self:clearPlayerListUI()
    self:bumpPresentationCacheVersion()

    if not rootContainer then
        self:refreshDetailSelection()
        self:updateStatus("No player inventory found.")
        return
    end

    self.scanStack[#self.scanStack + 1] = {
        container = rootContainer,
        index = 0
    }
    self.scanning = true
    self:updateStatus("Scanning inventory for labour supplies...")
end

function DC_SupplyWindow:finishInventoryScan()
    self.scanning = false
    local builtCount = #(self.playerEntries or {})
    self:beginPlayerEntryFinalize(
        self.scanTargetTabKey or self.activeTab or Internal.Tabs.Provisions,
        "Loaded "
            .. tostring(builtCount)
            .. " visible entries from "
            .. tostring(self.scanProcessed or 0)
            .. " inventory items."
    )
end

function DC_SupplyWindow:processInventoryScan(batchSize)
    if not self.scanning then
        return
    end

    local visibleProcessed = 0
    local rawSteps = 0
    local startedAt = Internal.getPerfNowMs and Internal.getPerfNowMs() or nil
    while #self.scanStack > 0
        and visibleProcessed < (batchSize or Internal.ENTRY_SCAN_BATCH_SIZE)
        and rawSteps < Internal.RAW_SCAN_STEP_LIMIT do
        local frame = self.scanStack[#self.scanStack]
        local container = frame and frame.container or nil
        local items = container and container.getItems and container:getItems() or nil

        if not items then
            table.remove(self.scanStack)
        elseif frame.index >= items:size() then
            table.remove(self.scanStack)
        else
            local invItem = items:get(frame.index)
            frame.index = frame.index + 1
            rawSteps = rawSteps + 1

            if invItem then
                local addedVisibleEntry = self:addScannedItem(invItem)
                if addedVisibleEntry then
                    visibleProcessed = visibleProcessed + 1
                end
                self.scanProcessed = self.scanProcessed + 1

                if instanceof(invItem, "InventoryContainer") then
                    local subContainer = invItem:getItemContainer()
                    if subContainer then
                        self.scanStack[#self.scanStack + 1] = {
                            container = subContainer,
                            index = 0
                        }
                    end
                end
            end
        end

        if Internal.isTimeBudgetExceeded
            and Internal.isTimeBudgetExceeded(startedAt, Internal.SCAN_TIME_BUDGET_MS) then
            break
        end
    end

    if #self.scanStack <= 0 then
        self:finishInventoryScan()
    elseif self.scanProcessed % 120 == 0 then
        self:updateStatus(
            "Scanning inventory... "
            .. tostring(self.scanProcessed)
            .. " items checked, "
            .. tostring(#(self.playerEntries or {}))
            .. " visible entries."
        )
    end
end

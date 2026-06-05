require "ISUI/ISCollapsableWindow"
require "ISUI/ISRichTextPanel"
require "ISUI/ISButton"
require "ISUI/ISScrollingListBox"

DC_CorpseFacilityModal = ISCollapsableWindow:derive("DC_CorpseFacilityModal")

local function findBuildingPlot(snapshot, buildingID)
    for _, plot in ipairs(snapshot and snapshot.map and snapshot.map.plots or {}) do
        if tostring(plot and plot.building and plot.building.buildingID or "") == tostring(buildingID or "") then
            return plot
        end
    end
    return nil
end

function DC_CorpseFacilityModal:initialise()
    ISCollapsableWindow.initialise(self)
end

function DC_CorpseFacilityModal:createChildren()
    ISCollapsableWindow.createChildren(self)

    self.summaryPanel = ISRichTextPanel:new(8, 24, self.width - 16, 160)
    self.summaryPanel:initialise()
    self.summaryPanel.clip = true
    self.summaryPanel.backgroundColor = { r = 0, g = 0, b = 0, a = 0 }
    self.summaryPanel.borderColor = { r = 0, g = 0, b = 0, a = 0 }
    self.summaryPanel:addScrollBars()
    self:addChild(self.summaryPanel)

    self.entryList = ISScrollingListBox:new(8, 190, self.width - 16, 150)
    self.entryList:initialise()
    self.entryList.itemheight = 22
    self.entryList.doDrawItem = function(list, y, item, alt)
        local a = alt and 0.08 or 0.03
        list:drawRect(0, y, list:getWidth(), list.itemheight - 1, a, 0, 0, 0)
        local color = item.item and item.item.ready == true and { r = 0.82, g = 0.94, b = 0.82, a = 1 } or { r = 0.85, g = 0.85, b = 0.85, a = 1 }
        list:drawText(item.text or "", 8, y + 3, color.r, color.g, color.b, color.a, UIFont.Small)
        return y + list.itemheight
    end
    self:addChild(self.entryList)

    self.btnRoute = ISButton:new(8, self.height - 66, 140, 24, "Route", self, self.onToggleRoute)
    self.btnRoute:initialise()
    self:addChild(self.btnRoute)

    self.btnOverflow = ISButton:new(156, self.height - 66, 164, 24, "Overflow", self, self.onToggleOverflow)
    self.btnOverflow:initialise()
    self:addChild(self.btnOverflow)

    self.btnExhume = ISButton:new(8, self.height - 36, 140, 24, "Exhume Ready", self, self.onExhumeSelected)
    self.btnExhume:initialise()
    self:addChild(self.btnExhume)

    self.btnRefresh = ISButton:new(156, self.height - 36, 80, 24, "Refresh", self, self.onRefreshClicked)
    self.btnRefresh:initialise()
    self:addChild(self.btnRefresh)

    self.btnClose = ISButton:new(self.width - 88, self.height - 36, 80, 24, "Close", self, self.onCloseClicked)
    self.btnClose:initialise()
    self:addChild(self.btnClose)

    self:refreshFromSnapshot()
end

function DC_CorpseFacilityModal:refreshFromSnapshot()
    local snapshot = DC_BuildingsWindow and DC_BuildingsWindow.cachedSnapshot or nil
    local plot = findBuildingPlot(snapshot, self.buildingID)
    self.plot = plot or self.plot
    local building = self.plot and self.plot.building or nil
    local facilitySnapshot = snapshot and snapshot.corpseFacilities or nil
    local settings = facilitySnapshot and facilitySnapshot.settings or {}
    local summary = facilitySnapshot and facilitySnapshot.summary or {}
    local facilityType = tostring(building and building.corpseFacilityType or building and building.buildingType or "Facility")

    local text = " <RGB:1,1,1> <SIZE:Medium> " .. tostring(building and building.displayName or facilityType) .. " <LINE> "
    text = text .. " <RGB:0.72,0.72,0.72> Route Preference: <RGB:1,1,1> " .. tostring(settings.generalRoutePreference or "MassGrave") .. " <LINE> "
    text = text .. " <RGB:0.72,0.72,0.72> Teammate Overflow: <RGB:1,1,1> " .. tostring(settings.teammateOverflowPolicy or "Block") .. " <LINE> "
    text = text .. " <RGB:0.72,0.72,0.72> Buried: <RGB:1,1,1> " .. tostring(summary.buried or 0)
        .. " <RGB:0.72,0.72,0.72> | Incinerated: <RGB:1,1,1> " .. tostring(summary.incinerated or 0)
        .. " <RGB:0.72,0.72,0.72> | Exhumed: <RGB:1,1,1> " .. tostring(summary.exhumed or 0)
        .. " <LINE> "
    if facilityType == "Cemetery" or facilityType == "MassGrave" then
        text = text .. " <RGB:0.72,0.72,0.72> Slots: <RGB:1,1,1> "
            .. tostring(building and building.corpseUsedSlots or 0)
            .. " / "
            .. tostring(building and building.corpseSlotCapacity or 0)
            .. " <RGB:0.72,0.72,0.72> | Ready to Exhume: <RGB:1,1,1> "
            .. tostring(building and building.corpseReadyToExhumeCount or 0)
            .. " <LINE> "
    elseif facilityType == "Incinerator" then
        text = text .. " <RGB:0.72,0.72,0.72> Queue: <RGB:1,1,1> "
            .. tostring(building and building.corpseQueueSize or 0)
            .. " <RGB:0.72,0.72,0.72> | Active Batch: <RGB:1,1,1> "
            .. tostring(building and building.corpseIncineratorActiveBatchSize or 0)
            .. " <RGB:0.72,0.72,0.72> | Cooldown: <RGB:1,1,1> "
            .. tostring(math.floor((tonumber(building and building.corpseIncineratorCooldownRemainingHours) or 0) + 0.5))
            .. "h <LINE> "
    end
    self.summaryPanel:setText(text)
    self.summaryPanel:paginate()

    self.entryList:clear()
    for _, entry in ipairs(building and building.corpseEntriesPreview or {}) do
        local status = entry.ready == true and "Ready" or "Waiting"
        self.entryList:addItem(tostring(entry.label or entry.entryID or "Entry") .. " | " .. status, entry)
    end

    self.btnRoute:setTitle("Route: " .. tostring(settings.generalRoutePreference or "MassGrave"))
    self.btnOverflow:setTitle("Overflow: " .. tostring(settings.teammateOverflowPolicy or "Block"))
    self.btnExhume:setEnable(self.entryList.items and #self.entryList.items > 0)
end

function DC_CorpseFacilityModal:sendCommand(command, args)
    if self.ownerWindow and self.ownerWindow.sendColonyCommand then
        self.ownerWindow:sendColonyCommand(command, args or {})
    end
    if self.window and self.window.requestSnapshot then
        self.window:requestSnapshot(false)
    end
end

function DC_CorpseFacilityModal:onToggleRoute()
    local snapshot = DC_BuildingsWindow and DC_BuildingsWindow.cachedSnapshot or nil
    local settings = snapshot and snapshot.corpseFacilities and snapshot.corpseFacilities.settings or {}
    local nextRoute = tostring(settings.generalRoutePreference or "MassGrave") == "MassGrave" and "Incinerator" or "MassGrave"
    self:sendCommand("SetCorpseFacilityRoutePreference", { route = nextRoute })
end

function DC_CorpseFacilityModal:onToggleOverflow()
    local snapshot = DC_BuildingsWindow and DC_BuildingsWindow.cachedSnapshot or nil
    local settings = snapshot and snapshot.corpseFacilities and snapshot.corpseFacilities.settings or {}
    local nextPolicy = tostring(settings.teammateOverflowPolicy or "Block") == "Block" and "AllowOverflow" or "Block"
    self:sendCommand("SetCorpseFacilityOverflowPolicy", { policy = nextPolicy })
end

function DC_CorpseFacilityModal:onExhumeSelected()
    local item = self.entryList.items and self.entryList.items[self.entryList.selected] or nil
    if not (item and item.item and item.item.ready == true) then
        return
    end
    self:sendCommand("ExhumeCorpseFacilityEntry", {
        buildingID = self.buildingID,
        entryID = item.item.entryID or item.item.slotIndex,
    })
end

function DC_CorpseFacilityModal:onRefreshClicked()
    if self.window and self.window.requestSnapshot then
        self.window:requestSnapshot(false)
    end
    self:refreshFromSnapshot()
end

function DC_CorpseFacilityModal:onCloseClicked()
    self:close()
end

function DC_CorpseFacilityModal:update()
    ISCollapsableWindow.update(self)
    self:refreshFromSnapshot()
end

function DC_CorpseFacilityModal.Open(args)
    args = type(args) == "table" and args or {}
    local modal = DC_CorpseFacilityModal:new(
        getCore():getScreenWidth() / 2 - 180,
        getCore():getScreenHeight() / 2 - 190,
        360,
        380
    )
    modal.buildingID = args.buildingID
    modal.ownerWindow = args.ownerWindow
    modal.window = args.window
    modal.plot = args.plot
    modal.title = tostring(args.title or "Corpse Facility")
    modal:initialise()
    modal:addToUIManager()
    return modal
end

function DC_CorpseFacilityModal:new(x, y, width, height)
    local o = ISCollapsableWindow:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.resizable = false
    o.pin = false
    return o
end

return DC_CorpseFacilityModal

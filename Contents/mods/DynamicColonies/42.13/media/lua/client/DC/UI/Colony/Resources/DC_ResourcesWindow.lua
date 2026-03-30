require "ISUI/ISCollapsableWindow"
require "ISUI/ISButton"
require "ISUI/ISRichTextPanel"
require "ISUI/ISScrollingListBox"
require "DC/UI/Colony/Resources/DC_ResourcesClientBridge"

DC_ResourcesWindow = ISCollapsableWindow:derive("DC_ResourcesWindow")
DC_ResourcesWindow.instance = nil
DC_ResourcesWindow.EventsAdded = DC_ResourcesWindow.EventsAdded or false

local Bridge = DC_ResourcesClientBridge

function DC_ResourcesWindow:initialise()
    ISCollapsableWindow.initialise(self)
    self:setResizable(false)
end

function DC_ResourcesWindow:createChildren()
    ISCollapsableWindow.createChildren(self)

    local th = self:titleBarHeight()
    local statusHeight = 32
    local bottomPadding = 10
    local detailHeight = self.height - th - 40 - statusHeight - (bottomPadding * 2)

    self.btnRefresh = ISButton:new(10, th + 8, 90, 24, "Refresh", self, self.onRefreshClicked)
    self.btnRefresh:initialise()
    self:addChild(self.btnRefresh)

    self.categoryList = ISScrollingListBox:new(10, th + 40, 180, self.height - th - 52)
    self.categoryList:initialise()
    self.categoryList:instantiate()
    self.categoryList.itemheight = 32
    self.categoryList.target = self
    self.categoryList.onMouseDown = function(list, x, y)
        local result = ISScrollingListBox.onMouseDown(list, x, y)
        local row = tonumber(list.selected) or -1
        local item = row > 0 and list.items[row] or nil
        if item and item.item then
            list.target.selectedCategoryID = tostring(item.item.id or "Water")
            list.target:refreshView()
        end
        return result
    end
    self:addChild(self.categoryList)

    self.detailText = ISRichTextPanel:new(200, th + 40, self.width - 210, detailHeight)
    self.detailText:initialise()
    self.detailText.backgroundColor = { r = 0, g = 0, b = 0, a = 0.12 }
    self.detailText.borderColor = { r = 1, g = 1, b = 1, a = 0.08 }
    self.detailText.autosetheight = false
    self.detailText.clip = true
    self.detailText:addScrollBars()
    self:addChild(self.detailText)

    self.statusText = ISRichTextPanel:new(200, self.height - statusHeight - bottomPadding, self.width - 210, statusHeight)
    self.statusText:initialise()
    self.statusText.backgroundColor = { r = 0, g = 0, b = 0, a = 0 }
    self.statusText.borderColor = { r = 0, g = 0, b = 0, a = 0 }
    self:addChild(self.statusText)

    self.selectedCategoryID = self.selectedCategoryID or "Water"
    self:updateStatus("Resources ready.")
    self:requestSnapshot()
end

function DC_ResourcesWindow:updateStatus(message)
    if self.statusText then
        self.statusText.text = " <RGB:0.88,0.88,0.88> " .. tostring(message or "") .. " "
        self.statusText:paginate()
    end
end

function DC_ResourcesWindow:getSelectedCategory()
    local categories = self.snapshot and self.snapshot.categories or {}
    for _, category in ipairs(categories) do
        if tostring(category.id or "") == tostring(self.selectedCategoryID or "Water") then
            return category
        end
    end
    return categories[1]
end

function DC_ResourcesWindow:buildWaterDetailText()
    local water = self.snapshot and self.snapshot.water or {}
    local text = ""
    text = text .. " <RGB:1,1,1> <SIZE:Medium> Water Network <LINE> "
    text = text .. " <RGB:0.72,0.72,0.72> Stored: <RGB:1,1,1> "
        .. tostring(math.floor((tonumber(water.stored) or 0) + 0.5))
        .. " / "
        .. tostring(math.floor((tonumber(water.capacity) or 0) + 0.5))
        .. " <LINE> "
    text = text .. " <RGB:0.72,0.72,0.72> Rain State: <RGB:1,1,1> "
        .. ((water.raining and "Raining") or "Dry")
        .. " <LINE> "
    text = text .. " <RGB:0.72,0.72,0.72> Collection: <RGB:1,1,1> "
        .. tostring(string.format("%.2f", tonumber(water.activeCollectionRatePerHour) or 0))
        .. " / hour <LINE> "
    text = text .. " <RGB:0.72,0.72,0.72> Greenhouse Demand: <RGB:1,1,1> "
        .. tostring(math.floor((tonumber(water.dailyDemand) or 0) + 0.5))
        .. " / day <LINE> "
    text = text .. " <RGB:0.72,0.72,0.72> Outdoor Temp: <RGB:1,1,1> "
        .. tostring(string.format("%.1f", tonumber(water.outdoorTemperatureC) or 0))
        .. " C <LINE> "

    text = text .. " <LINE> <RGB:1,1,1> <SIZE:Medium> Collection Buildings <LINE> "
    if #(water.collectors or {}) <= 0 then
        text = text .. " <RGB:0.65,0.65,0.65> No Water Collector has been built yet. <LINE> "
    else
        for _, collector in ipairs(water.collectors or {}) do
            text = text .. " <RGB:0.82,0.82,0.82> - Plot "
                .. tostring(collector.plotX or 0)
                .. ","
                .. tostring(collector.plotY or 0)
                .. ": +"
                .. tostring(collector.storageBonus or 0)
                .. " storage, +"
                .. tostring(collector.collectionRate or 0)
                .. " / hour, "
                .. tostring(collector.barrelInstallCount or 0)
                .. " barrel upgrades <LINE> "
        end
    end

    text = text .. " <LINE> <RGB:1,1,1> <SIZE:Medium> Storage Tanks <LINE> "
    if #(water.tanks or {}) <= 0 then
        text = text .. " <RGB:0.65,0.65,0.65> No Water Tank has been built yet. <LINE> "
    else
        for _, tank in ipairs(water.tanks or {}) do
            text = text .. " <RGB:0.82,0.82,0.82> - Plot "
                .. tostring(tank.plotX or 0)
                .. ","
                .. tostring(tank.plotY or 0)
                .. ": +"
                .. tostring(tank.storageBonus or 0)
                .. " storage <LINE> "
        end
    end

    text = text .. " <LINE> <RGB:1,1,1> <SIZE:Medium> Greenhouses <LINE> "
    if #(water.greenhouses or {}) <= 0 then
        text = text .. " <RGB:0.65,0.65,0.65> No Greenhouse has been built yet. <LINE> "
    else
        for _, greenhouse in ipairs(water.greenhouses or {}) do
            text = text .. " <RGB:0.82,0.82,0.82> - Plot "
                .. tostring(greenhouse.plotX or 0)
                .. ","
                .. tostring(greenhouse.plotY or 0)
                .. ": "
                .. tostring(greenhouse.activeSlotCount or 0)
                .. " / "
                .. tostring(greenhouse.slotCount or 0)
                .. " beds active, thermostat "
                .. tostring(greenhouse.thermostatC or 20)
                .. " C, "
                .. tostring(greenhouse.dailyWaterUse or 0)
                .. " water / day <LINE> "
        end
    end

    text = text .. " <LINE> <RGB:0.82,0.82,0.82> Greenhouse planting and bed management now live in the dedicated Garden modal from the Buildings screen. <LINE> "
    return text
end

function DC_ResourcesWindow:buildPlaceholderDetailText(category)
    local name = tostring(category and category.displayName or "Resource")
    local text = ""
    text = text .. " <RGB:1,1,1> <SIZE:Medium> " .. name .. " <LINE> "
    text = text .. " <RGB:0.78,0.78,0.78> This resource card is a placeholder for the upcoming colony utility systems. <LINE> "
    if name == "Electricity" then
        text = text .. " <RGB:0.72,0.72,0.72> Planned: unique generator building, fuel modules, and colony power distribution. <LINE> "
    elseif name == "Ammo" then
        text = text .. " <RGB:0.72,0.72,0.72> Planned: ranged combat reserves and colony defense logistics. <LINE> "
    elseif name == "Medicine" then
        text = text .. " <RGB:0.72,0.72,0.72> Planned: infirmary stockpiles, treatment reserves, and medical shortages. <LINE> "
    elseif name == "Scrap" then
        text = text .. " <RGB:0.72,0.72,0.72> Planned: salvage inputs for construction, repairs, and future utilities. <LINE> "
    end
    return text
end

function DC_ResourcesWindow:populateCategoryList()
    self.categoryList:clear()
    local selectedIndex = -1
    for index, category in ipairs(self.snapshot and self.snapshot.categories or {}) do
        local label = tostring(category.displayName or category.id or "Resource")
            .. "  |  "
            .. tostring(category.metric or "-")
            .. "  |  "
            .. tostring(category.status or "")
        self.categoryList:addItem(label, category)
        if tostring(category.id or "") == tostring(self.selectedCategoryID or "Water") then
            selectedIndex = index
        end
    end

    if selectedIndex == -1 and #self.categoryList.items > 0 then
        selectedIndex = 1
        local firstItem = self.categoryList.items[selectedIndex]
        self.selectedCategoryID = firstItem and firstItem.item and tostring(firstItem.item.id or "Water") or "Water"
    end

    self.categoryList.selected = selectedIndex
end

function DC_ResourcesWindow:refreshView()
    local category = self:getSelectedCategory()
    if category and tostring(category.id or "") == "Water" then
        self.detailText.text = self:buildWaterDetailText()
    else
        self.detailText.text = self:buildPlaceholderDetailText(category)
    end
    self.detailText:paginate()
end

function DC_ResourcesWindow:applySnapshot(snapshot, version)
    self.snapshot = snapshot or {}
    self.version = version
    if not self.selectedCategoryID then
        self.selectedCategoryID = "Water"
    end
    self:populateCategoryList()
    self:refreshView()
end

function DC_ResourcesWindow:requestSnapshot()
    Bridge.RequestSnapshot(self.version or Bridge.GetCachedVersion())
end

function DC_ResourcesWindow:onRefreshClicked()
    self:updateStatus("Refreshing resources...")
    self:requestSnapshot()
end

function DC_ResourcesWindow.Open(parent)
    if not DC_ResourcesWindow.instance then
        local width = 860
        local height = 620
        local x = (getCore():getScreenWidth() - width) / 2
        local y = (getCore():getScreenHeight() - height) / 2
        local window = DC_ResourcesWindow:new(x, y, width, height)
        window:initialise()
        window:addToUIManager()
        window:setVisible(true)
        window:bringToTop()
        DC_ResourcesWindow.instance = window
    else
        DC_ResourcesWindow.instance:setVisible(true)
        DC_ResourcesWindow.instance:bringToTop()
        DC_ResourcesWindow.instance:requestSnapshot()
    end

    local cachedSnapshot = Bridge.GetCachedSnapshot()
    if cachedSnapshot and DC_ResourcesWindow.instance then
        DC_ResourcesWindow.instance:applySnapshot(cachedSnapshot, Bridge.GetCachedVersion())
    end

    return DC_ResourcesWindow.instance
end

function DC_ResourcesWindow:new(x, y, width, height)
    local o = ISCollapsableWindow:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.title = "Colony Resources"
    o.snapshot = nil
    o.version = nil
    return o
end

if not DC_ResourcesWindow.EventsAdded then
    Bridge.AddListener("resources_window", function(eventName, payload)
        if not (DC_ResourcesWindow.instance and DC_ResourcesWindow.instance.getIsVisible and DC_ResourcesWindow.instance:getIsVisible()) then
            return
        end

        if eventName == "resources_snapshot" then
            DC_ResourcesWindow.instance:applySnapshot(payload and payload.snapshot or nil, payload and payload.version or nil)
            DC_ResourcesWindow.instance:updateStatus("Resources synced.")
        elseif eventName == "colony_notice" then
            DC_ResourcesWindow.instance:updateStatus(payload and payload.message or "Colony update received.")
        end
    end)
    DC_ResourcesWindow.EventsAdded = true
end

return DC_ResourcesWindow

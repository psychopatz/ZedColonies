require "ISUI/ISCollapsableWindow"
require "ISUI/ISButton"
require "ISUI/ISComboBox"
require "ISUI/ISRichTextPanel"
require "ISUI/ISScrollingListBox"
require "ISUI/ISTextEntryBox"
require "DC/UI/Colony/Resources/DC_ResourcesClientBridge"
require "DC/UI/Colony/Greenhouse/DC_GreenhouseUIUtils"

DC_GreenhouseModal = ISCollapsableWindow:derive("DC_GreenhouseModal")
DC_GreenhouseModal.instance = nil

local Bridge = DC_ResourcesClientBridge
local Utils = DC_GreenhouseUIUtils

function DC_GreenhouseModal:initialise()
    ISCollapsableWindow.initialise(self)
    self:setResizable(false)
end

function DC_GreenhouseModal:createChildren()
    ISCollapsableWindow.createChildren(self)

    local th = self:titleBarHeight()

    self.detailText = ISRichTextPanel:new(10, th + 10, self.width - 20, 160)
    self.detailText:initialise()
    self.detailText.backgroundColor = { r = 0, g = 0, b = 0, a = 0.12 }
    self.detailText.borderColor = { r = 1, g = 1, b = 1, a = 0.08 }
    self.detailText.autosetheight = false
    self.detailText.clip = true
    self.detailText:addScrollBars()
    self:addChild(self.detailText)

    self.greenhouseCombo = ISComboBox:new(10, th + 182, 280, 24, self, self.onGreenhouseChanged)
    self.greenhouseCombo:initialise()
    self:addChild(self.greenhouseCombo)

    self.tempEntry = ISTextEntryBox:new("", 300, th + 182, 80, 24)
    self.tempEntry:initialise()
    self:addChild(self.tempEntry)

    self.btnApplyThermostat = ISButton:new(390, th + 182, 110, 24, "Apply Temp", self, self.onApplyThermostatClicked)
    self.btnApplyThermostat:initialise()
    self:addChild(self.btnApplyThermostat)

    self.btnRefresh = ISButton:new(self.width - 110, th + 182, 100, 24, "Refresh", self, self.onRefreshClicked)
    self.btnRefresh:initialise()
    self:addChild(self.btnRefresh)

    self.slotList = ISScrollingListBox:new(10, th + 216, self.width - 20, 210)
    self.slotList:initialise()
    self.slotList:instantiate()
    self.slotList.itemheight = 28
    self.slotList.target = self
    self.slotList.onMouseDown = function(list, x, y)
        local result = ISScrollingListBox.onMouseDown(list, x, y)
        local row = tonumber(list.selected) or -1
        local item = row > 0 and list.items[row] or nil
        if item and item.item then
            list.target.selectedSlotIndex = tonumber(item.item.slotIndex) or nil
            list.target:refreshSelectionState()
        end
        return result
    end
    self:addChild(self.slotList)

    self.seedCombo = ISComboBox:new(10, th + 438, 280, 24, self, self.onSeedSelectionChanged)
    self.seedCombo:initialise()
    self:addChild(self.seedCombo)

    self.btnPlant = ISButton:new(300, th + 438, 110, 24, "Plant Bed", self, self.onPlantClicked)
    self.btnPlant:initialise()
    self:addChild(self.btnPlant)

    self.btnClear = ISButton:new(420, th + 438, 110, 24, "Clear Bed", self, self.onClearClicked)
    self.btnClear:initialise()
    self:addChild(self.btnClear)

    self.btnClose = ISButton:new(self.width - 110, th + 438, 100, 24, "Close", self, self.onCloseClicked)
    self.btnClose:initialise()
    self:addChild(self.btnClose)

    self.statusText = ISRichTextPanel:new(10, th + 472, self.width - 20, 32)
    self.statusText:initialise()
    self.statusText.backgroundColor = { r = 0, g = 0, b = 0, a = 0 }
    self.statusText.borderColor = { r = 0, g = 0, b = 0, a = 0 }
    self:addChild(self.statusText)

    self:updateStatus("Greenhouse controls ready.")
end

function DC_GreenhouseModal:updateStatus(message)
    if self.statusText then
        self.statusText.text = " <RGB:0.88,0.88,0.88> " .. tostring(message or "") .. " "
        self.statusText:paginate()
    end
end

function DC_GreenhouseModal:applyArgs(args)
    args = args or {}
    self.title = tostring(args.title or "Greenhouse")
    self.preferredBuildingID = tostring(args.buildingID or self.preferredBuildingID or "")
end

function DC_GreenhouseModal:getSelectedGreenhouse()
    local data = self.greenhouseCombo and self.greenhouseCombo.options and self.greenhouseCombo.options[self.greenhouseCombo.selected] or nil
    local greenhouse = data and data.data or nil
    self.selectedGreenhouseID = greenhouse and greenhouse.buildingID or nil
    return greenhouse
end

function DC_GreenhouseModal:getSelectedSlot()
    return Utils.FindSlot(self:getSelectedGreenhouse(), self.selectedSlotIndex)
end

function DC_GreenhouseModal:populateGreenhouses()
    self.greenhouseCombo:clear()
    local greenhouses = Utils.GetGreenhouses(self.snapshot)
    local selectedIndex = 0
    local desiredID = tostring(self.preferredBuildingID or self.selectedGreenhouseID or "")

    for index, greenhouse in ipairs(greenhouses) do
        self.greenhouseCombo:addOptionWithData(Utils.BuildGreenhouseOptionLabel(greenhouse), greenhouse)
        if tostring(greenhouse and greenhouse.buildingID or "") == desiredID then
            selectedIndex = index
        end
    end

    if #greenhouses > 0 then
        if selectedIndex <= 0 then
            selectedIndex = 1
        end
        self.greenhouseCombo.selected = selectedIndex
        local selectedGreenhouse = greenhouses[selectedIndex]
        self.selectedGreenhouseID = selectedGreenhouse and selectedGreenhouse.buildingID or nil
        self.preferredBuildingID = self.selectedGreenhouseID
    else
        self.greenhouseCombo.selected = 1
        self.selectedGreenhouseID = nil
        self.preferredBuildingID = nil
    end
end

function DC_GreenhouseModal:populateSlots()
    self.slotList:clear()
    local greenhouse = self:getSelectedGreenhouse()
    local selectedRow = -1

    for index, slot in ipairs(greenhouse and greenhouse.slots or {}) do
        self.slotList:addItem(Utils.BuildSlotLabel(slot), slot)
        if tonumber(slot and slot.slotIndex) == tonumber(self.selectedSlotIndex) then
            selectedRow = index
        end
    end

    if selectedRow == -1 and #self.slotList.items > 0 then
        selectedRow = 1
        local firstItem = self.slotList.items[selectedRow]
        self.selectedSlotIndex = firstItem and firstItem.item and tonumber(firstItem.item.slotIndex) or 1
    end

    self.slotList.selected = selectedRow
end

function DC_GreenhouseModal:populateSeeds()
    self.seedOptions = Utils.CollectSeedOptions()
    self.seedCombo:clear()

    for _, option in ipairs(self.seedOptions or {}) do
        self.seedCombo:addOptionWithData(option.label, option.fullType)
    end

    self.seedCombo.selected = 1
end

function DC_GreenhouseModal:refreshSelectionState()
    local greenhouse = self:getSelectedGreenhouse()
    local slot = self:getSelectedSlot()

    if self.tempEntry then
        self.tempEntry:setText(greenhouse and tostring(greenhouse.thermostatC or 20) or "")
    end
    if self.btnApplyThermostat then
        self.btnApplyThermostat:setEnable(greenhouse ~= nil)
    end
    if self.btnClear then
        self.btnClear:setEnable(slot ~= nil and tostring(slot.state or "Empty") ~= "Empty")
    end
    if self.btnPlant then
        self.btnPlant:setEnable(slot ~= nil and (tostring(slot.state or "Empty") == "Empty" or tostring(slot.state or "") == "Dead") and #(self.seedOptions or {}) > 0)
    end
    if self.detailText then
        self.detailText.text = Utils.BuildDetailText(greenhouse, slot)
        self.detailText:paginate()
    end
end

function DC_GreenhouseModal:applySnapshot(snapshot, version)
    self.snapshot = snapshot or {}
    self.version = version
    self:populateGreenhouses()
    self:populateSlots()
    self:populateSeeds()
    self:refreshSelectionState()
end

function DC_GreenhouseModal:requestSnapshot()
    Bridge.RequestSnapshot(self.version or Bridge.GetCachedVersion())
end

function DC_GreenhouseModal:onBridgeEvent(eventName, payload)
    if eventName == "resources_snapshot" then
        self:applySnapshot(payload and payload.snapshot or nil, payload and payload.version or nil)
        if self:getIsVisible() then
            self:updateStatus("Greenhouse synced.")
        end
    elseif eventName == "colony_notice" then
        if self:getIsVisible() then
            self:updateStatus(payload and payload.message or "Colony update received.")
        end
    end
end

function DC_GreenhouseModal:onGreenhouseChanged()
    self.selectedSlotIndex = 1
    self:populateSlots()
    self:refreshSelectionState()
end

function DC_GreenhouseModal:onSeedSelectionChanged()
    self:refreshSelectionState()
end

function DC_GreenhouseModal:onApplyThermostatClicked()
    local greenhouse = self:getSelectedGreenhouse()
    if not greenhouse then
        self:updateStatus("Select a greenhouse first.")
        return
    end

    local thermostatC = tonumber(self.tempEntry and self.tempEntry:getText() or "")
    if not thermostatC then
        self:updateStatus("Enter a valid thermostat temperature.")
        return
    end

    Bridge.SendCommand("SetGreenhouseThermostat", {
        buildingID = greenhouse.buildingID,
        thermostatC = thermostatC
    })
    self:updateStatus("Applying greenhouse thermostat...")
end

function DC_GreenhouseModal:onPlantClicked()
    local greenhouse = self:getSelectedGreenhouse()
    local slot = self:getSelectedSlot()
    local seedOption = self.seedCombo and self.seedCombo.options and self.seedCombo.options[self.seedCombo.selected] or nil
    local seedFullType = seedOption and seedOption.data or nil

    if not greenhouse or not slot or not seedFullType then
        self:updateStatus("Select a garden bed and a seed first.")
        return
    end

    Bridge.SendCommand("PlantGreenhouseSlot", {
        buildingID = greenhouse.buildingID,
        slotIndex = slot.slotIndex,
        seedFullType = seedFullType
    })
    self:updateStatus("Planting greenhouse bed...")
end

function DC_GreenhouseModal:onClearClicked()
    local greenhouse = self:getSelectedGreenhouse()
    local slot = self:getSelectedSlot()
    if not greenhouse or not slot then
        self:updateStatus("Select a garden bed first.")
        return
    end

    Bridge.SendCommand("ClearGreenhouseSlot", {
        buildingID = greenhouse.buildingID,
        slotIndex = slot.slotIndex
    })
    self:updateStatus("Clearing greenhouse bed...")
end

function DC_GreenhouseModal:onRefreshClicked()
    self:updateStatus("Refreshing greenhouse data...")
    self:requestSnapshot()
end

function DC_GreenhouseModal:onCloseClicked()
    self:close()
end

function DC_GreenhouseModal:close()
    if self.listenerKey then
        Bridge.RemoveListener(self.listenerKey)
        self.listenerKey = nil
    end
    self:setVisible(false)
    self:removeFromUIManager()
    if DC_GreenhouseModal.instance == self then
        DC_GreenhouseModal.instance = nil
    end
end

function DC_GreenhouseModal:new(x, y, width, height)
    local o = ISCollapsableWindow:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.snapshot = nil
    o.version = nil
    o.selectedSlotIndex = 1
    o.preferredBuildingID = nil
    o.selectedGreenhouseID = nil
    o.seedOptions = {}
    return o
end

function DC_GreenhouseModal.Open(args)
    args = args or {}
    if DC_GreenhouseModal.instance then
        DC_GreenhouseModal.instance:close()
    end

    local width = 760
    local height = 590
    local x = (getCore():getScreenWidth() - width) / 2
    local y = (getCore():getScreenHeight() - height) / 2
    local modal = DC_GreenhouseModal:new(x, y, width, height)
    modal:applyArgs(args)
    modal.listenerKey = "greenhouse_modal_" .. tostring(modal)
    modal:initialise()
    modal:instantiate()
    modal:addToUIManager()
    modal:bringToTop()

    Bridge.AddListener(modal.listenerKey, function(eventName, payload)
        if modal and modal.onBridgeEvent then
            modal:onBridgeEvent(eventName, payload)
        end
    end)

    local cachedSnapshot = Bridge.GetCachedSnapshot()
    if cachedSnapshot then
        modal:applySnapshot(cachedSnapshot, Bridge.GetCachedVersion())
    else
        modal:applySnapshot({}, nil)
    end

    modal:updateStatus("Loading greenhouse data...")
    modal:requestSnapshot()
    DC_GreenhouseModal.instance = modal
    return modal
end

return DC_GreenhouseModal

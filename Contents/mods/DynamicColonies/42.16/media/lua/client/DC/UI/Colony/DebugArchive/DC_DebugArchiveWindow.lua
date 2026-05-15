require "ISUI/ISCollapsableWindow"
require "ISUI/ISButton"
require "ISUI/ISRichTextPanel"
require "ISUI/ISScrollingListBox"
require "DC/UI/Colony/DebugArchive/DC_DebugArchiveClientBridge"
require "DC/UI/Colony/DebugArchive/DebugArchiveLayout/DC_DebugArchiveLayout"
require "DC/UI/Colony/DebugArchive/DebugArchiveSections/DC_DebugArchiveSections_Overview"
require "DC/UI/Colony/DebugArchive/DebugArchiveSections/DC_DebugArchiveSections_Workers"
require "DC/UI/Colony/DebugArchive/DebugArchiveSections/DC_DebugArchiveSections_Items"
require "DC/UI/Colony/DebugArchive/DebugArchiveSections/DC_DebugArchiveSections_Buildings"
require "DC/UI/Colony/DebugArchive/DebugArchiveSections/DC_DebugArchiveSections_Raw"

DC_DebugArchiveWindow = ISCollapsableWindow:derive("DC_DebugArchiveWindow")
DC_DebugArchiveWindow.instance = nil

local Bridge = DC_DebugArchiveClientBridge
local Layout = DC_DebugArchiveLayout

local SECTION_BUILDERS = {
    Overview = DC_DebugArchiveSections_Overview,
    Workers = DC_DebugArchiveSections_Workers,
    Items = DC_DebugArchiveSections_Items,
    Buildings = DC_DebugArchiveSections_Buildings,
    Raw = DC_DebugArchiveSections_Raw,
}

function DC_DebugArchiveWindow:initialise()
    ISCollapsableWindow.initialise(self)
    self:setResizable(true)
    self.listenerKey = "debug_archive_window"
end

function DC_DebugArchiveWindow:createChildren()
    Layout.CreateChildren(self)

    self.selectedSectionID = self.selectedSectionID or "Overview"
    self:updateSectionButtons()
    self:updateStatus("Debug archive ready.")

    Bridge.AddListener(self.listenerKey, function(eventName, payload)
        self:onBridgeEvent(eventName, payload)
    end)

    local cachedIndex = Bridge.GetCachedIndexSnapshot()
    if cachedIndex then
        self:applyIndexSnapshot(cachedIndex, Bridge.GetCachedIndexVersion())
    end

    self:requestIndex()
end

function DC_DebugArchiveWindow:onBridgeEvent(eventName, payload)
    if eventName == "debug_archive_index" or eventName == "debug_archive_index_unchanged" then
        self:applyIndexSnapshot(payload and payload.snapshot or nil, payload and payload.version or nil)
        if eventName == "debug_archive_index" then
            self:updateStatus("Debug archive index updated.")
        end
        return
    end

    if eventName == "debug_archive_colony" or eventName == "debug_archive_colony_unchanged" then
        local owner = payload and payload.ownerUsername or nil
        if owner and tostring(owner) == tostring(self.selectedOwnerUsername or "") then
            self:applyColonySnapshot(payload and payload.snapshot or nil, payload and payload.version or nil)
            if eventName == "debug_archive_colony" then
                self:updateStatus("Loaded colony snapshot for " .. tostring(owner) .. ".")
            end
        end
        return
    end

    if eventName == "colony_notice" then
        self:updateStatus(payload and payload.message or "Colony update received.")
    end
end

function DC_DebugArchiveWindow:updateStatus(message)
    if self.statusText then
        self.statusText.text = " <RGB:0.88,0.88,0.88> " .. tostring(message or "") .. " "
        Layout.RefreshRichText(self.statusText)
    end
end

function DC_DebugArchiveWindow:updateSectionButtons()
    for sectionID, button in pairs(self.sectionButtons or {}) do
        button:setEnable(tostring(sectionID) ~= tostring(self.selectedSectionID or "Overview"))
    end
end

function DC_DebugArchiveWindow:setSelectedOwner(ownerUsername)
    local owner = tostring(ownerUsername or "")
    if owner == "" then
        return
    end

    self.selectedOwnerUsername = owner
    self.colonyVersion = nil
    self:populateColonyList()
    self:refreshView()
    self:requestSelectedColony()
end

function DC_DebugArchiveWindow:populateColonyList()
    if not self.colonyList then
        return
    end

    self.colonyList:clear()
    local selectedIndex = -1

    for index, entry in ipairs(self.indexSnapshot and self.indexSnapshot.colonies or {}) do
        local label = tostring(entry.ownerUsername or "colony")
            .. " | W" .. tostring(entry.workerCount or 0)
            .. " | B" .. tostring(entry.buildingCount or 0)
            .. " | Inv " .. tostring(entry.inventoryItemCount or 0)
        self.colonyList:addItem(label, entry)
        if tostring(entry.ownerUsername or "") == tostring(self.selectedOwnerUsername or "") then
            selectedIndex = index
        end
    end

    if selectedIndex == -1 and #self.colonyList.items > 0 then
        selectedIndex = 1
        local first = self.colonyList.items[1]
        self.selectedOwnerUsername = first and first.item and tostring(first.item.ownerUsername or "") or self.selectedOwnerUsername
    end

    self.colonyList.selected = selectedIndex
end

function DC_DebugArchiveWindow:applyIndexSnapshot(snapshot, version)
    self.indexSnapshot = snapshot or { colonies = {} }
    self.indexVersion = version
    self:populateColonyList()
    if self.selectedOwnerUsername and self.selectedOwnerUsername ~= "" then
        local cached = Bridge.GetCachedColonySnapshot(self.selectedOwnerUsername)
        if cached then
            self:applyColonySnapshot(cached, Bridge.GetCachedColonyVersion(self.selectedOwnerUsername))
        end
        self:requestSelectedColony()
    else
        self:refreshView()
    end
end

function DC_DebugArchiveWindow:applyColonySnapshot(snapshot, version)
    self.colonySnapshot = snapshot or nil
    self.colonyVersion = version
    self:refreshView()
end

function DC_DebugArchiveWindow:requestIndex()
    Bridge.RequestIndex(self.indexVersion or Bridge.GetCachedIndexVersion())
end

function DC_DebugArchiveWindow:requestSelectedColony()
    local owner = tostring(self.selectedOwnerUsername or "")
    if owner == "" then
        return
    end

    local cached = Bridge.GetCachedColonySnapshot(owner)
    if cached then
        self:applyColonySnapshot(cached, Bridge.GetCachedColonyVersion(owner))
    end
    Bridge.RequestColony(owner, self.colonyVersion or Bridge.GetCachedColonyVersion(owner))
end

function DC_DebugArchiveWindow:onRefreshClicked()
    self:updateStatus("Refreshing debug archive...")
    self:requestIndex()
    self:requestSelectedColony()
end

function DC_DebugArchiveWindow:onSectionClicked(button)
    self.selectedSectionID = button and button.sectionID or "Overview"
    self:updateSectionButtons()
    self:refreshView()
end

function DC_DebugArchiveWindow:onColonySelected(entry)
    local owner = entry and entry.ownerUsername or nil
    if not owner or tostring(owner) == "" then
        return
    end

    self.selectedOwnerUsername = tostring(owner)
    self.colonyVersion = nil
    self:updateStatus("Loading colony snapshot for " .. tostring(owner) .. "...")
    self:requestSelectedColony()
end

function DC_DebugArchiveWindow:refreshView()
    if not self.detailText then
        return
    end

    if not self.colonySnapshot then
        self.detailText.text = " <RGB:0.72,0.72,0.72> Select a colony from the left list to inspect its debug archive. <LINE> "
        Layout.RefreshRichText(self.detailText)
        return
    end

    local builder = SECTION_BUILDERS[self.selectedSectionID or "Overview"]
    if builder and builder.Build then
        self.detailText.text = builder.Build(self, self.colonySnapshot)
    else
        self.detailText.text = " <RGB:1,0.5,0.5> Missing section renderer: " .. tostring(self.selectedSectionID) .. " <LINE> "
    end
    Layout.RefreshRichText(self.detailText)
end

function DC_DebugArchiveWindow:close()
    self:setVisible(false)
    self:removeFromUIManager()
end

function DC_DebugArchiveWindow.Open(parent, options)
    options = options or {}

    if not DC_DebugArchiveWindow.instance then
        local width = 1080
        local height = 720
        local x = (getCore():getScreenWidth() - width) / 2
        local y = (getCore():getScreenHeight() - height) / 2
        local window = DC_DebugArchiveWindow:new(x, y, width, height)
        window:initialise()
        window:addToUIManager()
        window:setVisible(true)
        window:bringToTop()
        DC_DebugArchiveWindow.instance = window
    else
        DC_DebugArchiveWindow.instance:setVisible(true)
        DC_DebugArchiveWindow.instance:addToUIManager()
        DC_DebugArchiveWindow.instance:bringToTop()
    end

    if options.ownerUsername and DC_DebugArchiveWindow.instance.setSelectedOwner then
        DC_DebugArchiveWindow.instance:setSelectedOwner(options.ownerUsername)
    else
        DC_DebugArchiveWindow.instance:requestIndex()
        DC_DebugArchiveWindow.instance:requestSelectedColony()
    end

    return DC_DebugArchiveWindow.instance
end

function DC_DebugArchiveWindow:new(x, y, width, height)
    local o = ISCollapsableWindow:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.title = "Dynamic Colonies Debug Archive"
    o.resizable = true
    return o
end

return DC_DebugArchiveWindow

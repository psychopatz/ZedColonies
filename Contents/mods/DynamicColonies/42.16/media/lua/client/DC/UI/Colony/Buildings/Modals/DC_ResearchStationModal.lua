require "ISUI/ISCollapsableWindow"
require "ISUI/ISScrollingListBox"
require "ISUI/ISRichTextPanel"
require "ISUI/ISButton"
require "ISUI/ISPanel"

DC_ResearchStationModal = ISCollapsableWindow:derive("DC_ResearchStationModal")
DC_ResearchStationModal.instance = DC_ResearchStationModal.instance or nil
DC_ResearchStationModal.cachedSnapshot = DC_ResearchStationModal.cachedSnapshot or nil
DC_ResearchStationModal.EventsAdded = DC_ResearchStationModal.EventsAdded or false
DC_ResearchStationModalInternal = DC_ResearchStationModalInternal or {}

require "DC/UI/Colony/Buildings/Modals/ResearchStationModal/DC_ResearchStationModal_Utils"
require "DC/UI/Colony/Buildings/Modals/ResearchStationModal/DC_ResearchStationModal_ItemsPanel"
require "DC/UI/Colony/Buildings/Modals/ResearchStationModal/DC_ResearchStationModal_QueueList"
require "DC/UI/Colony/Buildings/Modals/ResearchStationModal/DC_ResearchStationModal_Details"
require "DC/UI/Colony/Buildings/Modals/ResearchStationModal/DC_ResearchStationModal_ViewLifecycle"
require "DC/UI/Colony/Buildings/Modals/ResearchStationModal/DC_ResearchStationModal_Actions"
require "DC/UI/Colony/Buildings/Modals/ResearchStationModal/DC_ResearchStationModal_Network"

function DC_ResearchStationModal:new(x, y, width, height, options)
    local o = ISCollapsableWindow:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.title = tostring(options and options.title or "Research Station")
    o.resizable = true
    o.ownerWindow = options and options.ownerWindow or nil
    o.onRefreshBuildings = options and options.onRefreshBuildings or nil
    o.buildingID = options and options.buildingID or nil
    o.snapshot = nil
    o.snapshotVersion = nil
    o.selectedCandidate = nil
    o.selectedQueue = nil
    o.statusText = ""
    o.pendingBuildingRefresh = false
    o.minimumWidth = 860
    o.minimumHeight = 520
    return o
end

function DC_ResearchStationModal.Open(options)
    local existing = DC_ResearchStationModal.instance
    if existing and existing:getIsVisible() then
        existing:close()
    end

    local width = 1040
    local height = 620
    local x = (getCore():getScreenWidth() - width) / 2
    local y = (getCore():getScreenHeight() - height) / 2
    local modal = DC_ResearchStationModal:new(x, y, width, height, options or {})
    modal:initialise()
    modal:instantiate()
    modal:addToUIManager()
    modal:setVisible(true)
    DC_ResearchStationModal.instance = modal
    modal:requestSnapshot(true)
    modal:updateStatus("Loading research queue...")
    return modal
end

return DC_ResearchStationModal

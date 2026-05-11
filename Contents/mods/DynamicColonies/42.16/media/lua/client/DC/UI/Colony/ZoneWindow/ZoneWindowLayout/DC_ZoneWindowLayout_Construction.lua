-- ============================================================================
-- DC_ZoneWindowLayout_Construction.lua — createChildren for DC_ZoneWindow
-- ============================================================================

DC_ZoneWindow = DC_ZoneWindow or {}
DC_ZoneWindow.Internal = DC_ZoneWindow.Internal or {}

local ZoneWindowLayout = DC_ZoneWindow.Internal.ZoneWindowLayout or {}

-- ---------------------------------------------------------------------------
-- Header Panel (derived ISPanel with title + icon buttons)
-- ---------------------------------------------------------------------------

DC_ZoneWindowHeaderPanel = ISPanel:derive("DC_ZoneWindowHeaderPanel")

function DC_ZoneWindowHeaderPanel:createChildren()
    ISPanel.createChildren(self)

    local btnSize = 18

    self.btnOptions = ISButton:new(self.width - btnSize - 10, 5, btnSize, btnSize, "", self, function()
        -- Placeholder: future settings hook
    end)
    self.btnOptions:initialise()
    self.btnOptions.borderColor = { r = 1, g = 1, b = 1, a = 0.2 }
    self.btnOptions.backgroundColor = { r = 0, g = 0, b = 0, a = 0 }
    self.btnOptions.displayBackground = false
    if getTexture("media/ui/inventoryPanes/Button_Settings.png") then
        self.btnOptions:setImage(getTexture("media/ui/inventoryPanes/Button_Settings.png"))
    end
    self:addChild(self.btnOptions)
end

function DC_ZoneWindowHeaderPanel:prerender()
    ISPanel.prerender(self)
    self:drawTextCentre("ZONE MANAGEMENT", self.width / 2, 6, 1, 1, 1, 1, UIFont.Large)

    if self.btnOptions then
        self.btnOptions:setX(self.width - self.btnOptions:getWidth() - 10)
    end
end

function DC_ZoneWindowHeaderPanel:new(x, y, width, height)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.backgroundColor = { r = 0, g = 0, b = 0, a = 0 }
    return o
end


-- ---------------------------------------------------------------------------
-- createChildren — builds the entire UI tree
-- ---------------------------------------------------------------------------

function DC_ZoneWindow:createChildren()
    ISCollapsableWindow.createChildren(self)

    local L   = ZoneWindowLayout
    local th  = self:titleBarHeight()
    local pad = 10

    -- Computed positions (will be refined by applyWindowLayout)
    local headerY    = th + pad + L.WINDOW_HEADER_CLEARANCE
    local toolbarY   = headerY + L.HEADER_HEIGHT + 4
    local tabBarH    = L.TAB_BAR_HEIGHT or 30
    local contentY   = toolbarY + L.TOOLBAR_HEIGHT + tabBarH + pad
    local footerH    = L.BUTTON_BAR_HEIGHT
    local contentH   = self.height - contentY - footerH - pad
    local listWidth  = math.max(L.LIST_MIN_WIDTH, math.floor(self.width * 0.35))
    local rightX     = listWidth + (pad * 2)
    local rightWidth = math.max(100, self.width - rightX - pad)
    local splitGap   = 8
    local detailH    = math.max(L.DETAIL_MIN_HEIGHT, math.floor(contentH * 0.45))
    local rectListY  = contentY + detailH + splitGap
    local rectListH  = math.max(L.RECT_LIST_MIN_HEIGHT, contentH - detailH - splitGap)


    -- ===== HEADER =====
    self.headerPanel = DC_ZoneWindowHeaderPanel:new(0, th, self.width, L.HEADER_HEIGHT)
    self.headerPanel:initialise()
    self.headerPanel:setAnchorRight(true)
    self:addChild(self.headerPanel)


    -- ===== TOOLBAR =====
    self.toolbar = ISPanel:new(pad, toolbarY, self.width - pad * 2, L.TOOLBAR_HEIGHT)
    self.toolbar:initialise()
    self.toolbar.backgroundColor = { r = 0, g = 0, b = 0, a = 0 }
    self.toolbar:setAnchorRight(true)
    self:addChild(self.toolbar)

    -- Add Zone button
    self.btnAddZone = ISButton:new(0, 3, 110, 28, "Add Zone", self, DC_ZoneWindow.onAddZone)
    self.btnAddZone:initialise()
    self.toolbar:addChild(self.btnAddZone)

    -- Delete Zone button
    self.btnDeleteZone = ISButton:new(120, 3, 110, 28, "Delete Zone", self, DC_ZoneWindow.onDeleteZone)
    self.btnDeleteZone:initialise()
    self.btnDeleteZone:setEnable(false)
    self.btnDeleteZone.backgroundColor = { r = 0.45, g = 0.08, b = 0.08, a = 1 }
    self.btnDeleteZone.backgroundColorMouseOver = { r = 0.62, g = 0.12, b = 0.12, a = 1 }
    self.toolbar:addChild(self.btnDeleteZone)


    -- ===== TAB BAR =====
    local tabBarY = toolbarY + L.TOOLBAR_HEIGHT + 2
    self.tabBar = ISPanel:new(pad, tabBarY, self.width - pad * 2, 28)
    self.tabBar:initialise()
    self.tabBar.backgroundColor = { r = 0, g = 0, b = 0, a = 0 }
    self.tabBar:setAnchorRight(true)
    self:addChild(self.tabBar)

    self.btnTabZones = ISButton:new(0, 0, 100, 26, "Zones", self, DC_ZoneWindow.onSwitchTab)
    self.btnTabZones.internal = "TAB_ZONES"
    self.btnTabZones:initialise()
    self.btnTabZones.backgroundColor = { r = 0.2, g = 0.2, b = 0.2, a = 1 }
    self.btnTabZones.backgroundColorMouseOver = { r = 0.3, g = 0.3, b = 0.3, a = 1 }
    self.btnTabZones.borderColor = { r = 0.6, g = 0.8, b = 1.0, a = 0.6 }
    self.tabBar:addChild(self.btnTabZones)

    self.btnTabMap = ISButton:new(110, 0, 100, 26, "Map", self, DC_ZoneWindow.onSwitchTab)
    self.btnTabMap.internal = "TAB_MAP"
    self.btnTabMap:initialise()
    self.tabBar:addChild(self.btnTabMap)

    self.activeTab = "TAB_ZONES"


    -- ===== ZONE LIST (left side) =====
    self.zoneList = ISScrollingListBox:new(pad, contentY, listWidth, contentH)
    self.zoneList:initialise()
    self.zoneList:instantiate()
    self.zoneList.itemheight = 32
    self.zoneList.target = self
    self.zoneList.onmousedown = DC_ZoneWindow.onZoneListMouseDown
    self.zoneList.drawBorder = true
    self.zoneList.borderColor = { r = 1, g = 1, b = 1, a = 0.1 }
    self.zoneList:setAnchorLeft(true)
    self.zoneList:setAnchorTop(true)
    self.zoneList:setAnchorBottom(true)
    self:addChild(self.zoneList)


    -- ===== DETAIL PANEL (right top) =====
    self.detailPanel = ISPanel:new(rightX, contentY, rightWidth, detailH)
    self.detailPanel:initialise()
    self.detailPanel.backgroundColor = { r = 0, g = 0, b = 0, a = 0.2 }
    self.detailPanel.borderColor = { r = 1, g = 1, b = 1, a = 0.1 }
    self.detailPanel:setAnchorRight(true)
    self.detailPanel.prerender = function(panel)
        ISPanel.prerender(panel)
        panel:drawText("Zone Details", 8, 6, 1, 1, 1, 1, UIFont.Medium)
    end
    self:addChild(self.detailPanel)

    -- Zone name entry
    self.detailNameLabel = ISLabel:new(L.PANEL_INNER_PAD, L.PANEL_HEADER_HEIGHT + 4, 20, "Name:", 1, 1, 1, 1, UIFont.Small, true)
    self.detailNameLabel:initialise()
    self.detailPanel:addChild(self.detailNameLabel)

    self.detailNameEntry = ISTextEntryBox:new("", 60, L.PANEL_HEADER_HEIGHT + 2, 200, 22)
    self.detailNameEntry:initialise()
    self.detailNameEntry.onTextChange = function()
        if self.selectedZone then
            self.selectedZone.name = self.detailNameEntry:getText()
            self:populateZoneList()
        end
    end
    self.detailPanel:addChild(self.detailNameEntry)

    -- Zone type combo
    self.detailTypeLabel = ISLabel:new(L.PANEL_INNER_PAD, L.PANEL_HEADER_HEIGHT + 32, 20, "Type:", 1, 1, 1, 1, UIFont.Small, true)
    self.detailTypeLabel:initialise()
    self.detailPanel:addChild(self.detailTypeLabel)

    self.detailTypeCombo = ISComboBox:new(60, L.PANEL_HEADER_HEIGHT + 30, 200, 22, self, function(owner)
        if owner.selectedZone then
            local types = DC_ZoneData.getTypeList()
            local idx = owner.detailTypeCombo.selected
            if types[idx] then
                owner.selectedZone.zoneType = types[idx].id
                owner:populateZoneList()
            end
        end
    end)
    self.detailTypeCombo:initialise()
    -- Populate combo options
    local typeList = DC_ZoneData.getTypeList()
    for _, t in ipairs(typeList) do
        self.detailTypeCombo:addOption(t.label)
    end
    self.detailPanel:addChild(self.detailTypeCombo)

    -- Zone info labels
    self.detailInfoLabel = ISLabel:new(L.PANEL_INNER_PAD, L.PANEL_HEADER_HEIGHT + 60, 20, "", 0.7, 0.7, 0.7, 1, UIFont.Small, true)
    self.detailInfoLabel:initialise()
    self.detailPanel:addChild(self.detailInfoLabel)


    -- ===== RECT LIST (right bottom) =====
    self.rectList = ISScrollingListBox:new(rightX, rectListY, rightWidth, rectListH)
    self.rectList:initialise()
    self.rectList:instantiate()
    self.rectList.itemheight = 28
    self.rectList.target = self
    self.rectList.onmousedown = DC_ZoneWindow.onRectListMouseDown
    self.rectList.drawBorder = true
    self.rectList.borderColor = { r = 1, g = 1, b = 1, a = 0.1 }
    self.rectList:setAnchorRight(true)
    self.rectList:setAnchorBottom(true)
    self:addChild(self.rectList)

    -- Rect toolbar
    self.rectToolbar = ISPanel:new(rightX, rectListY + rectListH + 4, rightWidth, L.TOOLBAR_HEIGHT)
    self.rectToolbar:initialise()
    self.rectToolbar.backgroundColor = { r = 0, g = 0, b = 0, a = 0 }
    self.rectToolbar:setAnchorRight(true)
    self.rectToolbar:setAnchorBottom(true)
    self:addChild(self.rectToolbar)

    self.btnAddArea = ISButton:new(0, 3, 110, 28, "Add Area", self, DC_ZoneWindow.onAddArea)
    self.btnAddArea:initialise()
    self.btnAddArea:setEnable(false)
    self.rectToolbar:addChild(self.btnAddArea)

    self.btnDeleteArea = ISButton:new(120, 3, 110, 28, "Delete Area", self, DC_ZoneWindow.onDeleteArea)
    self.btnDeleteArea:initialise()
    self.btnDeleteArea:setEnable(false)
    self.btnDeleteArea.backgroundColor = { r = 0.45, g = 0.08, b = 0.08, a = 1 }
    self.btnDeleteArea.backgroundColorMouseOver = { r = 0.62, g = 0.12, b = 0.12, a = 1 }
    self.rectToolbar:addChild(self.btnDeleteArea)

    self.btnShowArea = ISButton:new(240, 3, 110, 28, "Show Area", self, DC_ZoneWindow.onShowArea)
    self.btnShowArea:initialise()
    self.btnShowArea:setEnable(false)
    self.rectToolbar:addChild(self.btnShowArea)

    self.btnEditArea = ISButton:new(360, 3, 110, 28, "Edit Area", self, DC_ZoneWindow.onEditArea)
    self.btnEditArea:initialise()
    self.btnEditArea:setEnable(false)
    self.rectToolbar:addChild(self.btnEditArea)


    -- ===== MAP PANEL (hidden by default, shown on Map tab) =====
    self.mapPanel = DC_ZoneWindowMapPanel and DC_ZoneWindowMapPanel:new(pad, contentY, self.width - pad * 2, contentH, self) or nil
    if self.mapPanel then
        self.mapPanel:initialise()
        self.mapPanel:setVisible(false)
        self.mapPanel:setAnchorRight(true)
        self.mapPanel:setAnchorBottom(true)
        self:addChild(self.mapPanel)
    end


    -- Apply dynamic layout
    ZoneWindowLayout.applyWindowLayout(self)

    -- Initial empty state
    self:refreshDetailPanel()
end

require "ISUI/ISCollapsableWindow"
require "ISUI/ISButton"
require "ISUI/ISLabel"
require "ISUI/ISTextEntryBox"

DC_CompanionLootModal = ISCollapsableWindow:derive("DC_CompanionLootModal")
DC_CompanionLootModal.instance = nil

local DEFAULT_RADIUS = 10
local MIN_RADIUS = 2
local MAX_RADIUS = 25

local function clampRadius(value)
    local number = math.floor(tonumber(value) or DEFAULT_RADIUS)
    if number < MIN_RADIUS then
        return MIN_RADIUS
    end
    if number > MAX_RADIUS then
        return MAX_RADIUS
    end
    return number
end

local function getCompanionInternal()
    local companion = DC_Colony and DC_Colony.Companion or nil
    return companion and companion.Internal or nil
end

local function buildDefaultConfig()
    return {
        radius = DEFAULT_RADIUS,
        includeWorldContainers = true,
        includeLooseWorldItems = true,
        includeGroundContainers = true,
        includeFurnitureContainers = true,
        includeCorpseContainers = true,
        includeVehicleContainers = true,
        profileID = nil,
        rawTags = {},
    }
end

local function cloneLootConfig(config)
    local companionInternal = getCompanionInternal()
    if companionInternal and companionInternal.CloneCompanionLootConfig then
        return companionInternal.CloneCompanionLootConfig(config)
    end

    local source = type(config) == "table" and config or buildDefaultConfig()
    local includeWorldContainers = source.includeWorldContainers ~= false
    return {
        radius = clampRadius(source.radius),
        includeWorldContainers = includeWorldContainers,
        includeLooseWorldItems = source.includeLooseWorldItems ~= false,
        includeGroundContainers = source.includeGroundContainers ~= false,
        includeFurnitureContainers = source.includeFurnitureContainers ~= false,
        includeCorpseContainers = source.includeCorpseContainers ~= false,
        includeVehicleContainers = source.includeVehicleContainers ~= false,
        profileID = nil,
        rawTags = {},
    }
end

local function getWorkerLootConfig(worker)
    local companionInternal = getCompanionInternal()
    if companionInternal and companionInternal.GetCompanionLootConfig then
        return cloneLootConfig(companionInternal.GetCompanionLootConfig(worker))
    end

    local companionData = type(worker and worker.companion) == "table" and worker.companion or {}
    return cloneLootConfig(companionData.lootConfig)
end

local function formatFallback(template, params)
    local text = tostring(template or "")
    if type(params) ~= "table" then
        return text
    end

    return (text:gsub("{([%w_]+)}", function(name)
        local value = params[name]
        return value == nil and ("{" .. name .. "}") or tostring(value)
    end))
end

local function T(key, fallback, params)
    if DC and DC.Text and DC.Text.Get then
        return DC.Text.Get(key, params, fallback)
    end
    return formatFallback(fallback or key, params)
end

function DC_CompanionLootModal:initialise()
    ISCollapsableWindow.initialise(self)
    self:setResizable(false)
    self.backgroundColor = { r = 0.02, g = 0.02, b = 0.02, a = 0.94 }
    self.borderColor = { r = 0.9, g = 0.9, b = 0.9, a = 0.18 }
end

function DC_CompanionLootModal:applyToggleStyle(button, enabled, onLabel, offLabel)
    if not button then
        return
    end

    button.title = (enabled and onLabel or offLabel) or ""
    if enabled then
        button.backgroundColor = { r = 0.10, g = 0.34, b = 0.12, a = 1 }
        button.backgroundColorMouseOver = { r = 0.14, g = 0.46, b = 0.18, a = 1 }
        button.borderColor = { r = 0.58, g = 0.92, b = 0.62, a = 0.35 }
    else
        button.backgroundColor = { r = 0.16, g = 0.16, b = 0.16, a = 1 }
        button.backgroundColorMouseOver = { r = 0.24, g = 0.24, b = 0.24, a = 1 }
        button.borderColor = { r = 1, g = 1, b = 1, a = 0.15 }
    end
end

function DC_CompanionLootModal:updateContainerButtons()
    self:applyToggleStyle(self.btnLooseWorldItems, self.includeLooseWorldItems ~= false, T("DCCommon_UI_CompanionLoot_GroundItemsOn", "Ground Items: On"), T("DCCommon_UI_CompanionLoot_GroundItemsOff", "Ground Items: Off"))
    self:applyToggleStyle(self.btnGroundContainers, self.includeGroundContainers ~= false, T("DCCommon_UI_CompanionLoot_GroundBagsOn", "Ground Bags: On"), T("DCCommon_UI_CompanionLoot_GroundBagsOff", "Ground Bags: Off"))
    self:applyToggleStyle(self.btnFurnitureContainers, self.includeFurnitureContainers ~= false, T("DCCommon_UI_CompanionLoot_FurnitureOn", "Furniture: On"), T("DCCommon_UI_CompanionLoot_FurnitureOff", "Furniture: Off"))
    self:applyToggleStyle(self.btnCorpseContainers, self.includeCorpseContainers ~= false, T("DCCommon_UI_CompanionLoot_CorpsesOn", "Corpses: On"), T("DCCommon_UI_CompanionLoot_CorpsesOff", "Corpses: Off"))
    self:applyToggleStyle(self.btnVehicleContainers, self.includeVehicleContainers ~= false, T("DCCommon_UI_CompanionLoot_VehiclesOn", "Vehicles: On"), T("DCCommon_UI_CompanionLoot_VehiclesOff", "Vehicles: Off"))
end

function DC_CompanionLootModal:setCurrentConfig(config)
    local nextConfig = cloneLootConfig(config)
    self.currentConfig = nextConfig
    self.includeWorldContainers = nextConfig.includeWorldContainers ~= false
    self.includeLooseWorldItems = nextConfig.includeLooseWorldItems ~= false
    self.includeGroundContainers = nextConfig.includeGroundContainers ~= false
    self.includeFurnitureContainers = nextConfig.includeFurnitureContainers ~= false
    self.includeCorpseContainers = nextConfig.includeCorpseContainers ~= false
    self.includeVehicleContainers = nextConfig.includeVehicleContainers ~= false

    if self.radiusEntry then
        self.radiusEntry:setText(tostring(nextConfig.radius or DEFAULT_RADIUS))
    end

    self:updateContainerButtons()
end

function DC_CompanionLootModal:buildCurrentConfig()
    return cloneLootConfig({
        radius = self.radiusEntry and self.radiusEntry:getText() or DEFAULT_RADIUS,
        includeWorldContainers = self.includeLooseWorldItems ~= false
            or self.includeGroundContainers ~= false
            or self.includeFurnitureContainers ~= false,
        includeLooseWorldItems = self.includeLooseWorldItems ~= false,
        includeGroundContainers = self.includeGroundContainers ~= false,
        includeFurnitureContainers = self.includeFurnitureContainers ~= false,
        includeCorpseContainers = self.includeCorpseContainers ~= false,
        includeVehicleContainers = self.includeVehicleContainers ~= false,
        profileID = nil,
        rawTags = {},
    })
end

function DC_CompanionLootModal:createChildren()
    ISCollapsableWindow.createChildren(self)

    local pad = 10
    local th = self:titleBarHeight()
    local contentY = th + pad
    local buttonY = self.height - 42
    local noteY = buttonY - 48

    self.promptLabel = ISLabel:new(
        pad,
        contentY,
        20,
        tostring(self.promptText or T("DCCommon_UI_CompanionLoot_Prompt", "Configure companion loot search.")),
        1,
        1,
        1,
        1,
        UIFont.Small,
        true
    )
    self.promptLabel:initialise()
    self.promptLabel:instantiate()
    self:addChild(self.promptLabel)

    self.radiusLabel = ISLabel:new(pad, contentY + 34, 20, T("DCCommon_UI_CompanionLoot_SearchRadius", "Search Radius"), 0.8, 0.8, 0.8, 1, UIFont.Small, true)
    self.radiusLabel:initialise()
    self.radiusLabel:instantiate()
    self:addChild(self.radiusLabel)

    self.radiusEntry = ISTextEntryBox:new(tostring(DEFAULT_RADIUS), pad, contentY + 56, 80, 24)
    self.radiusEntry:initialise()
    self.radiusEntry:instantiate()
    self:addChild(self.radiusEntry)

    self.radiusHint = ISLabel:new(pad + 90, contentY + 60, 20, T("DCCommon_UI_CompanionLoot_RadiusHint", "tiles around you"), 0.7, 0.7, 0.7, 1, UIFont.Small, true)
    self.radiusHint:initialise()
    self.radiusHint:instantiate()
    self:addChild(self.radiusHint)

    self.sourcesLabel = ISLabel:new(pad, contentY + 100, 20, T("DCCommon_UI_CompanionLoot_SearchSources", "Search Sources"), 0.8, 0.8, 0.8, 1, UIFont.Small, true)
    self.sourcesLabel:initialise()
    self.sourcesLabel:instantiate()
    self:addChild(self.sourcesLabel)

    self.btnLooseWorldItems = ISButton:new(pad, contentY + 126, 120, 24, "", self, self.onToggleLooseWorldItems)
    self.btnLooseWorldItems:initialise()
    self.btnLooseWorldItems:instantiate()
    self:addChild(self.btnLooseWorldItems)

    self.btnGroundContainers = ISButton:new(pad + 130, contentY + 126, 120, 24, "", self, self.onToggleGroundContainers)
    self.btnGroundContainers:initialise()
    self.btnGroundContainers:instantiate()
    self:addChild(self.btnGroundContainers)

    self.btnFurnitureContainers = ISButton:new(pad + 260, contentY + 126, 120, 24, "", self, self.onToggleFurnitureContainers)
    self.btnFurnitureContainers:initialise()
    self.btnFurnitureContainers:instantiate()
    self:addChild(self.btnFurnitureContainers)

    self.btnCorpseContainers = ISButton:new(pad, contentY + 156, 120, 24, "", self, self.onToggleCorpseContainers)
    self.btnCorpseContainers:initialise()
    self.btnCorpseContainers:instantiate()
    self:addChild(self.btnCorpseContainers)

    self.btnVehicleContainers = ISButton:new(pad + 130, contentY + 156, 120, 24, "", self, self.onToggleVehicleContainers)
    self.btnVehicleContainers:initialise()
    self.btnVehicleContainers:instantiate()
    self:addChild(self.btnVehicleContainers)

    self.noteLabel = ISLabel:new(
        pad,
        noteY,
        20,
        T("DCCommon_UI_CompanionLoot_Note", "Loot filters were removed. Companions now search nearby sources, reveal discoveries, and wait for manual pickup choices."),
        0.72,
        0.72,
        0.72,
        1,
        UIFont.Small,
        true
    )
    self.noteLabel:initialise()
    self.noteLabel:instantiate()
    self:addChild(self.noteLabel)

    self.btnReset = ISButton:new(self.width - 310, buttonY, 90, 24, T("DCCommon_UI_CompanionLoot_Defaults", "Defaults"), self, self.onResetDefaults)
    self.btnReset:initialise()
    self.btnReset:instantiate()
    self:addChild(self.btnReset)

    self.btnCancel = ISButton:new(self.width - 210, buttonY, 90, 24, T("DCCommon_UI_CompanionLoot_Cancel", "Cancel"), self, self.onCancel)
    self.btnCancel:initialise()
    self.btnCancel:instantiate()
    self:addChild(self.btnCancel)

    self.btnSave = ISButton:new(self.width - 110, buttonY, 90, 24, T("DCCommon_UI_CompanionLoot_Save", "Save"), self, self.onSave)
    self.btnSave:initialise()
    self.btnSave:instantiate()
    self:addChild(self.btnSave)

    self:setCurrentConfig(self.currentConfig)
end

function DC_CompanionLootModal:onToggleLooseWorldItems()
    self.includeLooseWorldItems = not (self.includeLooseWorldItems ~= false)
    self.includeWorldContainers = self.includeLooseWorldItems ~= false
        or self.includeGroundContainers ~= false
        or self.includeFurnitureContainers ~= false
    self:updateContainerButtons()
end

function DC_CompanionLootModal:onToggleGroundContainers()
    self.includeGroundContainers = not (self.includeGroundContainers ~= false)
    self.includeWorldContainers = self.includeLooseWorldItems ~= false
        or self.includeGroundContainers ~= false
        or self.includeFurnitureContainers ~= false
    self:updateContainerButtons()
end

function DC_CompanionLootModal:onToggleFurnitureContainers()
    self.includeFurnitureContainers = not (self.includeFurnitureContainers ~= false)
    self.includeWorldContainers = self.includeLooseWorldItems ~= false
        or self.includeGroundContainers ~= false
        or self.includeFurnitureContainers ~= false
    self:updateContainerButtons()
end

function DC_CompanionLootModal:onToggleCorpseContainers()
    self.includeCorpseContainers = not (self.includeCorpseContainers ~= false)
    self:updateContainerButtons()
end

function DC_CompanionLootModal:onToggleVehicleContainers()
    self.includeVehicleContainers = not (self.includeVehicleContainers ~= false)
    self:updateContainerButtons()
end

function DC_CompanionLootModal:onResetDefaults()
    self:setCurrentConfig(buildDefaultConfig())
end

function DC_CompanionLootModal:onCancel()
    self:close()
end

function DC_CompanionLootModal:onSave()
    if self.onSaveConfig then
        self.onSaveConfig(self:buildCurrentConfig(), self.worker)
    end
    self:close()
end

function DC_CompanionLootModal:close()
    DC_CompanionLootModal.instance = nil
    ISCollapsableWindow.close(self)
end

function DC_CompanionLootModal:new(x, y, width, height, args)
    local o = ISCollapsableWindow:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self

    args = args or {}
    o.worker = args.worker
    o.promptText = args.promptText
    o.onSaveConfig = args.onSave
    o.currentConfig = getWorkerLootConfig(args.worker)
    o.includeWorldContainers = true
    o.includeLooseWorldItems = true
    o.includeGroundContainers = true
    o.includeFurnitureContainers = true
    o.includeCorpseContainers = true
    o.includeVehicleContainers = true
    o.title = args.title or T("DCCommon_UI_CompanionLoot_Title", "Companion Loot Setup")
    return o
end

function DC_CompanionLootModal.Open(args)
    if DC_CompanionLootModal.instance then
        DC_CompanionLootModal.instance:close()
    end

    local width = 520
    local height = 320
    local x = math.max(0, math.floor((getCore():getScreenWidth() - width) / 2))
    local y = math.max(0, math.floor((getCore():getScreenHeight() - height) / 2))
    local modal = DC_CompanionLootModal:new(x, y, width, height, args or {})
    modal:initialise()
    modal:instantiate()
    modal:addToUIManager()
    modal:setVisible(true)
    modal:bringToTop()
    DC_CompanionLootModal.instance = modal
    return modal
end

return DC_CompanionLootModal

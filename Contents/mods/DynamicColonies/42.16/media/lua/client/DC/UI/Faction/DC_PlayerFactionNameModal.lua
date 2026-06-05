require "ISUI/ISCollapsableWindow"
require "ISUI/ISButton"
require "ISUI/ISLabel"
require "ISUI/ISTextEntryBox"

DC_PlayerFactionNameModal = ISCollapsableWindow:derive("DC_PlayerFactionNameModal")
DC_PlayerFactionNameModal.instance = nil

local function trimName(value)
    return tostring(value or ""):gsub("^%s+", ""):gsub("%s+$", "")
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

function DC_PlayerFactionNameModal:initialise()
    ISCollapsableWindow.initialise(self)
    self:setResizable(false)
end

function DC_PlayerFactionNameModal:createChildren()
    ISCollapsableWindow.createChildren(self)

    local pad = 10
    local th = self:titleBarHeight()
    local contentY = th + pad
    local contentWidth = self.width - (pad * 2)

    self.promptLabel = ISLabel:new(
        pad,
        contentY,
        20,
        tostring(self.promptText or T("DCCommon_UI_Faction_NamePromptChoose", "Choose a faction name.")),
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

    self.nameEntry = ISTextEntryBox:new(tostring(self.defaultValue or ""), pad, contentY + 28, contentWidth, 24)
    self.nameEntry:initialise()
    self.nameEntry:instantiate()
    self:addChild(self.nameEntry)

    self.helpLabel = ISLabel:new(
        pad,
        contentY + 58,
        20,
        T("DCCommon_UI_Faction_NameHint", "Use 1-32 characters."),
        0.75,
        0.75,
        0.75,
        1,
        UIFont.Small,
        true
    )
    self.helpLabel:initialise()
    self.helpLabel:instantiate()
    self:addChild(self.helpLabel)

    self.statusLabel = ISLabel:new(
        pad,
        contentY + 78,
        20,
        "",
        0.95,
        0.62,
        0.62,
        1,
        UIFont.Small,
        true
    )
    self.statusLabel:initialise()
    self.statusLabel:instantiate()
    self:addChild(self.statusLabel)

    self.btnConfirm = ISButton:new(pad, self.height - 38, 100, 24, tostring(self.confirmLabel or T("DCCommon_UI_Faction_Create", "Create")), self, self.onConfirm)
    self.btnConfirm:initialise()
    self.btnConfirm:instantiate()
    self:addChild(self.btnConfirm)

    self.btnCancel = ISButton:new(self.width - 110, self.height - 38, 100, 24, T("DCCommon_UI_Faction_Cancel", "Cancel"), self, self.onCancel)
    self.btnCancel:initialise()
    self.btnCancel:instantiate()
    self:addChild(self.btnCancel)
end

function DC_PlayerFactionNameModal:setStatus(message)
    if self.statusLabel then
        self.statusLabel:setName(tostring(message or ""))
    end
end

function DC_PlayerFactionNameModal:onConfirm()
    local name = trimName(self.nameEntry and self.nameEntry:getText() or "")
    if name == "" then
        self:setStatus(T("DCCommon_UI_Faction_NameEmpty", "Faction name cannot be empty."))
        return
    end
    if #name > 32 then
        self:setStatus(T("DCCommon_UI_Faction_NameTooLong", "Faction name must be 32 characters or less."))
        return
    end

    if self.onConfirmCallback then
        self.onConfirmCallback(name)
    end
    self:close()
end

function DC_PlayerFactionNameModal:onCancel()
    self:close()
end

function DC_PlayerFactionNameModal:close()
    self:setVisible(false)
    self:removeFromUIManager()
    if DC_PlayerFactionNameModal.instance == self then
        DC_PlayerFactionNameModal.instance = nil
    end
end

function DC_PlayerFactionNameModal.Open(args)
    args = args or {}
    if DC_PlayerFactionNameModal.instance then
        DC_PlayerFactionNameModal.instance:close()
    end

    local width = 360
    local height = 180
    local x = (getCore():getScreenWidth() - width) / 2
    local y = (getCore():getScreenHeight() - height) / 2
    local modal = DC_PlayerFactionNameModal:new(x, y, width, height)
    modal.title = tostring(args.title or T("DCCommon_UI_Faction_NameTitle", "Faction Name"))
    modal.promptText = tostring(args.promptText or T("DCCommon_UI_Faction_NamePromptEnter", "Enter a faction name."))
    modal.defaultValue = tostring(args.defaultValue or "")
    modal.confirmLabel = tostring(args.confirmLabel or T("DCCommon_UI_Faction_Create", "Create"))
    modal.onConfirmCallback = args.onConfirm
    modal:initialise()
    modal:instantiate()
    modal:addToUIManager()
    modal:bringToTop()
    if modal.nameEntry and modal.nameEntry.focus then
        modal.nameEntry:focus()
    end
    modal:setStatus("")
    DC_PlayerFactionNameModal.instance = modal
    return modal
end

function DC_PlayerFactionNameModal:new(x, y, width, height)
    local o = ISCollapsableWindow:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.title = T("DCCommon_UI_Faction_NameTitle", "Faction Name")
    o.resizable = false
    o.promptText = T("DCCommon_UI_Faction_NamePromptEnter", "Enter a faction name.")
    o.defaultValue = ""
    o.confirmLabel = T("DCCommon_UI_Faction_Create", "Create")
    o.onConfirmCallback = nil
    return o
end

return DC_PlayerFactionNameModal

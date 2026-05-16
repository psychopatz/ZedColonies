require "ISUI/ISCollapsableWindow"
require "ISUI/ISScrollingListBox"
require "ISUI/ISRichTextPanel"
require "ISUI/ISButton"
require "ISUI/ISTextEntryBox"

DC_BlueprintCraftModal = ISCollapsableWindow:derive("DC_BlueprintCraftModal")
DC_BlueprintCraftModal.instance = DC_BlueprintCraftModal.instance or nil
DC_BlueprintCraftModal.cachedSnapshot = DC_BlueprintCraftModal.cachedSnapshot or nil
DC_BlueprintCraftModal.EventsAdded = DC_BlueprintCraftModal.EventsAdded or false

local function getCommandModule()
    return (DC_Colony and DC_Colony.Config and DC_Colony.Config.COMMAND_MODULE) or "DColony"
end

local function getPlayerObject()
    local config = DC_Colony and DC_Colony.Config or nil
    return config and config.GetPlayerObject and config.GetPlayerObject() or nil
end

local function sendColonyCommand(ownerWindow, command, args)
    if ownerWindow and ownerWindow.sendColonyCommand then
        return ownerWindow:sendColonyCommand(command, args or {})
    end

    local player = getPlayerObject()
    if player and isClient() and not isServer() then
        sendClientCommand(player, getCommandModule(), command, args or {})
        return true
    end

    return false
end

local function formatInput(input)
    local count = math.max(0, math.floor(tonumber(input and input.count) or 0))
    local label = tostring(input and input.displayName or input and input.category or input and input.fullType or "Unknown")
    return tostring(count) .. "x " .. label
end

function DC_BlueprintCraftModal:new(x, y, width, height, options)
    local o = ISCollapsableWindow:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.title = tostring(options and options.title or "Craft")
    o.resizable = true
    o.ownerWindow = options and options.ownerWindow or nil
    o.onRefreshBuildings = options and options.onRefreshBuildings or nil
    o.buildingID = options and options.buildingID or nil
    o.buildingType = tostring(options and options.buildingType or "")
    o.snapshotVersion = nil
    o.selectedBlueprint = nil
    o.statusMessage = ""
    o.minimumWidth = 760
    o.minimumHeight = 480
    return o
end

function DC_BlueprintCraftModal.Open(options)
    local existing = DC_BlueprintCraftModal.instance
    if existing and existing:getIsVisible() then
        existing:close()
    end

    local width = 860
    local height = 560
    local modal = DC_BlueprintCraftModal:new(
        (getCore():getScreenWidth() - width) / 2,
        (getCore():getScreenHeight() - height) / 2,
        width,
        height,
        options or {}
    )
    modal:initialise()
    modal:instantiate()
    modal:addToUIManager()
    modal:setVisible(true)
    DC_BlueprintCraftModal.instance = modal
    modal:updateStatus("Loading researched blueprints...")
    modal:requestSnapshot(true)
    return modal
end

function DC_BlueprintCraftModal:initialise()
    ISCollapsableWindow.initialise(self)
end

function DC_BlueprintCraftModal:createChildren()
    ISCollapsableWindow.createChildren(self)

    local th = self:titleBarHeight()
    self.blueprintList = ISScrollingListBox:new(10, th + 10, math.floor(self.width * 0.42), self.height - th - 92)
    self.blueprintList:initialise()
    self.blueprintList.itemheight = 24
    self.blueprintList.font = UIFont.Small
    self.blueprintList.onmousedown = function(list)
        local row = list.items[list.selected]
        self.selectedBlueprint = row and row.item or nil
        self:updateDetails()
    end
    self:addChild(self.blueprintList)

    self.detailText = ISRichTextPanel:new(self.blueprintList.x + self.blueprintList.width + 10, th + 10, self.width - self.blueprintList.width - 30, self.height - th - 92)
    self.detailText:initialise()
    self.detailText.backgroundColor = { r = 0, g = 0, b = 0, a = 0.08 }
    self.detailText.borderColor = { r = 1, g = 1, b = 1, a = 0.12 }
    self.detailText.clip = true
    self.detailText.autosetheight = false
    self.detailText:addScrollBars()
    self:addChild(self.detailText)

    self.qtyEntry = ISTextEntryBox:new("1", 10, self.height - 42, 70, 24)
    self.qtyEntry:initialise()
    self:addChild(self.qtyEntry)

    self.btnCraft = ISButton:new(88, self.height - 42, 100, 24, "Craft", self, self.onCraftClicked)
    self.btnCraft:initialise()
    self:addChild(self.btnCraft)

    self.btnRefresh = ISButton:new(196, self.height - 42, 90, 24, "Refresh", self, self.onRefreshClicked)
    self.btnRefresh:initialise()
    self:addChild(self.btnRefresh)

    self.statusButton = ISButton:new(294, self.height - 42, self.width - 304, 24, " ", self, function() end)
    self.statusButton:initialise()
    self.statusButton:setEnable(false)
    self:addChild(self.statusButton)
end

function DC_BlueprintCraftModal:onResize()
    ISCollapsableWindow.onResize(self)
    if self.width < self.minimumWidth then
        self:setWidth(self.minimumWidth)
    end
    if self.height < self.minimumHeight then
        self:setHeight(self.minimumHeight)
    end

    local th = self:titleBarHeight()
    self.blueprintList:setHeight(self.height - th - 92)
    self.detailText:setX(self.blueprintList.x + self.blueprintList.width + 10)
    self.detailText:setWidth(self.width - self.blueprintList.width - 30)
    self.detailText:setHeight(self.height - th - 92)
    self.qtyEntry:setY(self.height - 42)
    self.btnCraft:setY(self.height - 42)
    self.btnRefresh:setY(self.height - 42)
    self.statusButton:setY(self.height - 42)
    self.statusButton:setWidth(self.width - 304)
end

function DC_BlueprintCraftModal:updateStatus(message)
    self.statusMessage = tostring(message or " ")
    if self.statusButton then
        self.statusButton:setTitle(self.statusMessage)
    end
end

function DC_BlueprintCraftModal:requestSnapshot(forceRefresh)
    if sendColonyCommand(self.ownerWindow, "RequestResearchSnapshot", {
        knownVersion = forceRefresh == true and nil or self.snapshotVersion,
    }) then
        self:updateStatus("Refreshing blueprint data...")
    end
end

function DC_BlueprintCraftModal:applySnapshot(snapshot, version)
    DC_BlueprintCraftModal.cachedSnapshot = snapshot or {
        blueprints = {},
        queue = {},
        queueCount = 0,
        unlockedCount = 0,
    }
    self.snapshotVersion = version or self.snapshotVersion
    self:rebuildBlueprintList()
    self:updateDetails()
end

function DC_BlueprintCraftModal:rebuildBlueprintList()
    local snapshot = DC_BlueprintCraftModal.cachedSnapshot or {}
    local filtered = {}
    for _, blueprint in ipairs(snapshot.blueprints or {}) do
        if tostring(blueprint and blueprint.buildingType or "") == self.buildingType then
            filtered[#filtered + 1] = blueprint
        end
    end

    self.blueprints = filtered
    self.blueprintList:clear()
    for _, blueprint in ipairs(filtered) do
        self.blueprintList:addItem(tostring(blueprint.displayName or blueprint.fullType or "Blueprint"), blueprint)
    end

    local selectedIndex = nil
    local wanted = tostring(self.selectedBlueprint and self.selectedBlueprint.fullType or "")
    if wanted ~= "" then
        for index, blueprint in ipairs(filtered) do
            if tostring(blueprint and blueprint.fullType or "") == wanted then
                selectedIndex = index
                self.selectedBlueprint = blueprint
                break
            end
        end
    end

    if selectedIndex == nil and filtered[1] then
        selectedIndex = 1
        self.selectedBlueprint = filtered[1]
    end
    self.blueprintList.selected = selectedIndex or -1
end

function DC_BlueprintCraftModal:updateDetails()
    local blueprint = self.selectedBlueprint
    local text = " <RGB:1,1,1> <SIZE:Medium> Station Blueprints <LINE> "
    text = text .. " <RGB:0.72,0.72,0.72> Station: <RGB:1,1,1> " .. tostring(self.buildingType or "Unknown") .. " <LINE> "
    text = text .. " <RGB:0.72,0.72,0.72> Unlocked Here: <RGB:1,1,1> " .. tostring(self.blueprints and #self.blueprints or 0) .. " <LINE> "

    if blueprint then
        text = text .. " <LINE> <RGB:1,1,1> <SIZE:Medium> Selected Blueprint <LINE> "
        text = text .. " <RGB:0.72,0.72,0.72> Item: <RGB:1,1,1> " .. tostring(blueprint.displayName or blueprint.fullType or "Unknown") .. " <LINE> "
        text = text .. " <RGB:0.72,0.72,0.72> Recipe: <RGB:1,1,1> " .. tostring(blueprint.recipeName or "Unknown Recipe") .. " <LINE> "
        text = text .. " <RGB:0.72,0.72,0.72> Output Count: <RGB:1,1,1> " .. tostring(blueprint.outputCount or 1) .. " <LINE> "
        if #(blueprint.inputs or {}) > 0 then
            text = text .. " <RGB:0.72,0.72,0.72> Ingredients: <LINE> "
            for _, input in ipairs(blueprint.inputs or {}) do
                text = text .. " <RGB:0.82,0.82,0.82> - " .. formatInput(input) .. " <LINE> "
            end
        end
        text = text .. " <RGB:0.82,0.82,0.82> Crafting consumes warehouse materials immediately and deposits the finished item into the colony warehouse output. <LINE> "
    else
        text = text .. " <LINE> <RGB:0.62,0.62,0.62> No researched blueprints match this station yet. <LINE> "
    end

    self.detailText:setText(text)
    self.detailText:paginate()
    self.btnCraft:setEnable(blueprint ~= nil)
end

function DC_BlueprintCraftModal:onCraftClicked()
    if not self.selectedBlueprint then
        self:updateStatus("Choose a blueprint first.")
        return
    end

    local qty = math.max(1, math.floor(tonumber(self.qtyEntry and self.qtyEntry:getText() or "1") or 1))
    if sendColonyCommand(self.ownerWindow, "CraftUnlockedBlueprint", {
        buildingID = self.buildingID,
        fullType = self.selectedBlueprint.fullType,
        qty = qty,
    }) then
        self:updateStatus("Crafting " .. tostring(self.selectedBlueprint.displayName or self.selectedBlueprint.fullType or "blueprint") .. "...")
    end
end

function DC_BlueprintCraftModal:onRefreshClicked()
    self:requestSnapshot(true)
end

function DC_BlueprintCraftModal:close()
    self:setVisible(false)
    self:removeFromUIManager()
    if DC_BlueprintCraftModal.instance == self then
        DC_BlueprintCraftModal.instance = nil
    end
end

local function onServerCommand(module, command, args)
    if module ~= getCommandModule() then
        return
    end

    local modal = DC_BlueprintCraftModal.instance
    if not modal or not modal.getIsVisible or not modal:getIsVisible() then
        return
    end

    if command == "SyncResearchSnapshot" then
        if args and args.unchanged ~= true then
            modal:applySnapshot(args.snapshot, args.version)
            modal:updateStatus("Blueprint data synced.")
            if modal.onRefreshBuildings then
                modal.onRefreshBuildings()
            end
        else
            modal.snapshotVersion = args and args.version or modal.snapshotVersion
        end
    elseif command == "ColonyNotice" and args and args.message then
        modal:updateStatus(args.message)
    end
end

if not DC_BlueprintCraftModal.EventsAdded then
    Events.OnServerCommand.Add(onServerCommand)
    DC_BlueprintCraftModal.EventsAdded = true
end

return DC_BlueprintCraftModal

require "ISUI/ISCollapsableWindow"
require "ISUI/ISScrollingListBox"
require "ISUI/ISRichTextPanel"
require "ISUI/ISButton"
require "DC/Common/Colony/Recycler/DC_ColonyRecycler"

DC_RecyclerModal = ISCollapsableWindow:derive("DC_RecyclerModal")
DC_RecyclerModal.instance = DC_RecyclerModal.instance or nil
DC_RecyclerModal.EventsAdded = DC_RecyclerModal.EventsAdded or false

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

function DC_RecyclerModal:new(x, y, width, height, options)
    local o = ISCollapsableWindow:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.title = tostring(options and options.title or "Recycler")
    o.ownerWindow = options and options.ownerWindow or nil
    o.buildingID = options and options.buildingID or nil
    o.statusMessage = ""
    o.minimumWidth = 760
    o.minimumHeight = 500
    o.selectedEntry = nil
    return o
end

function DC_RecyclerModal.Open(options)
    local existing = DC_RecyclerModal.instance
    if existing and existing:getIsVisible() then
        existing:close()
    end

    local width = 860
    local height = 560
    local modal = DC_RecyclerModal:new(
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
    DC_RecyclerModal.instance = modal
    modal:rebuildCandidateList()
    modal:updateDetails()
    modal:updateStatus("Recycler ready.")
    return modal
end

function DC_RecyclerModal:initialise()
    ISCollapsableWindow.initialise(self)
end

function DC_RecyclerModal:createChildren()
    ISCollapsableWindow.createChildren(self)

    local th = self:titleBarHeight()
    self.itemList = ISScrollingListBox:new(10, th + 10, math.floor(self.width * 0.42), self.height - th - 92)
    self.itemList:initialise()
    self.itemList.itemheight = 24
    self.itemList.font = UIFont.Small
    self.itemList.onmousedown = function(list)
        local row = list.items[list.selected]
        self.selectedEntry = row and row.item or nil
        self:updateDetails()
    end
    self:addChild(self.itemList)

    self.detailText = ISRichTextPanel:new(self.itemList.x + self.itemList.width + 10, th + 10, self.width - self.itemList.width - 30, self.height - th - 92)
    self.detailText:initialise()
    self.detailText.backgroundColor = { r = 0, g = 0, b = 0, a = 0.08 }
    self.detailText.borderColor = { r = 1, g = 1, b = 1, a = 0.12 }
    self.detailText.clip = true
    self.detailText.autosetheight = false
    self.detailText:addScrollBars()
    self:addChild(self.detailText)

    self.btnRecycle = ISButton:new(10, self.height - 42, 100, 24, "Recycle", self, self.onRecycleClicked)
    self.btnRecycle:initialise()
    self:addChild(self.btnRecycle)

    self.btnRefresh = ISButton:new(118, self.height - 42, 90, 24, "Refresh", self, self.onRefreshClicked)
    self.btnRefresh:initialise()
    self:addChild(self.btnRefresh)

    self.statusButton = ISButton:new(216, self.height - 42, self.width - 226, 24, " ", self, function() end)
    self.statusButton:initialise()
    self.statusButton:setEnable(false)
    self:addChild(self.statusButton)
end

function DC_RecyclerModal:onResize()
    ISCollapsableWindow.onResize(self)
    if self.width < self.minimumWidth then
        self:setWidth(self.minimumWidth)
    end
    if self.height < self.minimumHeight then
        self:setHeight(self.minimumHeight)
    end

    local th = self:titleBarHeight()
    self.itemList:setHeight(self.height - th - 92)
    self.detailText:setX(self.itemList.x + self.itemList.width + 10)
    self.detailText:setWidth(self.width - self.itemList.width - 30)
    self.detailText:setHeight(self.height - th - 92)
    self.btnRecycle:setY(self.height - 42)
    self.btnRefresh:setY(self.height - 42)
    self.statusButton:setY(self.height - 42)
    self.statusButton:setWidth(self.width - 226)
end

function DC_RecyclerModal:updateStatus(message)
    self.statusMessage = tostring(message or " ")
    if self.statusButton then
        self.statusButton:setTitle(self.statusMessage)
    end
end

function DC_RecyclerModal:rebuildCandidateList()
    local player = getPlayerObject()
    local grouped = {}
    local inventory = player and player.getInventory and player:getInventory() or nil
    local recycler = DC_Colony and DC_Colony.Recycler or nil
    if inventory and inventory.getItems then
        local items = inventory:getItems()
        for index = 0, items:size() - 1 do
            local item = items:get(index)
            if item and item.getFullType and recycler and recycler.BuildRecyclePreview then
                local fullType = tostring(item:getFullType() or "")
                local preview = recycler.BuildRecyclePreview(fullType, DC_Colony and DC_Colony.Config and DC_Colony.Config.GetOwnerUsername and DC_Colony.Config.GetOwnerUsername(player) or nil)
                if preview then
                    local entry = grouped[fullType]
                    if not entry then
                        entry = {
                            fullType = fullType,
                            displayName = item.getDisplayName and item:getDisplayName() or fullType,
                            count = 0,
                            preview = preview,
                            itemRefs = {},
                        }
                        grouped[fullType] = entry
                    end
                    entry.count = entry.count + 1
                    entry.itemRefs[#entry.itemRefs + 1] = {
                        itemID = item:getID(),
                    }
                end
            end
        end
    end

    local entries = {}
    for _, entry in pairs(grouped) do
        entries[#entries + 1] = entry
    end
    table.sort(entries, function(a, b)
        return string.lower(tostring(a and a.displayName or "")) < string.lower(tostring(b and b.displayName or ""))
    end)

    self.entries = entries
    self.itemList:clear()
    for _, entry in ipairs(entries) do
        self.itemList:addItem(tostring(entry.displayName or entry.fullType or "Item") .. " x" .. tostring(entry.count or 0), entry)
    end

    local selectedIndex = nil
    local wanted = tostring(self.selectedEntry and self.selectedEntry.fullType or "")
    if wanted ~= "" then
        for index, entry in ipairs(entries) do
            if tostring(entry and entry.fullType or "") == wanted then
                selectedIndex = index
                self.selectedEntry = entry
                break
            end
        end
    end
    if selectedIndex == nil and entries[1] then
        selectedIndex = 1
        self.selectedEntry = entries[1]
    end
    self.itemList.selected = selectedIndex or -1
    self.btnRecycle:setEnable(self.selectedEntry ~= nil)
end

function DC_RecyclerModal:updateDetails()
    local entry = self.selectedEntry
    local text = " <RGB:1,1,1> <SIZE:Medium> Recycler <LINE> "
    if entry and entry.preview then
        local preview = entry.preview
        text = text .. " <RGB:0.72,0.72,0.72> Item: <RGB:1,1,1> " .. tostring(entry.displayName or entry.fullType or "Unknown") .. " <LINE> "
        text = text .. " <RGB:0.72,0.72,0.72> Recipe: <RGB:1,1,1> " .. tostring(preview.recipeName or "Unknown Recipe") .. " <LINE> "
        text = text .. " <RGB:0.72,0.72,0.72> Built At: <RGB:1,1,1> " .. tostring(preview.buildingDisplayName or preview.buildingType or "Unknown") .. " <LINE> "
        text = text .. " <RGB:0.72,0.72,0.72> Inventory Count: <RGB:1,1,1> " .. tostring(entry.count or 0) .. " <LINE> "
        text = text .. " <RGB:0.72,0.72,0.72> Lead Crafter: <RGB:1,1,1> "
            .. tostring(preview.crafterName ~= "" and preview.crafterName or "None")
            .. " (Craft "
            .. tostring(preview.craftingLevel or 0)
            .. ") <LINE> "
        text = text .. " <RGB:0.72,0.72,0.72> Recovery Chance Per Unit: <RGB:1,1,1> "
            .. tostring(math.floor((tonumber(preview.recoveryChance) or 0) * 100 + 0.5))
            .. "% <LINE> "
        text = text .. " <LINE> <RGB:1,1,1> <SIZE:Medium> Expected Recovery <LINE> "
        if #(preview.expectedRecovered or {}) <= 0 then
            text = text .. " <RGB:0.62,0.62,0.62> No recoverable inputs were resolved for this recipe. <LINE> "
        else
            for _, recovered in ipairs(preview.expectedRecovered or {}) do
                text = text .. " <RGB:0.82,0.82,0.82> - "
                    .. tostring(recovered.count or 0)
                    .. "x "
                    .. tostring(recovered.displayName or "Unknown")
                    .. " <LINE> "
            end
        end
    else
        text = text .. " <RGB:0.62,0.62,0.62> No recyclable crafted items found in your inventory. <LINE> "
    end

    self.detailText:setText(text)
    self.detailText:paginate()
    self.btnRecycle:setEnable(entry ~= nil)
end

function DC_RecyclerModal:onRecycleClicked()
    if not self.selectedEntry then
        self:updateStatus("Choose an item first.")
        return
    end

    local itemRef = self.selectedEntry.itemRefs and self.selectedEntry.itemRefs[1] or nil
    if not itemRef or not itemRef.itemID then
        self:updateStatus("That item is no longer available.")
        self:rebuildCandidateList()
        self:updateDetails()
        return
    end

    if sendColonyCommand(self.ownerWindow, "RecycleInventoryItem", {
        buildingID = self.buildingID,
        itemID = itemRef.itemID,
    }) then
        self:updateStatus("Recycling " .. tostring(self.selectedEntry.displayName or self.selectedEntry.fullType or "item") .. "...")
    end
end

function DC_RecyclerModal:onRefreshClicked()
    self:rebuildCandidateList()
    self:updateDetails()
    self:updateStatus("Recycler list refreshed.")
end

function DC_RecyclerModal:close()
    self:setVisible(false)
    self:removeFromUIManager()
    if DC_RecyclerModal.instance == self then
        DC_RecyclerModal.instance = nil
    end
end

local function onServerCommand(module, command, args)
    if module ~= getCommandModule() then
        return
    end

    local modal = DC_RecyclerModal.instance
    if not modal or not modal.getIsVisible or not modal:getIsVisible() then
        return
    end

    if command == "ColonyNotice" and args and args.message then
        modal:updateStatus(args.message)
        modal:rebuildCandidateList()
        modal:updateDetails()
    end
end

if not DC_RecyclerModal.EventsAdded then
    Events.OnServerCommand.Add(onServerCommand)
    DC_RecyclerModal.EventsAdded = true
end

return DC_RecyclerModal

require "ISUI/ISCollapsableWindow"
require "ISUI/ISScrollingListBox"
require "ISUI/ISRichTextPanel"
require "ISUI/ISButton"

DC_ResearchStationModal = ISCollapsableWindow:derive("DC_ResearchStationModal")
DC_ResearchStationModal.instance = DC_ResearchStationModal.instance or nil
DC_ResearchStationModal.cachedSnapshot = DC_ResearchStationModal.cachedSnapshot or nil
DC_ResearchStationModal.EventsAdded = DC_ResearchStationModal.EventsAdded or false

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
    if not player then
        return false
    end

    if isClient() and not isServer() then
        sendClientCommand(player, getCommandModule(), command, args or {})
        return true
    end

    return false
end

local function canResearchConvertedItem(converted)
    local group = tostring(converted and converted.group or "")
    local category = tostring(converted and converted.category or "")
    if converted == nil or converted.isFallback == true then
        return false
    end
    if group == "Research" or group == "Trade" or group == "Waste" then
        return false
    end
    if category == "Junk"
        or category == "QuestGoods"
        or category == "ContaminatedMaterial"
        or category == "ResearchData"
        or category == "Blueprints"
        or category == "Currency" then
        return false
    end
    return true
end

local function collectInventoryItems(container, grouped)
    if not container or not container.getItems then
        return
    end

    local items = container:getItems()
    if not items then
        return
    end

    for index = 0, items:size() - 1 do
        local item = items:get(index)
        if item and item.getFullType then
            local fullType = tostring(item:getFullType() or "")
            local converted = DC_Colony and DC_Colony.Config and DC_Colony.Config.GetItemCategoryData and DC_Colony.Config.GetItemCategoryData(fullType) or nil
            if fullType ~= "" and canResearchConvertedItem(converted) then
                local key = fullType
                local existing = grouped[key]
                local count = math.max(1, math.floor(tonumber(item.getCount and item:getCount() or 1) or 1))
                if not existing then
                    existing = {
                        fullType = fullType,
                        displayName = item.getDisplayName and item:getDisplayName() or fullType,
                        category = tostring(converted and converted.category or ""),
                        group = tostring(converted and converted.group or ""),
                        count = 0,
                        itemRefs = {},
                    }
                    grouped[key] = existing
                end
                existing.count = existing.count + count
                existing.itemRefs[#existing.itemRefs + 1] = {
                    itemID = item:getID(),
                    count = count,
                }
            end

            if instanceof(item, "InventoryContainer") then
                collectInventoryItems(item:getItemContainer(), grouped)
            end
        end
    end
end

local function buildCandidateList()
    local player = getPlayerObject()
    local grouped = {}
    if player and player.getInventory then
        collectInventoryItems(player:getInventory(), grouped)
    end

    local entries = {}
    for _, entry in pairs(grouped) do
        entries[#entries + 1] = entry
    end
    table.sort(entries, function(a, b)
        local aName = string.lower(tostring(a and a.displayName or a and a.fullType or ""))
        local bName = string.lower(tostring(b and b.displayName or b and b.fullType or ""))
        if aName == bName then
            return tostring(a and a.fullType or "") < tostring(b and b.fullType or "")
        end
        return aName < bName
    end)
    return entries
end

local function formatQueueLabel(entry)
    local progressRatio = math.max(0, math.min(1, tonumber(entry and entry.progressRatio) or 0))
    return tostring(entry and entry.displayName or entry and entry.fullType or "Research")
        .. " ("
        .. tostring(math.floor((progressRatio * 100) + 0.5))
        .. "%)"
end

local function layoutChildren(self)
    if not self then
        return
    end

    local margin = 10
    local top = 32
    local footerHeight = 66
    local contentHeight = math.max(120, self.height - top - footerHeight - margin)
    local listWidth = 250
    local queueX = margin + listWidth + margin
    local detailX = queueX + listWidth + margin
    local detailWidth = math.max(180, self.width - detailX - margin)
    local footerY = self.height - footerHeight

    if self.candidateList then
        self.candidateList:setX(margin)
        self.candidateList:setY(top)
        self.candidateList:setWidth(listWidth)
        self.candidateList:setHeight(contentHeight)
    end
    if self.queueList then
        self.queueList:setX(queueX)
        self.queueList:setY(top)
        self.queueList:setWidth(listWidth)
        self.queueList:setHeight(contentHeight)
    end
    if self.detailText then
        self.detailText:setX(detailX)
        self.detailText:setY(top)
        self.detailText:setWidth(detailWidth)
        self.detailText:setHeight(contentHeight)
    end
    if self.btnSubmit then
        self.btnSubmit:setX(margin)
        self.btnSubmit:setY(footerY)
    end
    if self.btnRefresh then
        self.btnRefresh:setX(128)
        self.btnRefresh:setY(footerY)
    end
    if self.statusButton then
        self.statusButton:setX(226)
        self.statusButton:setY(footerY)
        self.statusButton:setWidth(math.max(180, self.width - 236))
    end
end

function DC_ResearchStationModal:initialise()
    ISCollapsableWindow.initialise(self)
end

function DC_ResearchStationModal:createChildren()
    ISCollapsableWindow.createChildren(self)

    self.candidateList = ISScrollingListBox:new(10, 32, 250, self.height - 110)
    self.candidateList:initialise()
    self.candidateList.itemheight = 24
    self.candidateList.font = UIFont.Small
    self.candidateList.onmousedown = function(list)
        local item = list.items[list.selected]
        self.selectedCandidate = item and item.item or nil
        self.selectedQueue = nil
        self:updateDetailText()
    end
    self:addChild(self.candidateList)

    self.queueList = ISScrollingListBox:new(270, 32, 250, self.height - 110)
    self.queueList:initialise()
    self.queueList.itemheight = 24
    self.queueList.font = UIFont.Small
    self.queueList.onmousedown = function(list)
        local item = list.items[list.selected]
        self.selectedQueue = item and item.item or nil
        self.selectedCandidate = nil
        self:updateDetailText()
    end
    self:addChild(self.queueList)

    self.detailText = ISRichTextPanel:new(530, 32, self.width - 540, self.height - 110)
    self.detailText:initialise()
    self.detailText.backgroundColor = { r = 0, g = 0, b = 0, a = 0.15 }
    self.detailText.borderColor = { r = 1, g = 1, b = 1, a = 0.08 }
    self.detailText.clip = true
    self.detailText.autosetheight = false
    self.detailText:addScrollBars()
    self:addChild(self.detailText)

    self.btnSubmit = ISButton:new(10, self.height - 66, 110, 26, "Submit Item", self, self.onSubmitClicked)
    self.btnSubmit:initialise()
    self:addChild(self.btnSubmit)

    self.btnRefresh = ISButton:new(128, self.height - 66, 90, 26, "Refresh", self, self.onRefreshClicked)
    self.btnRefresh:initialise()
    self:addChild(self.btnRefresh)

    self.statusButton = ISButton:new(226, self.height - 66, 294, 26, "", self, function() end)
    self.statusButton:initialise()
    self.statusButton:setEnable(false)
    self:addChild(self.statusButton)

    layoutChildren(self)
    self:rebuildCandidateList()
    self:refreshFromSnapshot()
end

function DC_ResearchStationModal:rebuildCandidateList()
    self.candidates = buildCandidateList()
    if not self.candidateList then
        return
    end

    self.candidateList:clear()
    for _, entry in ipairs(self.candidates or {}) do
        self.candidateList:addItem(
            tostring(entry.displayName or entry.fullType or "Item")
                .. " x"
                .. tostring(entry.count or 0)
                .. " ["
                .. tostring(entry.category or "")
                .. "]",
            entry
        )
    end

    local selectedIndex = nil
    local wantedFullType = tostring(self.selectedCandidate and self.selectedCandidate.fullType or "")
    if wantedFullType ~= "" then
        for index, entry in ipairs(self.candidates or {}) do
            if tostring(entry and entry.fullType or "") == wantedFullType then
                selectedIndex = index
                self.selectedCandidate = entry
                break
            end
        end
    end

    if selectedIndex == nil and self.candidates[1] and not self.selectedQueue then
        selectedIndex = 1
        self.selectedCandidate = self.candidates[1]
    end

    if selectedIndex then
        self.candidateList.selected = selectedIndex
    else
        self.selectedCandidate = nil
        self.candidateList.selected = -1
    end
end

function DC_ResearchStationModal:refreshQueueList()
    local snapshot = self.snapshot or DC_ResearchStationModal.cachedSnapshot or nil
    if not self.queueList then
        return
    end

    self.queueList:clear()
    for _, entry in ipairs(snapshot and snapshot.queue or {}) do
        self.queueList:addItem(formatQueueLabel(entry), entry)
    end

    local wanted = tostring(self.selectedQueue and self.selectedQueue.jobID or "")
    if self.selectedQueue and self.queueList.items and #self.queueList.items > 0 then
        for index, row in ipairs(self.queueList.items) do
            if tostring(row and row.item and row.item.jobID or "") == wanted then
                self.queueList.selected = index
                self.selectedQueue = row.item
                return
            end
        end
    end

    if #self.queueList.items > 0 and not self.selectedCandidate then
        self.queueList.selected = 1
        self.selectedQueue = self.queueList.items[1] and self.queueList.items[1].item or nil
    else
        self.selectedQueue = nil
    end
end

function DC_ResearchStationModal:updateStatus(text)
    self.statusText = tostring(text or "")
    if self.statusButton then
        self.statusButton:setTitle(self.statusText ~= "" and self.statusText or " ")
    end
end

function DC_ResearchStationModal:updateDetailText()
    if not self.detailText then
        return
    end

    local snapshot = self.snapshot or DC_ResearchStationModal.cachedSnapshot or {}
    local text = ""
    text = text .. " <RGB:1,1,1> <SIZE:Medium> Research Station <LINE> "
    text = text .. " <RGB:0.72,0.72,0.72> Queue: <RGB:1,1,1> " .. tostring(snapshot.queueCount or 0) .. " <LINE> "
    text = text .. " <RGB:0.72,0.72,0.72> Unlocked Blueprints: <RGB:1,1,1> " .. tostring(snapshot.unlockedCount or 0) .. " <LINE> "

    if self.selectedCandidate then
        text = text .. " <LINE> <RGB:1,1,1> <SIZE:Medium> Selected Specimen <LINE> "
        text = text .. " <RGB:0.72,0.72,0.72> Item: <RGB:1,1,1> " .. tostring(self.selectedCandidate.displayName or self.selectedCandidate.fullType or "Unknown") .. " <LINE> "
        text = text .. " <RGB:0.72,0.72,0.72> Category: <RGB:1,1,1> " .. tostring(self.selectedCandidate.category or "") .. " <LINE> "
        text = text .. " <RGB:0.72,0.72,0.72> In Inventory: <RGB:1,1,1> " .. tostring(self.selectedCandidate.count or 0) .. " <LINE> "
        text = text .. " <RGB:0.82,0.82,0.82> Submit one item as a physical specimen. Researchers will keep it in colony storage while reverse engineering runs. <LINE> "
    elseif self.selectedQueue then
        text = text .. " <LINE> <RGB:1,1,1> <SIZE:Medium> Active Queue Entry <LINE> "
        text = text .. " <RGB:0.72,0.72,0.72> Item: <RGB:1,1,1> " .. tostring(self.selectedQueue.displayName or self.selectedQueue.fullType or "Unknown") .. " <LINE> "
        text = text .. " <RGB:0.72,0.72,0.72> Progress: <RGB:1,1,1> "
            .. tostring(math.floor((tonumber(self.selectedQueue.progressHours) or 0) + 0.5))
            .. " / "
            .. tostring(math.floor((tonumber(self.selectedQueue.requiredHours) or 0) + 0.5))
            .. " hours <LINE> "
    end

    text = text .. " <LINE> <RGB:1,1,1> <SIZE:Medium> Unlocked Blueprint Preview <LINE> "
    if #(snapshot.blueprints or {}) <= 0 then
        text = text .. " <RGB:0.62,0.62,0.62> No blueprints unlocked yet. <LINE> "
    else
        for index = 1, math.min(12, #(snapshot.blueprints or {})) do
            local blueprint = snapshot.blueprints[index]
            text = text .. " <RGB:0.82,0.82,0.82> - "
                .. tostring(blueprint.displayName or blueprint.fullType or "Blueprint")
                .. " <RGB:0.72,0.72,0.72>("
                .. tostring(blueprint.buildingType or "Workshop")
                .. ") <LINE> "
        end
    end

    self.detailText:setText(text)
    self.detailText:paginate()
end

function DC_ResearchStationModal:refreshFromSnapshot()
    self.snapshot = DC_ResearchStationModal.cachedSnapshot or self.snapshot or {
        queue = {},
        blueprints = {},
        queueCount = 0,
        unlockedCount = 0,
    }
    self:refreshQueueList()
    self:updateDetailText()
end

function DC_ResearchStationModal:requestSnapshot(forceRefresh)
    local knownVersion = forceRefresh == true and nil or (self.snapshotVersion or nil)
    if sendColonyCommand(self.ownerWindow, "RequestResearchSnapshot", {
        knownVersion = knownVersion,
    }) then
        self:updateStatus(forceRefresh == true and "Refreshing research data..." or "Requesting research data...")
    end
end

function DC_ResearchStationModal:onSubmitClicked()
    if not self.selectedCandidate then
        self:updateStatus("Select a research specimen first.")
        return
    end

    local firstRef = self.selectedCandidate.itemRefs and self.selectedCandidate.itemRefs[1] or nil
    if not firstRef or not firstRef.itemID then
        self:updateStatus("That specimen is no longer available.")
        self:rebuildCandidateList()
        self:updateDetailText()
        return
    end

    if sendColonyCommand(self.ownerWindow, "SubmitResearchSpecimen", {
        buildingID = self.buildingID,
        itemID = firstRef.itemID,
        fullType = self.selectedCandidate.fullType,
    }) then
        self.pendingBuildingRefresh = true
        self:updateStatus("Submitting " .. tostring(self.selectedCandidate.displayName or self.selectedCandidate.fullType or "item") .. " for research...")
        self:requestSnapshot(true)
    else
        self:updateStatus("Unable to submit that specimen right now.")
    end
end

function DC_ResearchStationModal:onRefreshClicked()
    self:rebuildCandidateList()
    self:requestSnapshot(true)
end

function DC_ResearchStationModal:onResize()
    ISCollapsableWindow.onResize(self)
    layoutChildren(self)
    self:updateDetailText()
end

function DC_ResearchStationModal:close()
    self:setVisible(false)
    self:removeFromUIManager()
    if DC_ResearchStationModal.instance == self then
        DC_ResearchStationModal.instance = nil
    end
end

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
    return o
end

function DC_ResearchStationModal.Open(options)
    local existing = DC_ResearchStationModal.instance
    if existing and existing:getIsVisible() then
        existing:close()
    end

    local width = 940
    local height = 560
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

local function onServerCommand(module, command, args)
    if module ~= getCommandModule() then
        return
    end

    local modal = DC_ResearchStationModal.instance
    if not modal or not modal.getIsVisible or not modal:getIsVisible() then
        return
    end

    if command == "SyncResearchSnapshot" then
        if args and args.unchanged ~= true then
            DC_ResearchStationModal.cachedSnapshot = args.snapshot or {
                queue = {},
                blueprints = {},
                queueCount = 0,
                unlockedCount = 0,
            }
            modal.snapshotVersion = args.version or modal.snapshotVersion
            modal:rebuildCandidateList()
            modal:refreshFromSnapshot()
            modal:updateStatus("Research data synced.")
            if modal.pendingBuildingRefresh == true then
                modal.pendingBuildingRefresh = false
                if modal.onRefreshBuildings then
                    modal.onRefreshBuildings()
                end
            end
        else
            modal.snapshotVersion = args and args.version or modal.snapshotVersion
            modal:updateStatus("Research data already up to date.")
        end
    elseif command == "ColonyNotice" and args and args.message then
        modal:updateStatus(args.message)
    end
end

if not DC_ResearchStationModal.EventsAdded then
    Events.OnServerCommand.Add(onServerCommand)
    DC_ResearchStationModal.EventsAdded = true
end

return DC_ResearchStationModal

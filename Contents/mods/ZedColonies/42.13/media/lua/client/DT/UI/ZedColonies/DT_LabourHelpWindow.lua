require "ISUI/ISCollapsableWindow"
require "ISUI/ISRichTextPanel"

DT_LabourHelpWindow = ISCollapsableWindow:derive("DT_LabourHelpWindow")
DT_LabourHelpWindow.instance = DT_LabourHelpWindow.instance or nil

local function buildHelpText()
    return table.concat({
        " <RGB:1,1,1> <SIZE:Large> Scavenge System Guide <LINE> <LINE> ",
        " <RGB:0.78,0.78,0.78> The scavenging job now follows four layers: ",
        "<RGB:1,1,1> site, capability, efficiency, and haul weight. <LINE> <LINE> ",

        " <RGB:1,1,1> <SIZE:Medium> 1. Site Profile <LINE> ",
        " <RGB:0.78,0.78,0.78> The assigned work site decides what kind of loot is even possible. ",
        "Houses lean toward food, clothing, books, and household parts. Warehouses lean toward materials and hardware. ",
        "Pharmacies, gun stores, and electronics areas bias their own loot pools. <LINE> <LINE> ",

        " <RGB:1,1,1> <SIZE:Medium> 2. Capability Unlocks <LINE> ",
        " <RGB:0.78,0.78,0.78> Tools do not directly spawn rare loot. Instead they unlock which sub-pools the worker can reach. <LINE> ",
        " <RGB:0.88,0.88,0.88> Access tools: <RGB:0.78,0.78,0.78> crowbar, screwdriver, sledgehammer. These open locked or secured locations. <LINE> ",
        " <RGB:0.88,0.88,0.88> Extraction tools: <RGB:0.78,0.78,0.78> hammer, saw, pipe wrench, propane torch, welding mask. These unlock dismantle and salvage pools. <LINE> ",
        " <RGB:0.88,0.88,0.88> Hauling tools: <RGB:0.78,0.78,0.78> bags, garbage bags, sandbags, rope. These improve quantity and carrying efficiency. <LINE> ",
        " <RGB:0.88,0.88,0.88> Utility tools: <RGB:0.78,0.78,0.78> flashlight, map, pen. These improve speed and reduce bad rolls. <LINE> <LINE> ",

        " <RGB:1,1,1> <SIZE:Medium> 3. Scavenge Tiers <LINE> ",
        " <RGB:0.78,0.78,0.78> Tier 0: open containers only. <LINE> ",
        " <RGB:0.78,0.78,0.78> Tier 1: locked entry and general goods. <LINE> ",
        " <RGB:0.78,0.78,0.78> Tier 2: stripping furniture and raw materials. <LINE> ",
        " <RGB:0.78,0.78,0.78> Tier 3: secure stores, industrial salvage, and high-value pools. <LINE> <LINE> ",

        " <RGB:1,1,1> <SIZE:Medium> 4. Search Efficiency <LINE> ",
        " <RGB:0.78,0.78,0.78> Flashlights improve dark-site search speed. Maps and pens help avoid duplicate pool picks. ",
        "Bags and bulk tools increase how much can be brought back, but they do not make loot magically better. ",
        "The scavenge bar tracks total work needed for the next loot roll, while speed decides how quickly that work is completed. <LINE> <LINE> ",

        " <RGB:1,1,1> <SIZE:Medium> 5. Trip Flow and Carry Weight <LINE> ",
        " <RGB:0.78,0.78,0.78> Scavengers now run finite trips. They leave ",
        "<RGB:1,1,1> Home <RGB:0.78,0.78,0.78> go ",
        "<RGB:1,1,1> Away <RGB:0.78,0.78,0.78> to the site, spend time ",
        "<RGB:1,1,1> Scavenging <RGB:0.78,0.78,0.78> there, then travel ",
        "<RGB:1,1,1> Away <RGB:0.78,0.78,0.78> back home to store the haul. <LINE> ",
        " <RGB:0.78,0.78,0.78> Found loot first goes into the worker's carried haul. When the pack is full, supplies run low, or you call them back, the trip ends and they head home with what they found. <LINE> ",
        " <RGB:0.88,0.88,0.88> Auto Repeat: <RGB:0.78,0.78,0.78> if enabled, the scavenger will head out again after unloading and restocking, but only when provisions, tools, and warehouse space are ready. <LINE> ",
        " <RGB:0.88,0.88,0.88> Important: <RGB:0.78,0.78,0.78> only the active haul is weight-limited. Provisions and equipment are not counted toward haul weight. <LINE> ",
        " <RGB:0.88,0.88,0.88> Body carry limit: <RGB:0.78,0.78,0.78> controlled by worker archetype and the Labour sandbox carry-weight setting. <LINE> ",
        " <RGB:0.88,0.88,0.88> Container reduction: <RGB:0.78,0.78,0.78> bags apply their capacity and weight reduction before leftover weight hits the body limit. <LINE> <LINE> ",

        " <RGB:1,1,1> <SIZE:Medium> Practical Tips <LINE> ",
        " <RGB:0.78,0.78,0.78> Pair crowbar plus flashlight for reliable house runs. <LINE> ",
        " <RGB:0.78,0.78,0.78> Use hammer plus saw when you want building materials. <LINE> ",
        " <RGB:0.78,0.78,0.78> Use torch plus welding mask for warehouse and industrial salvage. <LINE> ",
        " <RGB:0.78,0.78,0.78> Give scavengers backpacks or duffels if you want longer runs before they have to come home. <LINE> ",
        " <RGB:0.78,0.78,0.78> If you want all workers to carry more before returning, raise the Labour sandbox carry-weight setting. <LINE> <LINE> ",

        " <RGB:1,1,1> UI Reading Tips <LINE> ",
        " <RGB:0.78,0.78,0.78> In worker details, compare ",
        "<RGB:1,1,1> Carry Load <RGB:0.78,0.78,0.78> against ",
        "<RGB:1,1,1> Base Carry Limit <RGB:0.78,0.78,0.78> and ",
        "<RGB:1,1,1> Raw Carry Allowance <RGB:0.78,0.78,0.78> to see how much the worker is benefiting from bags. <LINE> ",
        " <RGB:0.78,0.78,0.78> In the supply window, the Haul tab shows what has already been stored at home and is ready to collect. <LINE> "
    }, "")
end

function DT_LabourHelpWindow:initialise()
    ISCollapsableWindow.initialise(self)
    self:setResizable(true)
    self.minimumWidth = 560
    self.minimumHeight = 420
end

function DT_LabourHelpWindow:createChildren()
    ISCollapsableWindow.createChildren(self)

    local pad = 10
    local th = self:titleBarHeight()
    local contentY = th + pad
    local contentW = self.width - (pad * 2)
    local contentH = self.height - contentY - pad

    self.helpText = ISRichTextPanel:new(pad, contentY, contentW, contentH)
    self.helpText:initialise()
    self.helpText.backgroundColor = { r = 0, g = 0, b = 0, a = 0.2 }
    self.helpText.borderColor = { r = 1, g = 1, b = 1, a = 0.08 }
    self.helpText.autosetheight = false
    self.helpText.clip = true
    self.helpText:setMargins(8, 8, 8, 8)
    self.helpText:addScrollBars()
    self.helpText:setAnchorLeft(true)
    self.helpText:setAnchorRight(true)
    self.helpText:setAnchorTop(true)
    self.helpText:setAnchorBottom(true)
    self.helpText:setText(buildHelpText())
    self.helpText:paginate()
    self:addChild(self.helpText)
end

function DT_LabourHelpWindow:onResize()
    ISCollapsableWindow.onResize(self)
    if not self.helpText then
        return
    end

    local pad = 10
    local th = self:titleBarHeight()
    local contentY = th + pad
    self.helpText:setX(pad)
    self.helpText:setY(contentY)
    self.helpText:setWidth(self.width - (pad * 2))
    self.helpText:setHeight(self.height - contentY - pad)
    self.helpText.textDirty = true
    self.helpText:paginate()
    if self.helpText.vscroll then
        self.helpText.vscroll:setHeight(self.helpText:getHeight())
    end
end

function DT_LabourHelpWindow:close()
    self:setVisible(false)
    self:removeFromUIManager()
end

function DT_LabourHelpWindow.Open()
    if DT_LabourHelpWindow.instance then
        DT_LabourHelpWindow.instance:setVisible(true)
        DT_LabourHelpWindow.instance:addToUIManager()
        DT_LabourHelpWindow.instance:bringToTop()
        return DT_LabourHelpWindow.instance
    end

    local width = 680
    local height = 620
    local x = (getCore():getScreenWidth() - width) / 2
    local y = (getCore():getScreenHeight() - height) / 2

    local window = DT_LabourHelpWindow:new(x, y, width, height)
    window:initialise()
    window:instantiate()
    window.title = "Scavenge Help"
    window:setVisible(true)
    window:addToUIManager()
    window:bringToTop()

    DT_LabourHelpWindow.instance = window
    return window
end

return DT_LabourHelpWindow

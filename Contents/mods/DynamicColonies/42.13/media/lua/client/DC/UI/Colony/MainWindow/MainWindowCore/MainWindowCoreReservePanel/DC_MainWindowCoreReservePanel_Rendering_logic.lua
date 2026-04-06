DC_MainWindow = DC_MainWindow or {}
DC_MainWindow.Internal = DC_MainWindow.Internal or {}

local Internal = DC_MainWindow.Internal
Internal.ReservePanel = Internal.ReservePanel or {}
local ReservePanel = Internal.ReservePanel

local ColonyProfileCard = ReservePanel.ColonyProfileCard
local TEXTURE_CACHE = ReservePanel.TextureCache or {}
ReservePanel.TextureCache = TEXTURE_CACHE

local function isValidTexture(tex)
    return tex and tex.getName and tex:getName() ~= "Question_Highlight"
end

local function tryTexture(textureName)
    if not textureName or textureName == "" then
        return nil
    end

    local tex = getTexture(textureName)
    if isValidTexture(tex) then
        return tex
    end

    return nil
end

local function resolveInventoryItemTexture(item)
    if not item then
        return nil
    end

    if item.getTex then
        local tex = item:getTex()
        if isValidTexture(tex) then
            return tex
        end
    end

    if item.getTexture then
        local tex = item:getTexture()
        if isValidTexture(tex) then
            return tex
        end
    end

    return nil
end

local function getTextureForFullType(fullType)
    if not fullType then
        return nil
    end

    if TEXTURE_CACHE[fullType] ~= nil then
        return TEXTURE_CACHE[fullType] or nil
    end

    local texture = nil
    if DC_SupplyWindow and DC_SupplyWindow.Internal and DC_SupplyWindow.Internal.getTextureForFullType then
        texture = DC_SupplyWindow.Internal.getTextureForFullType(fullType)
    end

    local script = getScriptManager and getScriptManager():getItem(fullType) or nil
    if not isValidTexture(texture) and script and script.getIcon then
        local iconName = script:getIcon()
        if iconName and iconName ~= "" then
            texture = tryTexture("Item_" .. tostring(iconName))
                or tryTexture(tostring(iconName))
                or tryTexture("media/textures/Item_" .. tostring(iconName) .. ".png")
        end
    end

    if not isValidTexture(texture) and InventoryItemFactory and InventoryItemFactory.CreateItem then
        local ok, item = pcall(InventoryItemFactory.CreateItem, fullType)
        if ok and item then
            texture = resolveInventoryItemTexture(item)
        end
    end

    TEXTURE_CACHE[fullType] = isValidTexture(texture) and texture or false
    return TEXTURE_CACHE[fullType] or nil
end

function ReservePanel.animateRatio(currentValue, targetValue)
    local current = tonumber(currentValue) or 0
    local target = tonumber(targetValue) or 0
    local delta = target - current
    if math.abs(delta) < 0.01 then
        return target
    end
    return current + (delta * 0.18)
end

function ColonyProfileCard:drawReserveBar(x, y, width, height, label, color, data, displayRatio)
    local safeData = data or { stored = 0, usage = 0, carryover = 0, provisionReserve = 0, daysLeft = nil }
    local tm = getTextManager()
    self:drawRect(x, y, width, height, 0.35, 0.08, 0.08, 0.08)
    self:drawRectBorder(x, y, width, height, 0.2, 1, 1, 1)

    local fillWidth = math.floor((width - 4) * math.max(0, math.min(1, displayRatio or 0)))
    if fillWidth > 0 then
        self:drawRect(x + 2, y + 2, fillWidth, height - 4, 0.9, color.r, color.g, color.b)
    end

    local labelWidth = tm:MeasureStringX(UIFont.Small, label)
    self:drawText(label, x + math.max(8, (width - labelWidth) / 2), y + 2, 0.95, 0.95, 0.95, 1, UIFont.Small)

    if safeData.treatmentActive and safeData.treatmentItemFullType then
        local iconTex = getTextureForFullType(safeData.treatmentItemFullType)
        local overlayText = tostring(safeData.treatmentOverlayText or "")
        local overlayWidth = overlayText ~= "" and tm:MeasureStringX(UIFont.Small, overlayText) or 0
        local iconSize = math.max(12, height - 6)
        local iconGap = 4
        local iconX = x + width - iconSize - 8
        local iconY = y + math.floor((height - iconSize) / 2)

        if overlayText ~= "" then
            self:drawText(
                overlayText,
                iconX - overlayWidth - iconGap,
                y + 2,
                0.58,
                0.96,
                0.58,
                1,
                UIFont.Small
            )
        end

        if iconTex then
            self:drawTextureScaled(iconTex, iconX, iconY, iconSize, iconSize, 1, 1, 1, 1)
        end
    end

    local daysText = safeData.captionText or ReservePanel.formatDaysAndEta(safeData.daysLeft, safeData.daysLeft and (safeData.daysLeft * 24) or nil)
    local totalsText = safeData.summaryText
        or ("Reserve " .. ReservePanel.formatReserveValue(safeData.provisionReserve or safeData.stored)
            .. " | Carryover " .. ReservePanel.formatReserveValue(safeData.carryover or safeData.overflow or 0))
    self:drawText(daysText, x, y + height + 4, 0.86, 0.86, 0.86, 1, UIFont.Small)
    self:drawTextRight(totalsText, x + width, y + height + 4, 0.66, 0.66, 0.66, 1, UIFont.Small)
end

function ColonyProfileCard:storeDisplayState()
    if not self.worker then
        return
    end

    local workerID = tostring(self.worker.workerID or "")
    if workerID == "" then
        return
    end

    self.workerDisplayCache[workerID] = {
        calories = self.caloriesDisplayRatio,
        hydration = self.hydrationDisplayRatio,
        health = self.healthDisplayRatio,
        energy = self.energyDisplayRatio,
        activity = self.activityDisplayRatio
    }
end

function ColonyProfileCard:prerender()
    ISPanel.prerender(self)

    local pad = 12
    local actionButtonHeight = (self.btnInventory and self.btnInventory:getHeight()) or 24
    local actionButtonGap = self.btnInventory and 8 or 0
    local actionButtonCount = 0
    if self.btnInventory then
        actionButtonCount = actionButtonCount + 1
    end
    if self.btnCharacter then
        actionButtonCount = actionButtonCount + 1
    end
    if not self.worker then
        self:drawTextCentre("Select a worker to inspect labour reserves and daily upkeep.", self.width / 2, self.height / 2 - 8, 0.65, 0.65, 0.65, 0.9, UIFont.Medium)
        return
    end

    self.caloriesDisplayRatio = ReservePanel.animateRatio(self.caloriesDisplayRatio, self.caloriesTargetRatio)
    self.hydrationDisplayRatio = ReservePanel.animateRatio(self.hydrationDisplayRatio, self.hydrationTargetRatio)
    self.healthDisplayRatio = ReservePanel.animateRatio(self.healthDisplayRatio, self.healthTargetRatio)
    self.energyDisplayRatio = ReservePanel.animateRatio(self.energyDisplayRatio, self.energyTargetRatio)
    self.activityDisplayRatio = ReservePanel.animateRatio(self.activityDisplayRatio, self.activityTargetRatio)
    self:storeDisplayState()

    local portraitSize = math.min(
        104,
        self.height - (pad * 2) - (actionButtonCount * actionButtonHeight) - (math.max(0, actionButtonCount - 1) * actionButtonGap) - 12
    )
    portraitSize = math.max(72, portraitSize)
    local portraitX = pad
    local portraitY = pad + 10
    local barsX = portraitX + portraitSize + 18
    local barsWidth = self.width - barsX - pad
    local barHeight = 24
    local topY = pad
    local worker = self.worker
    local profile = self.profile or {}

    self:drawText(tostring(worker.name or "Worker"), barsX, topY, 0.95, 0.97, 1, 1, UIFont.Large)
    topY = topY + 24
    local jobLabel = ReservePanel.getJobDisplayName(worker, profile)
    local stateLabel = ReservePanel.getWorkerStateLabel(worker)
    local separator = " | "
    local tm = getTextManager()
    local jobColor = ReservePanel.getWorkerJobColor(worker, profile)
    self:drawText(jobLabel, barsX, topY, jobColor.r, jobColor.g, jobColor.b, jobColor.a or 1, UIFont.Small)
    self:drawText(separator, barsX + tm:MeasureStringX(UIFont.Small, jobLabel), topY, 0.68, 0.8, 1, 1, UIFont.Small)
    self:drawText(
        stateLabel,
        barsX + tm:MeasureStringX(UIFont.Small, jobLabel .. separator),
        topY,
        0.68,
        0.8,
        1,
        1,
        UIFont.Small
    )
    topY = topY + 38

    self:drawRect(portraitX, portraitY, portraitSize, portraitSize, 0.08, 1, 1, 1)
    if self.portraitTex then
        self:drawTextureScaled(self.portraitTex, portraitX + 3, portraitY + 3, portraitSize - 6, portraitSize - 6, 1, 1, 1, 1)
    end
    self:drawRectBorder(portraitX, portraitY, portraitSize, portraitSize, 0.25, 1, 1, 1)

    if self.btnInventory then
        self.btnInventory:setX(portraitX)
        self.btnInventory:setY(portraitY + portraitSize + 8)
        self.btnInventory:setWidth(portraitSize)
        self.btnInventory:setHeight(actionButtonHeight)
    end

    local nextButtonY = portraitY + portraitSize + 8 + actionButtonHeight + 6
    if self.btnCharacter then
        self.btnCharacter:setX(portraitX)
        self.btnCharacter:setY(nextButtonY)
        self.btnCharacter:setWidth(portraitSize)
        self.btnCharacter:setHeight(actionButtonHeight)
        nextButtonY = nextButtonY + actionButtonHeight + 6
    end
    if self.ownerWindow and self.ownerWindow.btnCycleJob then
        self.ownerWindow.btnCycleJob:setX(portraitX)
        self.ownerWindow.btnCycleJob:setY(nextButtonY)
        self.ownerWindow.btnCycleJob:setWidth(portraitSize)
        self.ownerWindow.btnCycleJob:setHeight(actionButtonHeight)
    end

    self:drawReserveBar(
        barsX,
        topY,
        barsWidth,
        barHeight,
        "Health",
        { r = 0.74, g = 0.24, b = 0.24 },
        self.healthData,
        self.healthDisplayRatio
    )

    topY = topY + 44

    self:drawReserveBar(
        barsX,
        topY,
        barsWidth,
        barHeight,
        "Hunger",
        { r = 0.48, g = 0.30, b = 0.14 },
        self.caloriesData,
        self.caloriesDisplayRatio
    )

    topY = topY + 44

    self:drawReserveBar(
        barsX,
        topY,
        barsWidth,
        barHeight,
        "Hydration",
        { r = 0.36, g = 0.74, b = 1.00 },
        self.hydrationData,
        self.hydrationDisplayRatio
    )

    topY = topY + 44

    if self.activityData then
        self:drawReserveBar(
            barsX,
            topY,
            barsWidth,
            barHeight,
            tostring(self.activityData.displayText or self.activityData.label or "Working"),
            self.activityData.color or { r = 0.78, g = 0.78, b = 0.78 },
            self.activityData,
            self.activityDisplayRatio
        )
    end
end

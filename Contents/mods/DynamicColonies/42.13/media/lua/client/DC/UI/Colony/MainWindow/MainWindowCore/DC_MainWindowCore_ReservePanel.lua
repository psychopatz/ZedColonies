require "DC/UI/Colony/MainWindow/MainWindowCore/DC_MainWindowCore_Bootstrap"
require "DC/UI/Colony/MainWindow/MainWindowCore/DC_MainWindowCore_Formatters"
require "DC/UI/Colony/MainWindow/MainWindowCore/DC_MainWindowCore_ReserveData"
require "DC/UI/Colony/MainWindow/MainWindowCore/DC_MainWindowCore_WorkerPresentation"
require "DC/Common/Colony/ColonyConfig/DC_ColonyConfig"
require "DC/Common/Colony/ColonyEnergy/DC_ColonyEnergy"

DC_MainWindow = DC_MainWindow or {}
DC_MainWindow.Internal = DC_MainWindow.Internal or {}

local Internal = DC_MainWindow.Internal
local ColonyProfileCard = ISPanel:derive("ColonyProfileCard")

local function getConfig()
    return Internal.Config or DC_Colony and DC_Colony.Config or {}
end

local function isFunction(value)
    return type(value) == "function"
end

local function formatReserveValue(value)
    if Internal.formatReserveValue then
        return Internal.formatReserveValue(value)
    end
    return tostring(math.floor((tonumber(value) or 0) + 0.5))
end

local function getJobDisplayName(worker, profile)
    if Internal.getJobDisplayName then
        return Internal.getJobDisplayName(worker, profile)
    end
    return tostring(worker and worker.jobType or profile and profile.displayName or "Unassigned")
end

local function getWorkerStateLabel(worker)
    if Internal.getWorkerStateLabel then
        return Internal.getWorkerStateLabel(worker)
    end
    return tostring(worker and worker.state or "Idle")
end

local function formatDaysAndEta(daysValue, hoursValue)
    if Internal.formatDaysAndEta then
        return Internal.formatDaysAndEta(daysValue, hoursValue)
    end
    if daysValue == nil then
        return "No estimate"
    end
    if hoursValue ~= nil then
        return string.format("%.1f days | %.1fh", math.max(0, tonumber(daysValue) or 0), math.max(0, tonumber(hoursValue) or 0))
    end
    return string.format("%.1f days", math.max(0, tonumber(daysValue) or 0))
end

local function buildFallbackReserveData(currentAmount, maxAmount, summaryText, captionText)
    local safeMax = math.max(1, tonumber(maxAmount) or 100)
    local safeCurrent = math.max(0, math.min(safeMax, tonumber(currentAmount) or 0))
    return {
        stored = safeCurrent,
        usage = safeMax,
        fillRatio = safeCurrent / safeMax,
        overflow = 0,
        daysLeft = nil,
        summaryText = tostring(summaryText or (tostring(math.floor(safeCurrent + 0.5)) .. " / " .. tostring(math.floor(safeMax + 0.5)))),
        captionText = tostring(captionText or "")
    }
end

local function buildReserveBarData(storedAmount, dailyNeed)
    local stored = math.max(0, tonumber(storedAmount) or 0)
    local usage = math.max(0, tonumber(dailyNeed) or 0)
    if usage <= 0 then
        return {
            stored = stored,
            usage = usage,
            fillRatio = 0,
            overflow = 0,
            daysLeft = nil
        }
    end

    local rawRatio = stored / usage
    return {
        stored = stored,
        usage = usage,
        fillRatio = math.max(0, math.min(1, rawRatio)),
        overflow = math.max(0, stored - usage),
        daysLeft = math.max(0, rawRatio)
    }
end

local function buildNutritionBarData(unitLabel, currentBufferAmount, carryoverAmount, provisionReserveAmount, dailyNeed)
    if isFunction(Internal.getNutritionBarData) then
        return Internal.getNutritionBarData(unitLabel, currentBufferAmount, carryoverAmount, provisionReserveAmount, dailyNeed)
    end

    local unitName = tostring(unitLabel or "Nutrition")
    local currentBuffer = math.max(0, tonumber(currentBufferAmount) or 0)
    local carryover = math.max(0, tonumber(carryoverAmount) or 0)
    local provisionReserve = math.max(0, tonumber(provisionReserveAmount) or 0)
    local data = buildReserveBarData(currentBuffer, dailyNeed)
    data.carryover = carryover
    data.provisionReserve = provisionReserve
    data.currentBuffer = currentBuffer
    if tonumber(dailyNeed) and tonumber(dailyNeed) > 0 then
        data.daysLeft = math.max(0, (currentBuffer + carryover + provisionReserve) / tonumber(dailyNeed))
    end
    data.summaryText = unitName .. " Reserve " .. formatReserveValue(provisionReserve)
        .. " | Carryover " .. formatReserveValue(carryover)
    return data
end

local function buildHealthBarData(currentHp, maxHp)
    if isFunction(Internal.getHealthBarData) then
        return Internal.getHealthBarData(currentHp, maxHp)
    end

    local safeMax = math.max(1, tonumber(maxHp) or 100)
    local safeCurrent = math.max(0, math.min(safeMax, tonumber(currentHp) or safeMax))
    return {
        stored = safeCurrent,
        usage = safeMax,
        fillRatio = safeCurrent / safeMax,
        overflow = 0,
        daysLeft = nil,
        captionText = safeCurrent <= 0 and "dead" or "current hp",
        summaryText = formatReserveValue(safeCurrent) .. " / " .. formatReserveValue(safeMax)
    }
end

local function buildWorkerProgressData(worker, profile)
    if isFunction(Internal.getWorkerProgressData) then
        return Internal.getWorkerProgressData(worker, profile)
    end

    local interaction = DC_Colony and DC_Colony.Interaction or nil
    if not interaction or not isFunction(interaction.GetProgressDescriptor) then
        return nil
    end

    local data = interaction.GetProgressDescriptor(worker, profile)
    if not data then
        return nil
    end

    data.stored = tonumber(data.progressAmount) or tonumber(data.progressHours) or 0
    data.usage = tonumber(data.workTarget) or tonumber(data.cycleHours) or 0
    data.overflow = 0
    data.daysLeft = nil
    return data
end

local function getWorkerPortraitTexture(worker)
    if isFunction(Internal.getWorkerPortraitTexture) then
        return Internal.getWorkerPortraitTexture(worker)
    end
    if not worker then
        return nil
    end

    local archetype = tostring(worker.archetypeID or "General")
    local gender = worker.isFemale and "Female" or "Male"
    local seed = tonumber(worker.identitySeed) or 1
    local portraitID = 1
    local pathFolder = "media/ui/Portraits/" .. archetype .. "/" .. gender .. "/"

    if DynamicTrading and DynamicTrading.Portraits then
        if isFunction(DynamicTrading.Portraits.GetMappedID) then
            portraitID = DynamicTrading.Portraits.GetMappedID(archetype, gender, seed)
        end
        if isFunction(DynamicTrading.Portraits.GetPathFolder) then
            pathFolder = DynamicTrading.Portraits.GetPathFolder(archetype, gender)
        end
    end

    return getTexture(pathFolder .. tostring(portraitID) .. ".png")
        or getTexture("media/ui/Portraits/General/" .. gender .. "/1.png")
end

function ColonyProfileCard:new(x, y, width, height)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.backgroundColor = { r = 0, g = 0, b = 0, a = 0.18 }
    o.borderColor = { r = 1, g = 1, b = 1, a = 0.08 }
    o.caloriesDisplayRatio = 0
    o.hydrationDisplayRatio = 0
    o.healthDisplayRatio = 0
    o.energyDisplayRatio = 0
    o.activityDisplayRatio = 0
    o.workerDisplayCache = {}
    return o
end

function ColonyProfileCard:initialise()
    ISPanel.initialise(self)

    self.btnInventory = ISButton:new(0, 0, 96, 24, "Inventory", self, self.onOpenInventory)
    self.btnInventory:initialise()
    self.btnInventory:setEnable(false)
    self:addChild(self.btnInventory)

    self.btnCharacter = ISButton:new(0, 0, 96, 24, "Character", self, self.onOpenCharacter)
    self.btnCharacter:initialise()
    self.btnCharacter:setEnable(false)
    self:addChild(self.btnCharacter)
end

function ColonyProfileCard:setOwnerWindow(window)
    self.ownerWindow = window
end

function ColonyProfileCard:onOpenInventory()
    if self.ownerWindow and self.ownerWindow.onOpenInventory then
        self.ownerWindow:onOpenInventory()
    end
end

function ColonyProfileCard:onOpenCharacter()
    if self.ownerWindow and self.ownerWindow.onOpenCharacter then
        self.ownerWindow:onOpenCharacter()
    end
end

function ColonyProfileCard:setWorker(worker)
    self.worker = worker
    local config = getConfig()
    self.profile = worker and isFunction(config.GetJobProfile) and config.GetJobProfile(worker.jobType) or nil
    if not worker then
        self.portraitTex = nil
        self.caloriesData = nil
        self.hydrationData = nil
        self.healthData = nil
        self.energyData = nil
        self.activityData = nil
        self.caloriesTargetRatio = 0
        self.hydrationTargetRatio = 0
        self.healthTargetRatio = 0
        self.energyTargetRatio = 0
        self.activityTargetRatio = 0
        if self.btnInventory then
            self.btnInventory:setEnable(false)
        end
        if self.btnCharacter then
            self.btnCharacter:setEnable(false)
        end
        return
    end

    if self.btnInventory then
        self.btnInventory:setEnable(true)
    end
    if self.btnCharacter then
        self.btnCharacter:setEnable(true)
    end

    local profile = self.profile or {}
    local config = getConfig()
    local dailyCaloriesNeed = isFunction(config.GetEffectiveDailyCaloriesNeed) and config.GetEffectiveDailyCaloriesNeed(worker, profile)
        or tonumber(worker.dailyCaloriesNeed)
        or tonumber(profile.dailyCaloriesNeed)
        or 0
    local dailyHydrationNeed = isFunction(config.GetEffectiveDailyHydrationNeed) and config.GetEffectiveDailyHydrationNeed(worker, profile)
        or tonumber(worker.dailyHydrationNeed)
        or tonumber(profile.dailyHydrationNeed)
        or 0
    local carryoverCalories = math.max(0, tonumber(worker.carryoverCalories) or tonumber(worker.caloriesOverflow) or 0)
    local carryoverHydration = math.max(0, tonumber(worker.carryoverHydration) or tonumber(worker.hydrationOverflow) or 0)
    local provisionCalories = math.max(0, tonumber(worker.provisionCaloriesReserve) or tonumber(worker.storedCalories) or 0)
    local provisionHydration = math.max(0, tonumber(worker.provisionHydrationReserve) or tonumber(worker.storedHydration) or 0)
    local currentCaloriesBuffer = math.max(0, tonumber(worker.currentCaloriesBuffer) or tonumber(worker.caloriesCached) or 0)
    local currentHydrationBuffer = math.max(0, tonumber(worker.currentHydrationBuffer) or tonumber(worker.hydrationCached) or 0)

    self.caloriesData = buildNutritionBarData("Calories", currentCaloriesBuffer, carryoverCalories, provisionCalories, dailyCaloriesNeed)
    self.hydrationData = buildNutritionBarData("Hydration", currentHydrationBuffer, carryoverHydration, provisionHydration, dailyHydrationNeed)
    self.healthData = buildHealthBarData(worker.hp, worker.maxHp)
    self.energyData = DC_Colony and DC_Colony.Energy and isFunction(DC_Colony.Energy.GetBarData)
        and DC_Colony.Energy.GetBarData(worker) or nil
    self.activityData = buildWorkerProgressData(worker, profile)
    self.caloriesTargetRatio = self.caloriesData.fillRatio
    self.hydrationTargetRatio = self.hydrationData.fillRatio
    self.healthTargetRatio = self.healthData.fillRatio
    self.energyTargetRatio = self.energyData and self.energyData.fillRatio or 0
    self.activityTargetRatio = self.activityData and self.activityData.fillRatio or 0
    self.portraitTex = getWorkerPortraitTexture(worker)

    local workerID = tostring(worker.workerID or "")
    local cachedRatios = self.workerDisplayCache[workerID]
    if cachedRatios then
        self.caloriesDisplayRatio = tonumber(cachedRatios.calories) or self.caloriesTargetRatio
        self.hydrationDisplayRatio = tonumber(cachedRatios.hydration) or self.hydrationTargetRatio
        self.healthDisplayRatio = tonumber(cachedRatios.health) or self.healthTargetRatio
        self.energyDisplayRatio = tonumber(cachedRatios.energy) or self.energyTargetRatio
        self.activityDisplayRatio = tonumber(cachedRatios.activity) or self.activityTargetRatio
        return
    end

    self.caloriesDisplayRatio = self.caloriesTargetRatio
    self.hydrationDisplayRatio = self.hydrationTargetRatio
    self.healthDisplayRatio = self.healthTargetRatio
    self.energyDisplayRatio = self.energyTargetRatio
    self.activityDisplayRatio = self.activityTargetRatio
end

local function animateRatio(currentValue, targetValue)
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
    self:drawRect(x, y, width, height, 0.35, 0.08, 0.08, 0.08)
    self:drawRectBorder(x, y, width, height, 0.2, 1, 1, 1)

    local fillWidth = math.floor((width - 4) * math.max(0, math.min(1, displayRatio or 0)))
    if fillWidth > 0 then
        self:drawRect(x + 2, y + 2, fillWidth, height - 4, 0.9, color.r, color.g, color.b)
    end

    local labelWidth = getTextManager():MeasureStringX(UIFont.Small, label)
    self:drawText(label, x + math.max(8, (width - labelWidth) / 2), y + 2, 0.95, 0.95, 0.95, 1, UIFont.Small)

    local daysText = safeData.captionText or formatDaysAndEta(safeData.daysLeft, safeData.daysLeft and (safeData.daysLeft * 24) or nil)
    local totalsText = safeData.summaryText
        or ("Reserve " .. formatReserveValue(safeData.provisionReserve or safeData.stored)
            .. " | Carryover " .. formatReserveValue(safeData.carryover or safeData.overflow or 0))
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

    self.caloriesDisplayRatio = animateRatio(self.caloriesDisplayRatio, self.caloriesTargetRatio)
    self.hydrationDisplayRatio = animateRatio(self.hydrationDisplayRatio, self.hydrationTargetRatio)
    self.healthDisplayRatio = animateRatio(self.healthDisplayRatio, self.healthTargetRatio)
    self.energyDisplayRatio = animateRatio(self.energyDisplayRatio, self.energyTargetRatio)
    self.activityDisplayRatio = animateRatio(self.activityDisplayRatio, self.activityTargetRatio)
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
    self:drawText(
        getJobDisplayName(worker, profile) .. " | " .. getWorkerStateLabel(worker),
        barsX,
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

Internal.ColonyReservePanel = ColonyProfileCard

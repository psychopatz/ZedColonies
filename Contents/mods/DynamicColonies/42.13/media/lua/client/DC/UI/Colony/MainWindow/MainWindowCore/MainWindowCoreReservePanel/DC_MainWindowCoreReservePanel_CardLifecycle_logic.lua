DC_MainWindow = DC_MainWindow or {}
DC_MainWindow.Internal = DC_MainWindow.Internal or {}

local Internal = DC_MainWindow.Internal
Internal.ReservePanel = Internal.ReservePanel or {}
local ReservePanel = Internal.ReservePanel

ReservePanel.ColonyProfileCard = ReservePanel.ColonyProfileCard or ISPanel:derive("ColonyProfileCard")
local ColonyProfileCard = ReservePanel.ColonyProfileCard

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
    local config = ReservePanel.getConfig()
    self.profile = worker and ReservePanel.isFunction(config.GetJobProfile) and config.GetJobProfile(worker.jobType) or nil
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
    config = ReservePanel.getConfig()
    local dailyCaloriesNeed = ReservePanel.isFunction(config.GetEffectiveDailyCaloriesNeed) and config.GetEffectiveDailyCaloriesNeed(worker, profile)
        or tonumber(worker.dailyCaloriesNeed)
        or tonumber(profile.dailyCaloriesNeed)
        or 0
    local dailyHydrationNeed = ReservePanel.isFunction(config.GetEffectiveDailyHydrationNeed) and config.GetEffectiveDailyHydrationNeed(worker, profile)
        or tonumber(worker.dailyHydrationNeed)
        or tonumber(profile.dailyHydrationNeed)
        or 0
    local carryoverCalories = math.max(0, tonumber(worker.carryoverCalories) or tonumber(worker.caloriesOverflow) or 0)
    local carryoverHydration = math.max(0, tonumber(worker.carryoverHydration) or tonumber(worker.hydrationOverflow) or 0)
    local provisionCalories = math.max(0, tonumber(worker.provisionCaloriesReserve) or tonumber(worker.storedCalories) or 0)
    local provisionHydration = math.max(0, tonumber(worker.provisionHydrationReserve) or tonumber(worker.storedHydration) or 0)
    local currentCaloriesBuffer = math.max(0, tonumber(worker.currentCaloriesBuffer) or tonumber(worker.caloriesCached) or 0)
    local currentHydrationBuffer = math.max(0, tonumber(worker.currentHydrationBuffer) or tonumber(worker.hydrationCached) or 0)

    self.caloriesData = ReservePanel.buildNutritionBarData("Calories", currentCaloriesBuffer, carryoverCalories, provisionCalories, dailyCaloriesNeed)
    self.hydrationData = ReservePanel.buildNutritionBarData("Hydration", currentHydrationBuffer, carryoverHydration, provisionHydration, dailyHydrationNeed)
    self.healthData = ReservePanel.buildHealthBarData(worker.hp, worker.maxHp, worker)
    self.energyData = DC_Colony and DC_Colony.Energy and ReservePanel.isFunction(DC_Colony.Energy.GetBarData)
        and DC_Colony.Energy.GetBarData(worker) or nil
    self.activityData = ReservePanel.buildWorkerProgressData(worker, profile)
    self.caloriesTargetRatio = self.caloriesData.fillRatio
    self.hydrationTargetRatio = self.hydrationData.fillRatio
    self.healthTargetRatio = self.healthData.fillRatio
    self.energyTargetRatio = self.energyData and self.energyData.fillRatio or 0
    self.activityTargetRatio = self.activityData and self.activityData.fillRatio or 0
    self.portraitTex = ReservePanel.getWorkerPortraitTexture(worker)

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

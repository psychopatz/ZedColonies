DC_Colony = DC_Colony or {}
DC_Colony.Resources = DC_Colony.Resources or {}
DC_Colony.Resources.Internal = DC_Colony.Resources.Internal or {}

local Buildings = DC_Buildings
local Resources = DC_Colony.Resources
local Internal = Resources.Internal

function Resources.GetWaterCapacity(ownerUsername)
    local owner = Internal.GetAuthorityOwner(ownerUsername)
    local total = 0

    for _, instance in ipairs(Buildings.GetBuildingsForOwner and Buildings.GetBuildingsForOwner(owner) or {}) do
        local buildingType = tostring(instance and instance.buildingType or "")
        if math.floor(tonumber(instance and instance.level) or 0) > 0 then
            if buildingType == "WaterCollector" then
                total = total + Internal.GetWaterCollectorBaseCapacity(instance)
            elseif buildingType == "WaterTank" then
                total = total + Internal.GetWaterTankCapacity(instance)
            end
        end
    end

    return math.max(0, math.floor(total + 0.5))
end

function Resources.GetWaterStored(ownerUsername)
    local owner = Internal.GetAuthorityOwner(ownerUsername)
    local ownerData = Resources.EnsureOwner(owner)
    local capacity = Resources.GetWaterCapacity(owner)
    return math.max(0, math.min(capacity, tonumber(ownerData and ownerData.waterStored) or 0))
end

function Resources.GetWaterAvailableCapacity(ownerUsername)
    local capacity = Resources.GetWaterCapacity(ownerUsername)
    return math.max(0, capacity - Resources.GetWaterStored(ownerUsername))
end

function Resources.AddWaterStored(ownerUsername, amount)
    local owner = Internal.GetAuthorityOwner(ownerUsername)
    local requested = math.max(0, tonumber(amount) or 0)
    if requested <= 0 then
        return 0
    end

    local ownerData = Resources.EnsureOwner(owner)
    local capacity = Resources.GetWaterCapacity(owner)
    local stored = math.max(0, math.min(capacity, tonumber(ownerData and ownerData.waterStored) or 0))
    local accepted = math.max(0, math.min(requested, capacity - stored))
    if accepted <= 0 then
        return 0
    end

    ownerData.waterStored = stored + accepted
    Resources.Save(owner)
    return accepted
end

function Resources.GetWaterCollectionRatePerHour(ownerUsername)
    local owner = Internal.GetAuthorityOwner(ownerUsername)
    local total = 0

    for _, instance in ipairs(Buildings.GetBuildingsForOwner and Buildings.GetBuildingsForOwner(owner) or {}) do
        if tostring(instance and instance.buildingType or "") == "WaterCollector" and math.floor(tonumber(instance and instance.level) or 0) > 0 then
            local rate = Internal.GetWaterCollectorBaseRate(instance)
            local installRate = 0
            for _, definition in ipairs(Buildings.Config.GetInstallDefinitionList and Buildings.Config.GetInstallDefinitionList("WaterCollector") or {}) do
                local count = Buildings.GetBuildingInstallCount and Buildings.GetBuildingInstallCount(instance, definition.installKey) or 0
                local perInstall = math.max(0, tonumber(definition and definition.effects and definition.effects.waterCollectionRateBonus) or 0)
                installRate = installRate + (count * perInstall)
            end
            total = total + rate + installRate
        end
    end

    return math.max(0, total)
end

function Resources.GetGreenhouseDailyWaterDemand(ownerUsername)
    local owner = Internal.GetAuthorityOwner(ownerUsername)
    local total = 0
    Resources.NormalizeGreenhouseStates(owner)

    for _, instance in ipairs(Buildings.GetBuildingsForOwner and Buildings.GetBuildingsForOwner(owner) or {}) do
        if tostring(instance and instance.buildingType or "") == "Greenhouse" and math.floor(tonumber(instance and instance.level) or 0) > 0 then
            local state = Internal.GetGreenhouseState(owner, instance.buildingID)
            local perSlot = Resources.GetGreenhouseWaterPerDayForLevel(instance.level)
            for _, slot in ipairs(state and state.slots or {}) do
                if slot.cropID and slot.state ~= "Dead" and slot.state ~= "Empty" then
                    total = total + perSlot
                end
            end
        end
    end

    return math.max(0, total)
end

function Resources.GetBuildingMetrics(ownerUsername, instance)
    if type(instance) ~= "table" then
        return {}
    end

    if tostring(instance.buildingType or "") == "WaterCollector" then
        local barrelInstalls = {}
        local barrelInstallCount = 0
        local installRate = 0

        for _, definition in ipairs(Buildings.Config.GetInstallDefinitionList and Buildings.Config.GetInstallDefinitionList("WaterCollector") or {}) do
            local count = Buildings.GetBuildingInstallCount and Buildings.GetBuildingInstallCount(instance, definition.installKey) or 0
            barrelInstalls[definition.installKey] = count
            barrelInstallCount = barrelInstallCount + count
            installRate = installRate + (count * math.max(0, tonumber(definition and definition.effects and definition.effects.waterCollectionRateBonus) or 0))
        end

        return {
            waterStorageContribution = Internal.GetWaterCollectorBaseCapacity(instance),
            waterCollectionRateContribution = Internal.GetWaterCollectorBaseRate(instance) + installRate,
            barrelInstallCount = barrelInstallCount,
            barrelInstalls = barrelInstalls
        }
    end

    if tostring(instance.buildingType or "") == "WaterTank" then
        return {
            waterStorageContribution = Internal.GetWaterTankCapacity(instance)
        }
    end

    if tostring(instance.buildingType or "") == "Greenhouse" then
        local state = Internal.GetGreenhouseState(ownerUsername, instance.buildingID)
        local activeSlots = 0
        for _, slot in ipairs(state and state.slots or {}) do
            if slot.cropID and slot.state ~= "Dead" and slot.state ~= "Empty" then
                activeSlots = activeSlots + 1
            end
        end

        return {
            greenhouseSlotCount = Resources.GetGreenhouseSlotCountForLevel(instance.level),
            greenhouseActiveSlots = activeSlots,
            greenhouseThermostatC = state and state.thermostatC or 20,
            greenhouseDailyWaterUse = activeSlots * Resources.GetGreenhouseWaterPerDayForLevel(instance.level)
        }
    end

    return {}
end

DC_Colony = DC_Colony or {}
DC_Colony.Resources = DC_Colony.Resources or {}
DC_Colony.Resources.Internal = DC_Colony.Resources.Internal or {}

local Buildings = DC_Buildings
local Resources = DC_Colony.Resources
local Internal = Resources.Internal

function Internal.BuildGreenhouseSlotSnapshot(slot)
    local crop = slot and slot.cropID and Resources.CROP_CATALOG[slot.cropID] or nil
    local growthHours = crop and math.max(1, tonumber(crop.growthHours) or 1) or 1
    local progress = crop and math.max(0, math.min(1, (tonumber(slot and slot.growthHours) or 0) / growthHours)) or 0
    return {
        slotIndex = tonumber(slot and slot.slotIndex) or 0,
        state = tostring(slot and slot.state or "Empty"),
        cropID = crop and crop.cropID or nil,
        displayName = crop and crop.displayName or "Empty Slot",
        seedFullType = slot and slot.seedFullType or nil,
        growthHours = math.max(0, tonumber(slot and slot.growthHours) or 0),
        growthHoursRequired = growthHours,
        growthPercent = progress,
        health = math.max(0, math.floor((tonumber(slot and slot.health) or 0) + 0.5)),
        tempMinC = crop and crop.tempMinC or nil,
        tempMaxC = crop and crop.tempMaxC or nil,
        produceFullType = crop and crop.produceFullType or nil,
        produceDisplayName = crop and Internal.GetDisplayName(crop.produceFullType) or nil
    }
end

function Resources.GetGreenhouseSnapshots(ownerUsername)
    local owner = Internal.GetAuthorityOwner(ownerUsername)
    Resources.NormalizeGreenhouseStates(owner)
    local snapshots = {}

    for _, instance in ipairs(Buildings.GetBuildingsForOwner and Buildings.GetBuildingsForOwner(owner) or {}) do
        if tostring(instance and instance.buildingType or "") == "Greenhouse" and math.floor(tonumber(instance and instance.level) or 0) > 0 then
            local state = Internal.GetGreenhouseState(owner, instance.buildingID)
            local slots = {}
            local activeSlots = 0
            for _, slot in ipairs(state and state.slots or {}) do
                local snapshot = Internal.BuildGreenhouseSlotSnapshot(slot)
                if snapshot.cropID and snapshot.state ~= "Dead" and snapshot.state ~= "Empty" then
                    activeSlots = activeSlots + 1
                end
                slots[#slots + 1] = snapshot
            end

            snapshots[#snapshots + 1] = {
                buildingID = instance.buildingID,
                displayName = "Greenhouse",
                plotX = math.floor(tonumber(instance.plotX) or 0),
                plotY = math.floor(tonumber(instance.plotY) or 0),
                level = math.floor(tonumber(instance.level) or 0),
                thermostatC = state and state.thermostatC or 20,
                slotCount = Resources.GetGreenhouseSlotCountForLevel(instance.level),
                activeSlotCount = activeSlots,
                waterPerDayPerSlot = Resources.GetGreenhouseWaterPerDayForLevel(instance.level),
                dailyWaterUse = activeSlots * Resources.GetGreenhouseWaterPerDayForLevel(instance.level),
                slots = slots
            }
        end
    end

    table.sort(snapshots, function(a, b)
        if tonumber(a.plotY) == tonumber(b.plotY) then
            return tonumber(a.plotX) < tonumber(b.plotX)
        end
        return tonumber(a.plotY) < tonumber(b.plotY)
    end)

    return snapshots
end

function Resources.GetClientSnapshot(ownerUsername)
    local owner = Internal.GetAuthorityOwner(ownerUsername)
    local ownerData = Resources.NormalizeGreenhouseStates(owner)
    local capacity = Resources.GetWaterCapacity(owner)
    ownerData.waterStored = math.min(capacity, math.max(0, tonumber(ownerData.waterStored) or 0))

    local raining, rainIntensity = Internal.GetRainState()
    local baseRate = Resources.GetWaterCollectionRatePerHour(owner)
    local activeRate = raining and (baseRate * math.max(0.25, rainIntensity)) or 0
    local greenhouses = Resources.GetGreenhouseSnapshots(owner)
    local dailyDemand = Resources.GetGreenhouseDailyWaterDemand(owner)
    local collectors = {}
    local tanks = {}

    for _, instance in ipairs(Buildings.GetBuildingsForOwner and Buildings.GetBuildingsForOwner(owner) or {}) do
        if math.floor(tonumber(instance and instance.level) or 0) > 0 then
            local metrics = Resources.GetBuildingMetrics(owner, instance)
            if tostring(instance.buildingType or "") == "WaterCollector" then
                collectors[#collectors + 1] = {
                    buildingID = instance.buildingID,
                    plotX = math.floor(tonumber(instance.plotX) or 0),
                    plotY = math.floor(tonumber(instance.plotY) or 0),
                    storageBonus = metrics.waterStorageContribution or 0,
                    collectionRate = metrics.waterCollectionRateContribution or 0,
                    barrelInstallCount = metrics.barrelInstallCount or 0
                }
            elseif tostring(instance.buildingType or "") == "WaterTank" then
                tanks[#tanks + 1] = {
                    buildingID = instance.buildingID,
                    plotX = math.floor(tonumber(instance.plotX) or 0),
                    plotY = math.floor(tonumber(instance.plotY) or 0),
                    storageBonus = metrics.waterStorageContribution or 0
                }
            end
        end
    end

    return {
        ownerUsername = owner,
        categories = {
            {
                id = "Water",
                displayName = "Water",
                placeholder = false,
                metric = tostring(math.floor(ownerData.waterStored + 0.5)) .. " / " .. tostring(capacity),
                status = raining and "Collecting" or "Stable"
            },
            {
                id = "Electricity",
                displayName = "Electricity",
                placeholder = true,
                metric = "Placeholder",
                status = "Coming Soon"
            },
            {
                id = "Ammo",
                displayName = "Ammo",
                placeholder = true,
                metric = "Placeholder",
                status = "Coming Soon"
            },
            {
                id = "Medicine",
                displayName = "Medicine",
                placeholder = true,
                metric = "Placeholder",
                status = "Coming Soon"
            },
            {
                id = "Scrap",
                displayName = "Scrap",
                placeholder = true,
                metric = "Placeholder",
                status = "Coming Soon"
            }
        },
        water = {
            stored = ownerData.waterStored,
            capacity = capacity,
            available = math.max(0, capacity - ownerData.waterStored),
            baseCollectionRatePerHour = baseRate,
            activeCollectionRatePerHour = activeRate,
            raining = raining,
            rainIntensity = rainIntensity,
            outdoorTemperatureC = Internal.GetOutdoorTemperatureC(),
            dailyDemand = dailyDemand,
            collectors = collectors,
            tanks = tanks,
            greenhouses = greenhouses
        }
    }
end

function Resources.GetAnyGreenhouseLabel(ownerUsername)
    for _, greenhouse in ipairs(Resources.GetGreenhouseSnapshots(ownerUsername)) do
        return "Greenhouse " .. tostring(greenhouse.plotX) .. "," .. tostring(greenhouse.plotY)
    end
    return "Greenhouse"
end
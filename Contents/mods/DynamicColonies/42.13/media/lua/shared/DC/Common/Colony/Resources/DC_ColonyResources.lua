require "DC/Common/Colony/ColonyConfig/DC_ColonyConfig"
require "DC/Common/Colony/ColonyRegistry/DC_ColonyRegistry"
require "DC/Common/Buildings/Core/DC_Buildings"

DC_Colony = DC_Colony or {}
DC_Colony.Resources = DC_Colony.Resources or {}
DC_Colony.Resources.Internal = DC_Colony.Resources.Internal or {}

local Config = DC_Colony.Config
local Registry = DC_Colony.Registry
local Buildings = DC_Buildings
local Resources = DC_Colony.Resources
local Internal = Resources.Internal

local RESOURCE_SCHEMA_VERSION = 1

Resources.CROP_CATALOG = Resources.CROP_CATALOG or {
    Cabbage = {
        cropID = "Cabbage",
        displayName = "Cabbage",
        seedFullTypes = { "Base.CabbageSeed", "Base.CabbageBagSeed2" },
        produceFullType = "Base.Cabbage",
        growthHours = 292,
        tempMinC = 12,
        tempMaxC = 22,
        harvestMin = 2,
        harvestMax = 4
    },
    Broccoli = {
        cropID = "Broccoli",
        displayName = "Broccoli",
        seedFullTypes = { "Base.BroccoliSeed", "Base.BroccoliBagSeed2" },
        produceFullType = "Base.Broccoli",
        growthHours = 292,
        tempMinC = 14,
        tempMaxC = 22,
        harvestMin = 2,
        harvestMax = 4
    },
    Carrot = {
        cropID = "Carrot",
        displayName = "Carrot",
        seedFullTypes = { "Base.CarrotSeed", "Base.CarrotBagSeed2" },
        produceFullType = "Base.Carrots",
        growthHours = 432,
        tempMinC = 10,
        tempMaxC = 20,
        harvestMin = 3,
        harvestMax = 6
    },
    Potato = {
        cropID = "Potato",
        displayName = "Potato",
        seedFullTypes = { "Base.PotatoSeed", "Base.PotatoBagSeed2" },
        produceFullType = "Base.Potato",
        growthHours = 432,
        tempMinC = 8,
        tempMaxC = 18,
        harvestMin = 3,
        harvestMax = 4
    },
    Radish = {
        cropID = "Radish",
        displayName = "Radish",
        seedFullTypes = { "Base.RedRadishSeed", "Base.RedRadishBagSeed2" },
        produceFullType = "Base.RedRadish",
        growthHours = 144,
        tempMinC = 10,
        tempMaxC = 18,
        harvestMin = 4,
        harvestMax = 9
    },
    Strawberry = {
        cropID = "Strawberry",
        displayName = "Strawberry",
        seedFullTypes = { "Base.StrewberrieSeed", "Base.StrewberrieBagSeed2" },
        produceFullType = "Base.Strewberrie",
        growthHours = 360,
        tempMinC = 14,
        tempMaxC = 24,
        harvestMin = 4,
        harvestMax = 6
    },
    Tomato = {
        cropID = "Tomato",
        displayName = "Tomato",
        seedFullTypes = { "Base.TomatoSeed", "Base.TomatoBagSeed2" },
        produceFullType = "Base.Tomato",
        growthHours = 360,
        tempMinC = 18,
        tempMaxC = 28,
        harvestMin = 4,
        harvestMax = 5
    },
    BellPepper = {
        cropID = "BellPepper",
        displayName = "Bell Pepper",
        seedFullTypes = { "Base.BellPepperSeed", "Base.BellPepperBagSeed" },
        produceFullType = "Base.BellPepper",
        growthHours = 292,
        tempMinC = 18,
        tempMaxC = 28,
        harvestMin = 2,
        harvestMax = 4
    }
}

Internal.SeedToCropID = Internal.SeedToCropID or nil

local function clampNumber(value, minimum, maximum)
    local safeValue = tonumber(value) or 0
    if safeValue < minimum then
        return minimum
    end
    if safeValue > maximum then
        return maximum
    end
    return safeValue
end

local function copyTable(source)
    local copy = {}
    for key, value in pairs(source or {}) do
        if type(value) == "table" then
            copy[key] = copyTable(value)
        else
            copy[key] = value
        end
    end
    return copy
end

local function ensureModDataTable(key, defaults)
    if not ModData.exists(key) then
        ModData.add(key, defaults or {})
    end

    local data = ModData.get(key)
    if type(data) == "table" then
        return data
    end

    if ModData.remove then
        ModData.remove(key)
    end

    ModData.add(key, defaults or {})
    return ModData.get(key)
end

local function getOwnerKey(ownerUsername)
    if Registry and Registry.GetColonyIDForOwner then
        local colonyID = Registry.GetColonyIDForOwner(ownerUsername, true)
        if colonyID ~= nil then
            return tostring(colonyID)
        end
    end

    return Config.GetOwnerUsername and Config.GetOwnerUsername(ownerUsername) or tostring(ownerUsername or "local")
end

local function getAuthorityOwner(ownerUsername)
    return Config.GetOwnerUsername and Config.GetOwnerUsername(ownerUsername) or tostring(ownerUsername or "local")
end

local function getShardKey(ownerUsername)
    return tostring(Config.MOD_DATA_RESOURCES_PREFIX or "DColony_Resources_") .. tostring(getOwnerKey(ownerUsername))
end

local function buildEmptyOwnerData(ownerUsername)
    return {
        schemaVersion = RESOURCE_SCHEMA_VERSION,
        colonyID = getOwnerKey(ownerUsername),
        ownerUsername = getAuthorityOwner(ownerUsername),
        version = 1,
        waterStored = 0,
        lastProcessedHour = -1,
        greenhouses = {}
    }
end

local function buildSeedLookup()
    if Internal.SeedToCropID then
        return Internal.SeedToCropID
    end

    local lookup = {}
    for cropID, crop in pairs(Resources.CROP_CATALOG or {}) do
        for _, fullType in ipairs(crop.seedFullTypes or {}) do
            lookup[tostring(fullType or "")] = cropID
        end
    end
    Internal.SeedToCropID = lookup
    return lookup
end

local function getDisplayName(fullType)
    local registryInternal = Registry and Registry.Internal or nil
    if registryInternal and registryInternal.GetDisplayNameForFullType then
        return registryInternal.GetDisplayNameForFullType(fullType)
    end
    return tostring(fullType or "Unknown")
end

local function getClimateManagerSafe()
    if getClimateManager then
        local climate = getClimateManager()
        if climate then
            return climate
        end
    end

    if ClimateManager and ClimateManager.getInstance then
        return ClimateManager.getInstance()
    end

    return nil
end

local function getRainState()
    local climate = getClimateManagerSafe()
    local raining = false
    local intensity = 0

    if climate and climate.isRaining and climate:isRaining() then
        raining = true
    end
    if climate and climate.getRainIntensity then
        intensity = math.max(0, tonumber(climate:getRainIntensity()) or 0)
    end
    if not raining and RainManager and RainManager.isRaining and RainManager.isRaining() then
        raining = true
    end
    if raining and intensity <= 0 then
        intensity = 1
    end

    return raining, intensity
end

local function getOutdoorTemperatureC()
    local climate = getClimateManagerSafe()
    if climate and climate.getTemperature then
        return tonumber(climate:getTemperature()) or 0
    end
    return 0
end

local function normalizeSlot(slot, slotIndex)
    slot = type(slot) == "table" and slot or {}
    slot.slotIndex = slotIndex
    slot.cropID = tostring(slot.cropID or "")
    if slot.cropID == "" or not Resources.CROP_CATALOG[slot.cropID] then
        return {
            slotIndex = slotIndex,
            state = "Empty",
            cropID = nil,
            seedFullType = nil,
            growthHours = 0,
            health = 100
        }
    end

    slot.seedFullType = tostring(slot.seedFullType or "")
    if slot.seedFullType == "" then
        slot.seedFullType = Resources.CROP_CATALOG[slot.cropID].seedFullTypes[1]
    end
    slot.growthHours = math.max(0, tonumber(slot.growthHours) or 0)
    slot.health = clampNumber(slot.health, 0, 100)
    slot.state = tostring(slot.state or "Growing")
    if slot.health <= 0 then
        slot.state = "Dead"
    elseif slot.state ~= "Ready" then
        slot.state = "Growing"
    end

    return slot
end

local function normalizeOwnerData(ownerUsername, ownerData)
    ownerData.schemaVersion = RESOURCE_SCHEMA_VERSION
    ownerData.colonyID = tostring(ownerData.colonyID or getOwnerKey(ownerUsername))
    ownerData.ownerUsername = getAuthorityOwner(ownerUsername or ownerData.ownerUsername)
    ownerData.version = math.max(1, math.floor(tonumber(ownerData.version) or 1))
    ownerData.waterStored = math.max(0, tonumber(ownerData.waterStored) or 0)
    ownerData.lastProcessedHour = tonumber(ownerData.lastProcessedHour) or -1
    ownerData.greenhouses = type(ownerData.greenhouses) == "table" and ownerData.greenhouses or {}
    return ownerData
end

local function getWaterCollectorBaseCapacity(instance)
    local levelDefinition = Buildings.Config.GetLevelDefinition and Buildings.Config.GetLevelDefinition("WaterCollector", instance and instance.level) or nil
    return math.max(0, math.floor(tonumber(levelDefinition and levelDefinition.effects and levelDefinition.effects.waterStorageBonus) or 0))
end

local function getWaterCollectorBaseRate(instance)
    local levelDefinition = Buildings.Config.GetLevelDefinition and Buildings.Config.GetLevelDefinition("WaterCollector", instance and instance.level) or nil
    return math.max(0, tonumber(levelDefinition and levelDefinition.effects and levelDefinition.effects.waterCollectionRate) or 0)
end

local function getWaterTankCapacity(instance)
    local levelDefinition = Buildings.Config.GetLevelDefinition and Buildings.Config.GetLevelDefinition("WaterTank", instance and instance.level) or nil
    return math.max(0, math.floor(tonumber(levelDefinition and levelDefinition.effects and levelDefinition.effects.waterStorageBonus) or 0))
end

function Resources.EnsureOwner(ownerUsername)
    local shardKey = getShardKey(ownerUsername)
    local ownerData = ensureModDataTable(shardKey, buildEmptyOwnerData(ownerUsername))
    return normalizeOwnerData(ownerUsername, ownerData)
end

function Resources.TouchVersion(ownerUsername)
    local ownerData = Resources.EnsureOwner(ownerUsername)
    ownerData.version = ownerData.version + 1
    return ownerData.version
end

function Resources.Save(ownerUsername)
    if ownerUsername then
        Resources.TouchVersion(ownerUsername)
    end

    if GlobalModData and GlobalModData.save then
        GlobalModData.save()
    end
end

function Resources.GetCropCatalog()
    local list = {}
    for _, crop in pairs(Resources.CROP_CATALOG or {}) do
        list[#list + 1] = copyTable(crop)
    end
    table.sort(list, function(a, b)
        return tostring(a.displayName or a.cropID or "") < tostring(b.displayName or b.cropID or "")
    end)
    return list
end

function Resources.GetCropForSeedType(seedFullType)
    local cropID = buildSeedLookup()[tostring(seedFullType or "")]
    if not cropID then
        return nil
    end
    return Resources.CROP_CATALOG[cropID]
end

function Resources.GetGreenhouseSlotCountForLevel(level)
    local levelDefinition = Buildings.Config.GetLevelDefinition and Buildings.Config.GetLevelDefinition("Greenhouse", level) or nil
    return math.max(0, math.floor(tonumber(levelDefinition and levelDefinition.effects and levelDefinition.effects.gardenSlots) or 0))
end

function Resources.GetGreenhouseWaterPerDayForLevel(level)
    local levelDefinition = Buildings.Config.GetLevelDefinition and Buildings.Config.GetLevelDefinition("Greenhouse", level) or nil
    return math.max(0, tonumber(levelDefinition and levelDefinition.effects and levelDefinition.effects.greenhouseWaterPerDayPerSlot) or 0)
end

function Resources.NormalizeGreenhouseStates(ownerUsername)
    local owner = getAuthorityOwner(ownerUsername)
    local ownerData = Resources.EnsureOwner(owner)
    local validIDs = {}

    for _, instance in ipairs(Buildings.GetBuildingsForOwner and Buildings.GetBuildingsForOwner(owner) or {}) do
        if tostring(instance and instance.buildingType or "") == "Greenhouse" and math.floor(tonumber(instance and instance.level) or 0) > 0 then
            local buildingID = tostring(instance.buildingID or "")
            local slotCount = Resources.GetGreenhouseSlotCountForLevel(instance.level)
            if buildingID ~= "" and slotCount > 0 then
                validIDs[buildingID] = true
                local state = type(ownerData.greenhouses[buildingID]) == "table" and ownerData.greenhouses[buildingID] or {
                    thermostatC = 20,
                    slots = {}
                }
                state.thermostatC = clampNumber(state.thermostatC, 0, 40)
                local normalizedSlots = {}
                for slotIndex = 1, slotCount do
                    normalizedSlots[slotIndex] = normalizeSlot(state.slots and state.slots[slotIndex], slotIndex)
                end
                state.slots = normalizedSlots
                ownerData.greenhouses[buildingID] = state
            end
        end
    end

    for buildingID, _ in pairs(ownerData.greenhouses or {}) do
        if not validIDs[tostring(buildingID or "")] then
            ownerData.greenhouses[buildingID] = nil
        end
    end

    return ownerData
end

local function getGreenhouseState(ownerUsername, buildingID)
    local ownerData = Resources.NormalizeGreenhouseStates(ownerUsername)
    return ownerData.greenhouses and ownerData.greenhouses[tostring(buildingID or "")] or nil
end

function Resources.GetWaterCapacity(ownerUsername)
    local owner = getAuthorityOwner(ownerUsername)
    local total = 0

    for _, instance in ipairs(Buildings.GetBuildingsForOwner and Buildings.GetBuildingsForOwner(owner) or {}) do
        local buildingType = tostring(instance and instance.buildingType or "")
        if math.floor(tonumber(instance and instance.level) or 0) > 0 then
            if buildingType == "WaterCollector" then
                total = total + getWaterCollectorBaseCapacity(instance)
            elseif buildingType == "WaterTank" then
                total = total + getWaterTankCapacity(instance)
            end
        end
    end

    return math.max(0, math.floor(total + 0.5))
end

function Resources.GetWaterCollectionRatePerHour(ownerUsername)
    local owner = getAuthorityOwner(ownerUsername)
    local total = 0

    for _, instance in ipairs(Buildings.GetBuildingsForOwner and Buildings.GetBuildingsForOwner(owner) or {}) do
        if tostring(instance and instance.buildingType or "") == "WaterCollector" and math.floor(tonumber(instance and instance.level) or 0) > 0 then
            local rate = getWaterCollectorBaseRate(instance)
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
    local owner = getAuthorityOwner(ownerUsername)
    local total = 0
    Resources.NormalizeGreenhouseStates(owner)

    for _, instance in ipairs(Buildings.GetBuildingsForOwner and Buildings.GetBuildingsForOwner(owner) or {}) do
        if tostring(instance and instance.buildingType or "") == "Greenhouse" and math.floor(tonumber(instance and instance.level) or 0) > 0 then
            local state = getGreenhouseState(owner, instance.buildingID)
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
            waterStorageContribution = getWaterCollectorBaseCapacity(instance),
            waterCollectionRateContribution = getWaterCollectorBaseRate(instance) + installRate,
            barrelInstallCount = barrelInstallCount,
            barrelInstalls = barrelInstalls
        }
    end

    if tostring(instance.buildingType or "") == "WaterTank" then
        return {
            waterStorageContribution = getWaterTankCapacity(instance)
        }
    end

    if tostring(instance.buildingType or "") == "Greenhouse" then
        local state = getGreenhouseState(ownerUsername, instance.buildingID)
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

local function buildGreenhouseSlotSnapshot(slot)
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
        produceDisplayName = crop and getDisplayName(crop.produceFullType) or nil
    }
end

function Resources.GetGreenhouseSnapshots(ownerUsername)
    local owner = getAuthorityOwner(ownerUsername)
    Resources.NormalizeGreenhouseStates(owner)
    local snapshots = {}

    for _, instance in ipairs(Buildings.GetBuildingsForOwner and Buildings.GetBuildingsForOwner(owner) or {}) do
        if tostring(instance and instance.buildingType or "") == "Greenhouse" and math.floor(tonumber(instance and instance.level) or 0) > 0 then
            local state = getGreenhouseState(owner, instance.buildingID)
            local slots = {}
            local activeSlots = 0
            for _, slot in ipairs(state and state.slots or {}) do
                local snapshot = buildGreenhouseSlotSnapshot(slot)
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
    local owner = getAuthorityOwner(ownerUsername)
    local ownerData = Resources.NormalizeGreenhouseStates(owner)
    local capacity = Resources.GetWaterCapacity(owner)
    ownerData.waterStored = math.min(capacity, math.max(0, tonumber(ownerData.waterStored) or 0))

    local raining, rainIntensity = getRainState()
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
            outdoorTemperatureC = getOutdoorTemperatureC(),
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

local function collectInventoryItemsRecursive(container, into)
    if not container or not into then
        return
    end

    local items = container:getItems()
    if not items then
        return
    end

    for index = 0, items:size() - 1 do
        local item = items:get(index)
        if item then
            into[#into + 1] = item
            if instanceof(item, "InventoryContainer") then
                collectInventoryItemsRecursive(item:getItemContainer(), into)
            end
        end
    end
end

local function getInventoryItemQuantity(item)
    if not item then
        return 0
    end

    local count = item.getCount and item:getCount() or nil
    count = math.floor(tonumber(count) or 0)
    if count > 0 then
        return count
    end

    return 1
end

local function removeInventoryItem(item)
    local container = item and item:getContainer() or nil
    if container then
        container:DoRemoveItem(item)
    end
end

local function addInventoryItem(container, fullType, count)
    if container and fullType and count and count > 0 then
        container:AddItems(fullType, count)
    end
end

function Resources.ConsumeSeedFromPlayer(player, seedFullType)
    local inventory = player and player:getInventory() or nil
    if not inventory then
        return false
    end

    local items = {}
    collectInventoryItemsRecursive(inventory, items)

    for _, item in ipairs(items) do
        local fullType = item and item.getFullType and item:getFullType() or nil
        if tostring(fullType or "") == tostring(seedFullType or "") then
            local quantity = getInventoryItemQuantity(item)
            local container = item:getContainer()
            removeInventoryItem(item)
            if quantity > 1 and container then
                addInventoryItem(container, fullType, quantity - 1)
            end
            return true
        end
    end

    return false
end

function Resources.SetGreenhouseThermostat(ownerUsername, buildingID, thermostatC)
    local owner = getAuthorityOwner(ownerUsername)
    local state = getGreenhouseState(owner, buildingID)
    if not state then
        return false, "That greenhouse is no longer available."
    end

    state.thermostatC = clampNumber(thermostatC, 0, 40)
    Resources.Save(owner)
    return true, nil
end

function Resources.ClearGreenhouseSlot(ownerUsername, buildingID, slotIndex)
    local owner = getAuthorityOwner(ownerUsername)
    local state = getGreenhouseState(owner, buildingID)
    if not state or not state.slots or not state.slots[slotIndex] then
        return false, "That greenhouse slot is invalid."
    end

    state.slots[slotIndex] = normalizeSlot(nil, slotIndex)
    Resources.Save(owner)
    return true, nil
end

function Resources.PlantGreenhouseSlot(player, buildingID, slotIndex, seedFullType)
    local owner = getAuthorityOwner(player)
    local state = getGreenhouseState(owner, buildingID)
    if not state or not state.slots or not state.slots[slotIndex] then
        return false, "That greenhouse slot is invalid."
    end

    local slot = state.slots[slotIndex]
    if slot.cropID and slot.state ~= "Dead" and slot.state ~= "Empty" then
        return false, "That slot is already planted."
    end

    local crop = Resources.GetCropForSeedType(seedFullType)
    if not crop then
        return false, "That seed is not supported by the greenhouse."
    end

    if not Resources.ConsumeSeedFromPlayer(player, seedFullType) then
        return false, "That seed was not found in player inventory."
    end

    state.slots[slotIndex] = normalizeSlot({
        slotIndex = slotIndex,
        state = "Growing",
        cropID = crop.cropID,
        seedFullType = seedFullType,
        growthHours = 0,
        health = 100
    }, slotIndex)

    Resources.Save(owner)
    return true, nil
end

local function findHarvestableSlot(ownerUsername)
    local owner = getAuthorityOwner(ownerUsername)
    Resources.NormalizeGreenhouseStates(owner)

    for _, instance in ipairs(Buildings.GetBuildingsForOwner and Buildings.GetBuildingsForOwner(owner) or {}) do
        if tostring(instance and instance.buildingType or "") == "Greenhouse" and math.floor(tonumber(instance and instance.level) or 0) > 0 then
            local state = getGreenhouseState(owner, instance.buildingID)
            for _, slot in ipairs(state and state.slots or {}) do
                if slot.cropID and slot.state == "Ready" then
                    return instance, state, slot, Resources.CROP_CATALOG[slot.cropID]
                end
            end
        end
    end

    return nil, nil, nil, nil
end

function Resources.ProcessFarmWorkCycle(worker, ctx)
    local owner = getAuthorityOwner(worker and worker.ownerUsername)
    local yieldMultiplier = math.max(0.1, tonumber(ctx and ctx.yieldMultiplier) or 1)
    local greenhouse, state, slot, crop = findHarvestableSlot(owner)

    if not greenhouse or not slot or not crop then
        local label = Resources.GetAnyGreenhouseLabel(owner)
        if worker then
            worker.siteState = label
            worker.greenhouseWorkLabel = label
        end
        return {
            entries = {},
            totalQuantity = 0,
            success = false,
            failed = false,
            siteLabel = label
        }
    end

    local qty = ZombRand(crop.harvestMin, crop.harvestMax + 1)
    qty = math.max(1, math.floor((qty * yieldMultiplier) + 0.5))

    local slotIndex = tonumber(slot.slotIndex) or 1
    state.slots[slotIndex] = normalizeSlot(nil, slotIndex)
    Resources.Save(owner)

    local label = "Greenhouse " .. tostring(greenhouse.plotX or 0) .. "," .. tostring(greenhouse.plotY or 0)
    if worker then
        worker.siteState = label
        worker.greenhouseWorkLabel = label
    end

    return {
        entries = {
            {
                fullType = crop.produceFullType,
                qty = qty
            }
        },
        totalQuantity = qty,
        success = true,
        failed = false,
        siteLabel = label,
        harvestLabel = crop.displayName
    }
end

local function processOwner(ownerUsername, currentHour, deltaHours)
    local owner = getAuthorityOwner(ownerUsername)
    local ownerData = Resources.NormalizeGreenhouseStates(owner)
    local changed = false
    local capacity = Resources.GetWaterCapacity(owner)
    local stored = math.min(capacity, math.max(0, tonumber(ownerData.waterStored) or 0))

    local raining, rainIntensity = getRainState()
    if raining and deltaHours > 0 then
        local collectionRate = Resources.GetWaterCollectionRatePerHour(owner)
        if collectionRate > 0 then
            local collected = collectionRate * math.max(0.25, rainIntensity) * deltaHours
            local nextStored = math.min(capacity, stored + collected)
            if math.abs(nextStored - stored) > 0.0001 then
                stored = nextStored
                changed = true
            end
        end
    end

    for _, instance in ipairs(Buildings.GetBuildingsForOwner and Buildings.GetBuildingsForOwner(owner) or {}) do
        if tostring(instance and instance.buildingType or "") == "Greenhouse" and math.floor(tonumber(instance and instance.level) or 0) > 0 then
            local state = getGreenhouseState(owner, instance.buildingID)
            local perSlotWater = Resources.GetGreenhouseWaterPerDayForLevel(instance.level) / math.max(1, tonumber(Config.HOURS_PER_DAY) or 24)
            for slotIndex, slot in ipairs(state and state.slots or {}) do
                local crop = slot and slot.cropID and Resources.CROP_CATALOG[slot.cropID] or nil
                if crop and slot.state == "Growing" and deltaHours > 0 then
                    local tempOkay = state.thermostatC >= crop.tempMinC and state.thermostatC <= crop.tempMaxC
                    local waterNeeded = perSlotWater * deltaHours
                    local hasWater = stored + 0.0001 >= waterNeeded

                    if tempOkay and hasWater then
                        stored = math.max(0, stored - waterNeeded)
                        slot.growthHours = math.max(0, tonumber(slot.growthHours) or 0) + deltaHours
                        slot.health = clampNumber((tonumber(slot.health) or 100) + (deltaHours * 0.75), 0, 100)
                        if slot.growthHours + 0.0001 >= math.max(1, tonumber(crop.growthHours) or 1) then
                            slot.state = "Ready"
                        end
                        changed = true
                    else
                        local decayPerHour = tempOkay and 3 or 7
                        slot.health = clampNumber((tonumber(slot.health) or 100) - (decayPerHour * deltaHours), 0, 100)
                        if slot.health <= 0 then
                            state.slots[slotIndex] = normalizeSlot({
                                slotIndex = slotIndex,
                                cropID = slot.cropID,
                                seedFullType = slot.seedFullType,
                                growthHours = slot.growthHours,
                                health = 0,
                                state = "Dead"
                            }, slotIndex)
                        end
                        changed = true
                    end
                end
            end
        end
    end

    local clampedStored = math.min(capacity, math.max(0, stored))
    if math.abs(clampedStored - (tonumber(ownerData.waterStored) or 0)) > 0.0001 then
        ownerData.waterStored = clampedStored
        changed = true
    else
        ownerData.waterStored = clampedStored
    end

    ownerData.lastProcessedHour = currentHour
    return changed
end

function Resources.ProcessAllOwners(currentHour)
    if isClient() and not isServer() then
        return false
    end

    local changed = false
    for _, ownerUsername in ipairs(Registry.GetOwnerUsernames and Registry.GetOwnerUsernames() or {}) do
        local ownerData = Resources.EnsureOwner(ownerUsername)
        local lastHour = tonumber(ownerData.lastProcessedHour) or -1
        local deltaHours = 0
        if lastHour >= 0 then
            deltaHours = math.max(0, tonumber(currentHour) - lastHour)
        end

        if lastHour < 0 then
            ownerData.lastProcessedHour = currentHour
            changed = true
        elseif deltaHours > 0 then
            if processOwner(ownerUsername, currentHour, deltaHours) then
                changed = true
            end
        end
    end

    if changed then
        Resources.Save()
    end

    return changed
end

return Resources

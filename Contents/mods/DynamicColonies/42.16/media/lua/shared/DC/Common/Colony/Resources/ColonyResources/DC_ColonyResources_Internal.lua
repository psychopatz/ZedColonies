DC_Colony = DC_Colony or {}
DC_Colony.Resources = DC_Colony.Resources or {}
DC_Colony.Resources.Internal = DC_Colony.Resources.Internal or {}

local Config = DC_Colony.Config
local Registry = DC_Colony.Registry
local Buildings = DC_Buildings
local Resources = DC_Colony.Resources
local Internal = Resources.Internal

function Internal.ClampNumber(value, minimum, maximum)
    local safeValue = tonumber(value) or 0
    if safeValue < minimum then
        return minimum
    end
    if safeValue > maximum then
        return maximum
    end
    return safeValue
end

function Internal.CopyTable(source)
    local copy = {}
    for key, value in pairs(source or {}) do
        if type(value) == "table" then
            copy[key] = Internal.CopyTable(value)
        else
            copy[key] = value
        end
    end
    return copy
end

function Internal.EnsureModDataTable(key, defaults)
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

function Internal.GetOwnerKey(ownerUsername)
    if Registry and Registry.GetColonyIDForOwner then
        local colonyID = Registry.GetColonyIDForOwner(ownerUsername, true)
        if colonyID ~= nil then
            return tostring(colonyID)
        end
    end

    return Config.GetOwnerUsername and Config.GetOwnerUsername(ownerUsername) or tostring(ownerUsername or "local")
end

function Internal.GetAuthorityOwner(ownerUsername)
    return Config.GetOwnerUsername and Config.GetOwnerUsername(ownerUsername) or tostring(ownerUsername or "local")
end

function Internal.GetShardKey(ownerUsername)
    return tostring(Config.MOD_DATA_RESOURCES_PREFIX or "DColony_Resources_") .. tostring(Internal.GetOwnerKey(ownerUsername))
end

function Internal.BuildEmptyOwnerData(ownerUsername)
    return {
        schemaVersion = Internal.RESOURCE_SCHEMA_VERSION,
        colonyID = Internal.GetOwnerKey(ownerUsername),
        ownerUsername = Internal.GetAuthorityOwner(ownerUsername),
        version = 1,
        waterStored = 0,
        lastProcessedHour = -1,
        greenhouses = {}
    }
end

function Internal.BuildSeedLookup()
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

function Internal.GetDisplayName(fullType)
    local registryInternal = Registry and Registry.Internal or nil
    if registryInternal and registryInternal.GetDisplayNameForFullType then
        return registryInternal.GetDisplayNameForFullType(fullType)
    end
    return tostring(fullType or "Unknown")
end

function Internal.GetClimateManagerSafe()
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

function Internal.GetRainState()
    local climate = Internal.GetClimateManagerSafe()
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

function Internal.GetOutdoorTemperatureC()
    local climate = Internal.GetClimateManagerSafe()
    if climate and climate.getTemperature then
        return tonumber(climate:getTemperature()) or 0
    end
    return 0
end

function Internal.NormalizeSlot(slot, slotIndex)
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
    slot.health = Internal.ClampNumber(slot.health, 0, 100)
    slot.state = tostring(slot.state or "Growing")
    if slot.health <= 0 then
        slot.state = "Dead"
    elseif slot.state ~= "Ready" then
        slot.state = "Growing"
    end

    return slot
end

function Internal.NormalizeOwnerData(ownerUsername, ownerData)
    ownerData.schemaVersion = Internal.RESOURCE_SCHEMA_VERSION
    ownerData.colonyID = tostring(ownerData.colonyID or Internal.GetOwnerKey(ownerUsername))
    ownerData.ownerUsername = Internal.GetAuthorityOwner(ownerUsername or ownerData.ownerUsername)
    ownerData.version = math.max(1, math.floor(tonumber(ownerData.version) or 1))
    ownerData.waterStored = math.max(0, tonumber(ownerData.waterStored) or 0)
    ownerData.lastProcessedHour = tonumber(ownerData.lastProcessedHour) or -1
    ownerData.greenhouses = type(ownerData.greenhouses) == "table" and ownerData.greenhouses or {}
    return ownerData
end

function Internal.GetWaterCollectorBaseCapacity(instance)
    local levelDefinition = Buildings.Config.GetLevelDefinition and Buildings.Config.GetLevelDefinition("WaterCollector", instance and instance.level) or nil
    return math.max(0, math.floor(tonumber(levelDefinition and levelDefinition.effects and levelDefinition.effects.waterStorageBonus) or 0))
end

function Internal.GetWaterCollectorBaseRate(instance)
    local levelDefinition = Buildings.Config.GetLevelDefinition and Buildings.Config.GetLevelDefinition("WaterCollector", instance and instance.level) or nil
    return math.max(0, tonumber(levelDefinition and levelDefinition.effects and levelDefinition.effects.waterCollectionRate) or 0)
end

function Internal.GetWaterTankCapacity(instance)
    local levelDefinition = Buildings.Config.GetLevelDefinition and Buildings.Config.GetLevelDefinition("WaterTank", instance and instance.level) or nil
    return math.max(0, math.floor(tonumber(levelDefinition and levelDefinition.effects and levelDefinition.effects.waterStorageBonus) or 0))
end
DC_Colony = DC_Colony or {}
DC_Colony.CorpseFacilities = DC_Colony.CorpseFacilities or {}
DC_Colony.CorpseFacilities.Internal = DC_Colony.CorpseFacilities.Internal or {}

local Config = DC_Colony.Config
local Registry = DC_Colony.Registry
local Buildings = DC_Buildings
local Facilities = DC_Colony.CorpseFacilities
local Internal = Facilities.Internal

local DEFAULT_ROUTE = "MassGrave"
local DEFAULT_OVERFLOW = "Block"

local function getOwnerKey(ownerUsername)
    return Config.GetOwnerUsername and Config.GetOwnerUsername(ownerUsername) or tostring(ownerUsername or "local")
end

local function getDataKey(ownerUsername)
    local owner = getOwnerKey(ownerUsername)
    local colonyID = Registry.GetColonyIDForOwner and Registry.GetColonyIDForOwner(owner, true) or owner
    return "DColony_CorpseFacilities_" .. tostring(colonyID)
end

local function floorNumber(value, fallback)
    if tonumber(value) == nil then
        return fallback
    end
    return math.floor(tonumber(value) or fallback or 0)
end

local function getEffect(buildingType, level, key, fallback)
    local definition = Buildings and Buildings.Config and Buildings.Config.GetLevelDefinition
        and Buildings.Config.GetLevelDefinition(buildingType, level) or nil
    return floorNumber(definition and definition.effects and definition.effects[key], fallback)
end

function Internal.GetBuildingSlotCapacity(buildingType, level)
    if buildingType == "Cemetery" then
        return math.max(0, getEffect("Cemetery", level, "cemeterySlots", 8))
    end
    if buildingType == "MassGrave" then
        return math.max(0, getEffect("MassGrave", level, "massGraveSlots", 24))
    end
    return 0
end

function Internal.GetBuildingDecomposeDays(buildingType, level)
    if buildingType == "Cemetery" then
        return math.max(1, getEffect("Cemetery", level, "cemeteryDecomposeDays", 14))
    end
    if buildingType == "MassGrave" then
        return math.max(1, getEffect("MassGrave", level, "massGraveDecomposeDays", 7))
    end
    return 0
end

function Internal.GetIncineratorBatchSize(level)
    return math.max(1, getEffect("Incinerator", level, "incineratorBatchSize", 6))
end

function Internal.GetIncineratorCooldownHours(level)
    return math.max(1, getEffect("Incinerator", level, "incineratorCooldownHours", 12))
end

function Internal.GetIncineratorFuelPerBatch(level)
    return math.max(0, getEffect("Incinerator", level, "incineratorFuelPerBatch", 0))
end

function Internal.EnsureOwnerData(ownerUsername)
    local key = getDataKey(ownerUsername)
    local data = Registry and Registry.Internal and Registry.Internal.EnsureModDataTable
        and Registry.Internal.EnsureModDataTable(key, {
            ownerUsername = getOwnerKey(ownerUsername),
            settings = {
                generalRoutePreference = DEFAULT_ROUTE,
                teammateOverflowPolicy = DEFAULT_OVERFLOW,
            },
            buildings = {},
            summary = {
                buried = 0,
                incinerated = 0,
                exhumed = 0,
                blockedCleanups = 0,
            },
            version = 1,
            nextEntryID = 1,
            lastProcessedHour = -1,
        }) or nil
    if not data then
        return nil
    end

    data.ownerUsername = getOwnerKey(ownerUsername)
    data.settings = type(data.settings) == "table" and data.settings or {}
    data.settings.generalRoutePreference = tostring(data.settings.generalRoutePreference or DEFAULT_ROUTE)
    if data.settings.generalRoutePreference ~= "MassGrave" and data.settings.generalRoutePreference ~= "Incinerator" then
        data.settings.generalRoutePreference = DEFAULT_ROUTE
    end
    data.settings.teammateOverflowPolicy = tostring(data.settings.teammateOverflowPolicy or DEFAULT_OVERFLOW)
    if data.settings.teammateOverflowPolicy ~= "Block" and data.settings.teammateOverflowPolicy ~= "AllowOverflow" then
        data.settings.teammateOverflowPolicy = DEFAULT_OVERFLOW
    end

    data.buildings = type(data.buildings) == "table" and data.buildings or {}
    data.summary = type(data.summary) == "table" and data.summary or {}
    data.summary.buried = math.max(0, floorNumber(data.summary.buried, 0))
    data.summary.incinerated = math.max(0, floorNumber(data.summary.incinerated, 0))
    data.summary.exhumed = math.max(0, floorNumber(data.summary.exhumed, 0))
    data.summary.blockedCleanups = math.max(0, floorNumber(data.summary.blockedCleanups, 0))
    data.version = math.max(1, floorNumber(data.version, 1))
    data.nextEntryID = math.max(1, floorNumber(data.nextEntryID, 1))
    data.lastProcessedHour = tonumber(data.lastProcessedHour) or -1
    return data
end

function Internal.Touch(ownerUsername)
    local data = Internal.EnsureOwnerData(ownerUsername)
    if data then
        data.version = math.max(1, floorNumber(data.version, 1)) + 1
    end
    return data
end

function Internal.NextEntryID(ownerUsername)
    local data = Internal.EnsureOwnerData(ownerUsername)
    if not data then
        return ""
    end

    local nextID = math.max(1, floorNumber(data.nextEntryID, 1))
    data.nextEntryID = nextID + 1
    return tostring(data.ownerUsername or getOwnerKey(ownerUsername)) .. "_corpse_" .. tostring(nextID)
end

function Facilities.NormalizeOwner(ownerUsername)
    local owner = getOwnerKey(ownerUsername)
    local data = Internal.EnsureOwnerData(owner)
    if not data then
        return nil
    end

    local validIDs = {}
    for _, building in ipairs(Buildings.GetBuildingsForOwner and Buildings.GetBuildingsForOwner(owner) or {}) do
        local buildingType = tostring(building and building.buildingType or "")
        local buildingID = tostring(building and building.buildingID or "")
        local level = math.max(1, floorNumber(building and building.level, 1))
        if buildingID ~= "" and (buildingType == "Cemetery" or buildingType == "MassGrave" or buildingType == "Incinerator") then
            validIDs[buildingID] = true
            local state = type(data.buildings[buildingID]) == "table" and data.buildings[buildingID] or {
                buildingID = buildingID,
                buildingType = buildingType,
            }
            state.buildingID = buildingID
            state.buildingType = buildingType
            state.level = level
            if buildingType == "Cemetery" or buildingType == "MassGrave" then
                local slotCount = Internal.GetBuildingSlotCapacity(buildingType, level)
                local slots = {}
                for slotIndex = 1, slotCount do
                    slots[slotIndex] = state.slots and state.slots[slotIndex] or nil
                end
                state.slots = slots
            elseif buildingType == "Incinerator" then
                state.queue = type(state.queue) == "table" and state.queue or {}
                state.activeBatch = type(state.activeBatch) == "table" and state.activeBatch or nil
                state.fuelReserve = math.max(0, floorNumber(state.fuelReserve, 0))
            end
            data.buildings[buildingID] = state
        end
    end

    for buildingID, _ in pairs(data.buildings or {}) do
        if not validIDs[tostring(buildingID or "")] then
            data.buildings[buildingID] = nil
        end
    end

    return data
end

return Facilities

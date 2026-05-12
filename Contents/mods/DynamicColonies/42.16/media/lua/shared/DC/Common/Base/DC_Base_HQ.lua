DC_Base = DC_Base or {}
DC_Base.Internal = DC_Base.Internal or {}

local Base = DC_Base
local Internal = Base.Internal
local Registry = DC_Colony.Registry

local function getBuildings()
    return DC_Buildings or nil
end

local function registerPlacedHeadquarters(baseData, x, y, z, entityType)
    local squareKey = Internal.MakeSquareKey(x, y, z)
    baseData.placedStructures = type(baseData.placedStructures) == "table" and baseData.placedStructures or {}
    local replaced = false
    for index, entry in ipairs(baseData.placedStructures) do
        if tostring(entry.structureType or "") == Base.Constants.StructureTypes.Headquarters then
            baseData.placedStructures[index] = {
                structureType = Base.Constants.StructureTypes.Headquarters,
                entityType = tostring(entityType or Base.Constants.HeadquartersEntityType),
                x = x,
                y = y,
                z = z,
                squareKey = squareKey,
            }
            replaced = true
            break
        end
    end

    if not replaced then
        baseData.placedStructures[#baseData.placedStructures + 1] = {
            structureType = Base.Constants.StructureTypes.Headquarters,
            entityType = tostring(entityType or Base.Constants.HeadquartersEntityType),
            x = x,
            y = y,
            z = z,
            squareKey = squareKey,
        }
    end
end

local function syncWorkersHomeToHeadquarters(ownerUsername, x, y, z)
    if not Registry or not Registry.GetWorkersForOwnerRaw then
        return
    end

    for _, worker in ipairs(Registry.GetWorkersForOwnerRaw(ownerUsername) or {}) do
        worker.homeX = x
        worker.homeY = y
        worker.homeZ = z
        if Registry.TouchWorkerDetailVersion then
            Registry.TouchWorkerDetailVersion(worker)
        end
    end

    if Registry.TouchWorkersVersion then
        Registry.TouchWorkersVersion(ownerUsername)
    end
end

local function mirrorHeadquartersIntoBuildings(ownerUsername)
    local Buildings = getBuildings()
    if not Buildings then
        return
    end

    local existing = Buildings.GetHeadquartersInstance and Buildings.GetHeadquartersInstance(ownerUsername) or nil
    if existing then
        if math.floor(tonumber(existing.level) or 0) < 1 then
            existing.level = 1
            Buildings.Save(ownerUsername)
        end
        return
    end

    if Buildings.CreateBuildingInstance then
        Buildings.CreateBuildingInstance(
            ownerUsername,
            Base.Constants.HeadquartersBuildingType,
            1,
            Base.Constants.HeadquartersPlotX,
            Base.Constants.HeadquartersPlotY
        )
        Buildings.Save(ownerUsername)
    end
end

function Base.CanFinalizeHeadquarters(ownerUsername, x, y, z)
    local state = Internal.EnsureState(ownerUsername, true)
    if not state then
        return false, "Colony data is unavailable.", nil
    end

    if state.base.baseMode == Base.Constants.Modes.Settled and tostring(state.base.hqEntityType or "") ~= "" then
        return false, "Headquarters is already established.", nil
    end

    local baseZone = Base.GetBaseZone(ownerUsername)
    if not baseZone then
        return false, "Create a base zone first.", nil
    end

    if not DC_ZoneData.isInsideZone(baseZone, x, y, z) then
        return false, "Place the HQ inside the base zone.", baseZone
    end

    return true, nil, baseZone
end

function Base.FinalizeHeadquarters(ownerUsername, entityData)
    entityData = type(entityData) == "table" and entityData or {}
    local x = math.floor(tonumber(entityData.x) or 0)
    local y = math.floor(tonumber(entityData.y) or 0)
    local z = math.floor(tonumber(entityData.z) or 0)
    local entityType = tostring(entityData.entityType or Base.Constants.HeadquartersEntityType)

    local ok, reason, baseZone = Base.CanFinalizeHeadquarters(ownerUsername, x, y, z)
    if not ok then
        return false, reason, nil
    end

    local state = Internal.EnsureState(ownerUsername, true)
    if not state then
        return false, "Colony data is unavailable.", nil
    end

    state.base.baseMode = Base.Constants.Modes.Settled
    state.base.hqTier = 1
    state.base.hqEntityType = entityType
    state.base.hqX = x
    state.base.hqY = y
    state.base.hqZ = z
    state.base.baseZoneID = tostring(baseZone.id or "")
    registerPlacedHeadquarters(state.base, x, y, z, entityType)
    syncWorkersHomeToHeadquarters(ownerUsername, x, y, z)
    mirrorHeadquartersIntoBuildings(ownerUsername)

    Internal.Save(ownerUsername, "base")
    return true, nil, Base.GetBaseState(ownerUsername)
end

function Base.IsInsideFunctionalBase(ownerUsername, x, y, z)
    local state = Base.GetBaseState(ownerUsername)
    if not state or state.baseMode ~= Base.Constants.Modes.Settled then
        return false
    end

    local baseZone = Base.GetBaseZone(ownerUsername)
    if not baseZone then
        return false
    end

    return DC_ZoneData.isInsideZone(baseZone, x, y, z)
end

function Base.RegisterPlacedStructure(ownerUsername, structureType, entityType, x, y, z)
    local state = Internal.EnsureState(ownerUsername, true)
    if not state then
        return false
    end

    state.base.placedStructures = type(state.base.placedStructures) == "table" and state.base.placedStructures or {}
    state.base.placedStructures[#state.base.placedStructures + 1] = {
        structureType = tostring(structureType or ""),
        entityType = tostring(entityType or ""),
        x = math.floor(tonumber(x) or 0),
        y = math.floor(tonumber(y) or 0),
        z = math.floor(tonumber(z) or 0),
        squareKey = Internal.MakeSquareKey(x, y, z),
    }
    Internal.Save(ownerUsername, "base")
    return true
end

return Base

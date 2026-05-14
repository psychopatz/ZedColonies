DC_ZoneRealBase = DC_ZoneRealBase or {}

local RealBase = DC_ZoneRealBase

local function getConfig()
    return DC_Colony and DC_Colony.Config or nil
end

local function normalizeOwner(ownerUsername)
    local config = getConfig()
    if config and config.GetOwnerUsername then
        return config.GetOwnerUsername(ownerUsername)
    end
    return tostring(ownerUsername or "local")
end

function RealBase.GetTilesPerBarricade()
    local config = getConfig()
    local value = config and config.GetBaseTilesPerBarricade and config.GetBaseTilesPerBarricade() or 30
    return math.max(0, math.floor(tonumber(value) or 30))
end

function RealBase.CountCompletedBarricades(ownerUsername)
    local owner = normalizeOwner(ownerUsername)
    local count = 0
    local buildings = DC_Buildings

    for _, instance in ipairs(buildings and buildings.GetBuildingsForOwner and buildings.GetBuildingsForOwner(owner) or {}) do
        if tostring(instance and instance.buildingType or "") == "Barricade"
            and math.floor(tonumber(instance and instance.level) or 0) > 0 then
            count = count + 1
        end
    end

    return count
end

function RealBase.CountUnlockedPlots(ownerUsername)
    local owner = normalizeOwner(ownerUsername)
    local buildings = DC_Buildings
    local unlockedPlots = buildings and buildings.GetUnlockedPlotEntries and buildings.GetUnlockedPlotEntries(owner) or {}
    return #unlockedPlots
end

function RealBase.GetAllowedBaseTiles(ownerUsername, options)
    options = type(options) == "table" and options or {}
    local unlockedPlotCount = tonumber(options.unlockedPlotCount)
    if unlockedPlotCount == nil then
        unlockedPlotCount = RealBase.CountUnlockedPlots(ownerUsername)
    end
    if unlockedPlotCount ~= nil and unlockedPlotCount > 0 then
        return math.max(0, math.floor(unlockedPlotCount or 0)) * RealBase.GetTilesPerBarricade()
    end

    local barricadeCount = tonumber(options.completedBarricades)
    if barricadeCount == nil then
        barricadeCount = RealBase.CountCompletedBarricades(ownerUsername)
    end

    return math.max(0, math.floor(barricadeCount or 0)) * RealBase.GetTilesPerBarricade()
end

function RealBase.GetManagedAreaTileCap(options)
    options = type(options) == "table" and options or {}
    local configured = tonumber(options.areaTileCap)
    if configured == nil then
        local config = getConfig()
        configured = config and config.GetBaseAreaSlotTileCap and config.GetBaseAreaSlotTileCap() or 100
    end

    configured = math.max(0, math.floor(configured or 0))
    if configured <= 0 then
        return nil
    end
    return configured
end

return RealBase

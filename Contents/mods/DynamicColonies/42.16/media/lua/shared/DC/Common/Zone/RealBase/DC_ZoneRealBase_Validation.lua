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

local function getHeadquartersLevel(ownerUsername, options)
    options = type(options) == "table" and options or {}
    if options.headquartersLevel ~= nil then
        return math.max(0, math.floor(tonumber(options.headquartersLevel) or 0))
    end

    local owner = normalizeOwner(ownerUsername)
    return DC_Buildings and DC_Buildings.GetHeadquartersLevel and math.max(0, math.floor(tonumber(DC_Buildings.GetHeadquartersLevel(owner)) or 0)) or 0
end

local function buildDefaultOptions(ownerUsername, options)
    options = type(options) == "table" and options or {}
    if options.unlockedPlotCount ~= nil and options.allowedBaseTiles ~= nil and options.headquartersLevel ~= nil then
        return options
    end

    local owner = normalizeOwner(ownerUsername)
    local territory = DC_Buildings and DC_Buildings.GetTerritorySummary and DC_Buildings.GetTerritorySummary(owner) or nil
    if not territory then
        return options
    end

    if options.headquartersLevel == nil then
        options.headquartersLevel = tonumber(territory.headquartersLevel) or 0
    end
    if options.unlockedPlotCount == nil then
        options.unlockedPlotCount = tonumber(territory.unlockedPlotCount) or 0
    end
    if options.allowedBaseTiles == nil then
        options.allowedBaseTiles = RealBase.GetAllowedBaseTiles(owner, {
            unlockedPlotCount = options.unlockedPlotCount,
            completedBarricades = tonumber(territory.completedBarricadeCount) or tonumber(territory.activeBarricadeCount) or 0
        })
    end

    return options
end

local function normalizeZones(zones)
    for _, zone in ipairs(zones or {}) do
        RealBase.NormalizeZoneShape(zone)
    end
    return zones or {}
end

local function getBaseSlot(zones)
    local baseZone = RealBase.FindBaseZone(zones)
    if not baseZone then
        return nil, nil
    end

    local slots = RealBase.GetAreaSlots(baseZone)
    return baseZone, slots[1]
end

local function isInsideBase2D(rect, baseRect)
    if type(rect) ~= "table" or type(baseRect) ~= "table" then
        return false
    end

    return rect[1] >= baseRect[1]
        and rect[2] >= baseRect[2]
        and rect[3] <= baseRect[3]
        and rect[4] <= baseRect[4]
end

local function isManagedZone(zone)
    local zoneKind = tostring(zone and zone.zoneKind or "")
    return zoneKind == "base" or zoneKind == "buildingType" or zoneKind == "jobType"
end

local function getZoneTileCap(zone, ownerUsername, options)
    if tostring(zone and zone.zoneKind or "") == "base" then
        return math.max(0, math.floor(tonumber(options and options.allowedBaseTiles) or RealBase.GetAllowedBaseTiles(ownerUsername, options)))
    end

    return RealBase.GetManagedAreaTileCap(options)
end

function RealBase.GetUsedBaseTiles(zones)
    local _, slot = getBaseSlot(normalizeZones(zones))
    return RealBase.GetRectTileCount(slot and slot.rect or nil)
end

function RealBase.ValidateZonesForOwner(ownerUsername, zones, options)
    options = buildDefaultOptions(ownerUsername, options)
    normalizeZones(zones)

    local headquartersLevel = getHeadquartersLevel(ownerUsername, options)
    if headquartersLevel <= 0 then
        for _, zone in ipairs(zones or {}) do
            if isManagedZone(zone) then
                for _, slot in ipairs(RealBase.GetAreaSlots(zone)) do
                    if slot.rect then
                        return false, "Build Headquarters first before assigning base areas."
                    end
                end
            end
        end
        return true, nil
    end

    local _, baseSlot = getBaseSlot(zones)
    local baseRect = baseSlot and baseSlot.rect or nil
    local allowedTiles = math.max(0, math.floor(tonumber(options.allowedBaseTiles) or RealBase.GetAllowedBaseTiles(ownerUsername, options)))
    local usedTiles = RealBase.GetRectTileCount(baseRect)
    if usedTiles > allowedTiles then
        return false, "Base Zone exceeds the current barricade tile allowance."
    end

    for _, zone in ipairs(zones or {}) do
        local zoneKind = tostring(zone and zone.zoneKind or "")
        if zoneKind == "buildingType" or zoneKind == "jobType" then
            for _, slot in ipairs(RealBase.GetAreaSlots(zone)) do
                if slot.rect then
                    local slotTileCap = getZoneTileCap(zone, ownerUsername, options)
                    local slotTileCount = RealBase.GetRectTileCount(slot.rect)
                    if slotTileCap ~= nil and slotTileCount > slotTileCap then
                        return false, tostring(slot.label or "Managed area") .. " exceeds the tile cap of " .. tostring(slotTileCap) .. "."
                    end
                    if not baseRect then
                        return false, "Assign the Base Zone first before setting building areas."
                    end
                    if not isInsideBase2D(slot.rect, baseRect) then
                        return false, tostring(slot.label or "Building area") .. " must stay inside the Base Zone."
                    end
                end
            end
        end
    end

    return true, nil
end

function RealBase.CanDestroyBarricade(ownerUsername, options)
    options = type(options) == "table" and options or {}
    local owner = normalizeOwner(ownerUsername)
    local usedTiles = math.max(0, math.floor(tonumber(options.usedTiles) or RealBase.GetUsedBaseTiles(RealBase.GetZonesForOwner(owner))))
    local completedBarricades = RealBase.CountCompletedBarricades(owner)
    local nextBarricadeCount = math.max(0, completedBarricades - 1)
    local nextAllowance = RealBase.GetAllowedBaseTiles(owner, {
        completedBarricades = nextBarricadeCount
    })

    if usedTiles > nextAllowance then
        return false, "Base Zone uses " .. tostring(usedTiles) .. " tiles, but removing this barricade would lower the allowance to " .. tostring(nextAllowance) .. "."
    end

    return true, nil
end

function RealBase.SanitizeSnapshotForSave(ownerUsername, colonyId, incomingZones, options)
    local mergedZones = RealBase.BuildMergedZonesForSave(ownerUsername, colonyId, incomingZones or {})
    local ok, reason = RealBase.ValidateZonesForOwner(ownerUsername, mergedZones, options)
    return ok, reason, mergedZones
end

return RealBase

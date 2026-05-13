DC_Buildings = DC_Buildings or {}

local Buildings = DC_Buildings
Buildings.Internal = Buildings.Internal or {}

local Frontier = Buildings.Internal.Frontier or {}
Buildings.Internal.Frontier = Frontier

function Frontier.IsRingSecured(ownerUsername, ring)
    local safeRing = math.max(1, math.floor(tonumber(ring) or 1))
    local ringCoords = Buildings.GetRingCoordinates and Buildings.GetRingCoordinates(safeRing) or {}
    for _, cell in ipairs(ringCoords) do
        if not Frontier.HasCompletedBarricadeAt(ownerUsername, cell.x, cell.y) then
            return false
        end
    end
    return #ringCoords > 0
end

function Frontier.RetireBarricadeBuildingsForRing(ownerUsername, ring)
    local safeOwner = Frontier.GetOwnerUsername(ownerUsername)
    local safeRing = math.max(1, math.floor(tonumber(ring) or 1))
    local buildings = Buildings.GetBuildingsForOwner(safeOwner) or {}
    local removed = 0

    for index = #buildings, 1, -1 do
        local instance = buildings[index]
        if tostring(instance and instance.buildingType or "") == "Barricade"
            and Buildings.GetPlotRing
            and Buildings.GetPlotRing(instance.plotX, instance.plotY) == safeRing
            and math.floor(tonumber(instance and instance.level) or 0) > 0 then
            table.remove(buildings, index)
            removed = removed + 1
        end
    end

    return removed
end

function Frontier.ComputeLegacySecuredRing(ownerUsername)
    local safeOwner = Frontier.GetOwnerUsername(ownerUsername)
    local ring = 1
    local highestSecured = 0

    while Frontier.IsRingSecured(safeOwner, ring) do
        highestSecured = ring
        ring = ring + 1
    end

    return highestSecured
end

function Frontier.GetSecuredPerimeterRing(ownerUsername)
    local safeOwner = Frontier.GetOwnerUsername(ownerUsername)
    local mapData = Buildings.GetMapDataForOwner and Buildings.GetMapDataForOwner(safeOwner) or nil
    local storedRing = mapData and mapData.securedRing

    if storedRing ~= nil then
        return math.max(0, math.floor(tonumber(storedRing) or 0))
    end

    local computedRing = Frontier.ComputeLegacySecuredRing(safeOwner)
    if mapData then
        mapData.securedRing = computedRing
    end

    if computedRing > 0 then
        for ring = 1, computedRing do
            Frontier.RetireBarricadeBuildingsForRing(safeOwner, ring)
        end
        Buildings.Save()
    end

    return computedRing
end

function Frontier.GetNextFrontierRing(ownerUsername)
    return Frontier.GetSecuredPerimeterRing(ownerUsername) + 1
end

function Frontier.CanExpandToRing(ownerUsername, ring)
    local safeOwner = Frontier.GetOwnerUsername(ownerUsername)
    local safeRing = math.max(0, math.floor(tonumber(ring) or 0))
    if safeRing <= 0 then
        return false
    end

    return Buildings.GetHeadquartersLevel(safeOwner) >= safeRing
end

function Frontier.GetActiveFrontierRing(ownerUsername)
    local safeOwner = Frontier.GetOwnerUsername(ownerUsername)
    local nextRing = Frontier.GetNextFrontierRing(safeOwner)
    if Frontier.CanExpandToRing(safeOwner, nextRing) then
        return nextRing
    end
    return 0
end

function Buildings.GetActiveFrontierRing(ownerUsername)
    return Frontier.GetActiveFrontierRing(ownerUsername)
end

function Buildings.GetNextFrontierRing(ownerUsername)
    return Frontier.GetNextFrontierRing(ownerUsername)
end

function Buildings.GetSecuredPerimeterRing(ownerUsername)
    return Frontier.GetSecuredPerimeterRing(ownerUsername)
end

function Buildings.TryFinalizeBarricadeRing(ownerUsername, ring)
    local safeOwner = Frontier.GetOwnerUsername(ownerUsername)
    local safeRing = math.max(1, math.floor(tonumber(ring) or 1))
    local currentSecuredRing = Frontier.GetSecuredPerimeterRing(safeOwner)

    if safeRing ~= (currentSecuredRing + 1) then
        return false, 0
    end
    if not Frontier.CanExpandToRing(safeOwner, safeRing) then
        return false, 0
    end
    if not Frontier.IsRingSecured(safeOwner, safeRing) then
        return false, 0
    end

    local removed = Frontier.RetireBarricadeBuildingsForRing(safeOwner, safeRing)
    local mapData = Buildings.GetMapDataForOwner and Buildings.GetMapDataForOwner(safeOwner) or nil
    if mapData then
        mapData.securedRing = safeRing
    end
    if Buildings.UnlockRingFully then
        Buildings.UnlockRingFully(safeOwner, safeRing)
    end
    Buildings.Save()
    return true, removed
end

return Buildings

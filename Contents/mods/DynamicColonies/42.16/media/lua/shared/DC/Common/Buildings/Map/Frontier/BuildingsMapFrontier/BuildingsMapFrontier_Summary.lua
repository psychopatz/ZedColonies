DC_Buildings = DC_Buildings or {}

local Buildings = DC_Buildings
Buildings.Internal = Buildings.Internal or {}

local Frontier = Buildings.Internal.Frontier or {}
Buildings.Internal.Frontier = Frontier

function Buildings.GetTerritorySummary(ownerUsername)
    local owner = Frontier.GetOwnerUsername(ownerUsername)
    local unlockedPlots = Buildings.GetUnlockedPlotEntries(owner)
    local headquartersLevel = Buildings.GetHeadquartersLevel(owner)
    local securedPerimeterRing = Frontier.GetSecuredPerimeterRing(owner)
    local nextFrontierRing = Frontier.GetNextFrontierRing(owner)
    local currentFrontierRing = Frontier.GetActiveFrontierRing(owner)
    local activeBarricades = Buildings.GetActiveBarricadeCount(owner)
    local maxBarricades = Buildings.GetMaxActiveBarricades(owner)

    return {
        ownerUsername = owner,
        headquartersLevel = headquartersLevel,
        securedPerimeterRing = securedPerimeterRing,
        currentFrontierRing = currentFrontierRing > 0 and currentFrontierRing or nextFrontierRing,
        nextFrontierRing = nextFrontierRing,
        frontierExpansionAvailable = currentFrontierRing > 0,
        frontierRequiredHQLevel = nextFrontierRing,
        unlockedPlotCount = #unlockedPlots,
        activeBarricadeCount = activeBarricades,
        maxActiveBarricades = maxBarricades
    }
end

function Buildings.BuildVisibleBounds(plots)
    local bounds = {
        minX = 0,
        maxX = 0,
        minY = 0,
        maxY = 0
    }
    local seeded = false

    for _, plot in ipairs(plots or {}) do
        local x = math.floor(tonumber(plot and plot.x) or 0)
        local y = math.floor(tonumber(plot and plot.y) or 0)
        if not seeded then
            bounds.minX = x
            bounds.maxX = x
            bounds.minY = y
            bounds.maxY = y
            seeded = true
        else
            bounds.minX = math.min(bounds.minX, x)
            bounds.maxX = math.max(bounds.maxX, x)
            bounds.minY = math.min(bounds.minY, y)
            bounds.maxY = math.max(bounds.maxY, y)
        end
    end

    return bounds
end

return Buildings

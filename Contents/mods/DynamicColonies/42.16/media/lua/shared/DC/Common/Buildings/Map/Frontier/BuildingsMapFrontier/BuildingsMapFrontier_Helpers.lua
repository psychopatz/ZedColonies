DC_Buildings = DC_Buildings or {}

local Buildings = DC_Buildings
Buildings.Internal = Buildings.Internal or {}
local Internal = Buildings.Internal

local Frontier = Buildings.Internal.Frontier or {}
Buildings.Internal.Frontier = Frontier

function Frontier.GetOwnerUsername(ownerUsername)
    local colonyConfig = DC_Colony and DC_Colony.Config or nil
    return colonyConfig and colonyConfig.GetOwnerUsername and colonyConfig.GetOwnerUsername(ownerUsername) or tostring(ownerUsername or "local")
end

function Frontier.SortPlotsByPosition(plots)
    table.sort(plots, function(a, b)
        if tonumber(a.y) == tonumber(b.y) then
            return tonumber(a.x) < tonumber(b.x)
        end
        return tonumber(a.y) < tonumber(b.y)
    end)
end

function Frontier.GetCardinalDirections()
    local config = Frontier.Config or Buildings.Config
    local frontierConfig = config and config.Frontier or nil
    return frontierConfig and frontierConfig.CARDINAL_DIRECTIONS or {
        { x = -1, y = 0 },
        { x = 1, y = 0 },
        { x = 0, y = -1 },
        { x = 0, y = 1 }
    }
end

function Frontier.HasCompletedBarricadeAt(ownerUsername, plotX, plotY)
    local x = math.floor(tonumber(plotX) or 0)
    local y = math.floor(tonumber(plotY) or 0)
    local ownerData = Internal.GetOwnerDataIfNormalizing and Internal.GetOwnerDataIfNormalizing(ownerUsername)
        or Buildings.EnsureOwner and Buildings.EnsureOwner(ownerUsername)
        or nil

    for _, instance in ipairs(ownerData and ownerData.buildings or {}) do
        if tostring(instance and instance.buildingType or "") == "Barricade"
            and math.floor(tonumber(instance and instance.level) or 0) > 0
            and math.floor(tonumber(instance and instance.plotX) or 0) == x
            and math.floor(tonumber(instance and instance.plotY) or 0) == y then
            return true
        end
    end

    return false
end

function Frontier.HasUnlockedSupportingNeighbor(ownerUsername, plotX, plotY)
    local x = math.floor(tonumber(plotX) or 0)
    local y = math.floor(tonumber(plotY) or 0)

    for _, direction in ipairs(Frontier.GetCardinalDirections()) do
        local neighborX = x + direction.x
        local neighborY = y + direction.y
        local neighbor = Buildings.GetStoredPlotForOwner(ownerUsername, neighborX, neighborY)
        if neighbor and neighbor.unlocked == true then
            return true
        end
    end

    return false
end

return Buildings

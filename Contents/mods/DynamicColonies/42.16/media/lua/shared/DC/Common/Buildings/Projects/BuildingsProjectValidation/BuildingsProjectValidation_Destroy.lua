DC_Buildings = DC_Buildings or {}
DC_Buildings.Internal = DC_Buildings.Internal or {}

local Buildings = DC_Buildings
local Internal = Buildings.Internal
local Validation = Internal.ProjectValidation or {}

Internal.ProjectValidation = Validation

function Buildings.CanDestroyBuilding(ownerUsername, plotX, plotY, buildingID)
    local owner = Validation.GetOwnerUsername(ownerUsername)
    local x = math.floor(tonumber(plotX) or 0)
    local y = math.floor(tonumber(plotY) or 0)
    local building = Buildings.FindBuildingAtPlot(owner, x, y)
    if not building or math.floor(tonumber(building.level) or 0) <= 0 then
        return false, "There is no completed building on that plot.", nil
    end
    if buildingID and tostring(building.buildingID or "") ~= tostring(buildingID) then
        return false, "That building no longer matches the selected plot.", nil
    end
    if tostring(building.buildingType or "") == "Headquarters" then
        return false, "Headquarters cannot be destroyed.", nil
    end
    if Buildings.GetActiveProjectAtPlot(owner, x, y) then
        return false, "You cannot destroy a building while a project is active on that plot.", nil
    end
    if tostring(building.buildingType or "") == "Barricade" then
        if not Validation.HasCompletedOuterBarricade(owner, x, y) then
            return false, "This barricade stays locked until the next ring has a completed barricade enclosing it from outside.", nil
        end
    end
    return true, nil, building
end

return Buildings
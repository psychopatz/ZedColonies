DC_Colony = DC_Colony or {}
DC_Colony.Research = DC_Colony.Research or {}
DC_Colony.Research.Internal = DC_Colony.Research.Internal or {}

local Research = DC_Colony.Research
local Internal = Research.Internal
local AbstractInventory = DC_Colony.AbstractInventory
local Warehouse = DC_Colony.Warehouse

local function hasUnlockedBuilding(ownerUsername, buildingType, buildingID)
    local buildings = DC_Buildings
    if not (buildings and buildings.GetBuildingsForOwner) then
        return false
    end

    if buildingID and buildings.FindBuildingForOwner then
        local exact = buildings.FindBuildingForOwner(ownerUsername, buildingID)
        if exact and tostring(exact.buildingType or "") == tostring(buildingType or "")
            and math.floor(tonumber(exact.level) or 0) > 0 then
            return true
        end
    end

    for _, instance in ipairs(buildings.GetBuildingsForOwner(ownerUsername) or {}) do
        if tostring(instance and instance.buildingType or "") == tostring(buildingType or "")
            and math.floor(tonumber(instance and instance.level) or 0) > 0 then
            return true
        end
    end

    return false
end

function Research.CraftUnlockedItem(ownerUsername, buildingID, fullType, qty)
    local blueprint = Research.GetBlueprint(ownerUsername, fullType)
    if not blueprint then
        return false, "Blueprint not unlocked."
    end
    if not hasUnlockedBuilding(ownerUsername, blueprint.buildingType, buildingID) then
        return false, "Required colony building is not available."
    end

    local count = math.max(1, math.floor(tonumber(qty) or 1))
    local requirements = {}
    for _, input in ipairs(blueprint.inputs or {}) do
        requirements[#requirements + 1] = {
            category = input.category,
            count = math.max(1, math.floor(tonumber(input.count) or 1)) * count,
        }
    end

    if not (AbstractInventory and AbstractInventory.ConsumeCategories and AbstractInventory.ConsumeCategories(ownerUsername, requirements, {
        reason = "blueprint_craft",
        buildingID = buildingID,
        fullType = fullType,
    })) then
        return false, "Missing abstract inputs."
    end

    if Warehouse and Warehouse.DepositOutputEntry then
        Warehouse.DepositOutputEntry(ownerUsername, {
            fullType = tostring(fullType or ""),
            qty = count,
            forceLiteral = true,
        })
    end

    return true, nil
end

return Research

DC_Colony = DC_Colony or {}
DC_Colony.Research = DC_Colony.Research or {}
DC_Colony.Research.Internal = DC_Colony.Research.Internal or {}

local Research = DC_Colony.Research
local Internal = Research.Internal

local function resolveBuildingForCategory(categoryId, group)
    local category = tostring(categoryId or "")
    local categoryGroup = tostring(group or "")
    if categoryGroup == "Defense" then
        return "Armory"
    end
    if categoryGroup == "Clothing" then
        return "Workshop"
    end
    if categoryGroup == "Food" then
        return "Kitchen"
    end
    if categoryGroup == "Medical" then
        return "Infirmary"
    end
    if categoryGroup == "Electronics" or categoryGroup == "Power" then
        return "Laboratory"
    end
    if category == "Books" or category == "Schematics" then
        return "ResearchStation"
    end
    return "Workshop"
end

local function buildBlueprintInputs(categoryId, group)
    local category = tostring(categoryId or "")
    local categoryGroup = tostring(group or "")

    if categoryGroup == "Defense" then
        return {
            { category = "WeaponParts", count = 1 },
            { category = "Metal", count = 1 },
        }
    end
    if categoryGroup == "Clothing" then
        return {
            { category = "Cloth", count = 2 },
        }
    end
    if categoryGroup == "Food" then
        if category == "FineMeal" then
            return {
                { category = "Meal", count = 1 },
                { category = "Spice", count = 1 },
            }
        end
        if category == "Meal" then
            return {
                { category = "CookableProduce", count = 1 },
                { category = "CookableMeat", count = 1 },
                { category = "Water", count = 1 },
            }
        end
        return {
            { category = category, count = 1 },
        }
    end
    if categoryGroup == "Medical" then
        return {
            { category = "MedicalSupplies", count = 1 },
            { category = "Water", count = 1 },
        }
    end
    if categoryGroup == "Electronics" then
        return {
            { category = "ElectronicParts", count = 1 },
            { category = "PowerParts", count = 1 },
        }
    end
    if categoryGroup == "Power" then
        return {
            { category = "Metal", count = 1 },
            { category = "ElectronicParts", count = 1 },
        }
    end
    if categoryGroup == "Storage" then
        return {
            { category = "Cloth", count = 1 },
            { category = "Hardware", count = 1 },
        }
    end
    if categoryGroup == "Tool" then
        return {
            { category = "Metal", count = 1 },
            { category = "ToolParts", count = 1 },
        }
    end
    if categoryGroup == "Material" then
        return {
            { category = category, count = 1 },
        }
    end

    return {
        { category = category, count = 1 },
    }
end

function Research.GetBlueprint(ownerUsername, fullType)
    local data = Internal.EnsureOwnerData(ownerUsername)
    return data and data.blueprints and data.blueprints[tostring(fullType or "")] or nil
end

function Research.IsBlueprintUnlocked(ownerUsername, fullType)
    return Research.GetBlueprint(ownerUsername, fullType) ~= nil
end

function Internal.BuildBlueprintRecord(fullType)
    local converted = DC_Colony and DC_Colony.Config and DC_Colony.Config.GetItemCategoryData
        and DC_Colony.Config.GetItemCategoryData(fullType) or nil
    local categoryId = tostring(converted and converted.category or "Junk")
    local group = tostring(converted and converted.group or "Waste")
    return {
        fullType = tostring(fullType or ""),
        category = categoryId,
        group = group,
        buildingType = resolveBuildingForCategory(categoryId, group),
        inputs = buildBlueprintInputs(categoryId, group),
        workCost = math.max(1, math.floor(tonumber(Research.Config and Research.Config.BaseHours) or 8)),
    }
end

return Research

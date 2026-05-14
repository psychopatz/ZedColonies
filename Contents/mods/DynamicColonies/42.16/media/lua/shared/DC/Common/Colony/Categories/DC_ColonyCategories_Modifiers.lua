DC_Colony = DC_Colony or {}
DC_Colony.Categories = DC_Colony.Categories or {}

local Config = DC_Colony.Config
local Categories = DC_Colony.Categories

local orderedMappings = {
    { "Rarity.Common", "Common" },
    { "Rarity.Uncommon", "Uncommon" },
    { "Rarity.Rare", "Rare" },
    { "Rarity.Legendary", "Legendary" },
    { "Quality.Luxury", "Luxury" },
    { "Quality.Waste", "Waste" },
    { "Tool.Durable", "Durable" },
    { "Tool.Fragile", "Fragile" },
    { "Food.HighNutrition", "HighNutrition" },
    { "Food.LowNutrition", "LowNutrition" },
}

local function appendModifier(result, seen, modifier)
    local key = tostring(modifier or "")
    if key == "" or seen[key] == true then
        return
    end
    seen[key] = true
    result[#result + 1] = key
end

function Categories.ExtractModifiers(tagList)
    local result = {}
    local seen = {}

    for _, mapping in ipairs(orderedMappings) do
        local query = mapping[1]
        local modifier = mapping[2]
        if Config.HasMatchingTag and Config.HasMatchingTag(tagList, query) then
            appendModifier(result, seen, modifier)
        end
    end

    return result
end

return Categories

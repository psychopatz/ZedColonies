DC_Buildings = DC_Buildings or {}
DC_Buildings.Internal = DC_Buildings.Internal or {}

local Internal = DC_Buildings.Internal

-- Static description strings keyed by buildingType.
-- These are presentation-only; no state is read or mutated here.
local DescriptionTexts = {
    Headquarters = "Establishes the settlement core. Unsafe-zone growth expands in circular frontier rings as you secure barricades around the perimeter.",
    ResearchStation = "Analyzes physical craftable specimens and unlocks colony blueprints based on their real crafting recipes.",
    Recycler = "Breaks down crafted items into recoverable ingredients. Better colony crafters reclaim more of the original materials.",
    Barracks = "Provides housing for your workers and improves recovery for the occupants living inside.",
    Warehouse = "Expands total warehouse storage for your settlement. Higher levels unlock extra storage installations.",
    WaterCollector = "A unique colony rain catcher that stores water and passively fills whenever it rains.",
    WaterTank = "A modular reservoir that expands total colony water storage.",
    Greenhouse = "Protected crop beds for the Farmer job. Plant seeds, set the thermostat, and spend water to raise harvests indoors.",
    ElectricityGenerator = "Reserved for the future electricity grid. The resource card exists now, but power modules are still placeholder.",
    Infirmary = "Treats injured workers while they sleep. Beds expand capacity, and Doctors can use medical provisions to speed recovery.",
    FabricationBench = "General fabrication station for craftable utility and mixed-material items.",
    Forge = "Heavy metalworking station for ore, scrap, ingots, and forged hardware.",
    Cookhouse = "Food preparation station for drinks, preserved goods, cookware recipes, and perishable meals.",
    TextileRoom = "Tailoring and leatherworking room for clothing, bags, and textile components.",
    Woodshop = "Woodworking station for lumber goods, containers, and durable shop tools.",
    TinkerBench = "Electronics bench for batteries, radios, generators, light sources, and small gadgets.",
    Armory = "Weapons workshop for melee arms, firearms, ammo, accessories, explosives, and battlefield chemicals.",
    ProvisionYard = "Field supply yard for farming, fishing, and fresh produce processing.",
    FuelDepot = "Fuel handling depot for solid, liquid, and gas energy stock.",
}

-- Builds the effectLines list for a known buildingType using live effects values.
-- effects: the preview.effects table from BuildProjectPreview (read-only).
local function buildEffectLines(buildingType, effects)
    local lines = {}
    effects = type(effects) == "table" and effects or {}

    if buildingType == "Headquarters" then
        lines[#lines + 1] = "Expansion Rule: complete every barricade slot on the current ring to reveal the next ring"
        lines[#lines + 1] = "Frontier Capacity: scales with the active ring perimeter"
    elseif buildingType == "Barracks" then
        if effects.housingSlots then
            lines[#lines + 1] = "Housing Slots: " .. tostring(effects.housingSlots)
        end
        if effects.recoveryMultiplier then
            lines[#lines + 1] = "Recovery Multiplier: x" .. tostring(effects.recoveryMultiplier)
        end
    elseif buildingType == "Warehouse" then
        if effects.warehouseBaseBonus then
            lines[#lines + 1] = "Base Capacity Bonus: +" .. tostring(effects.warehouseBaseBonus)
        end
        lines[#lines + 1] = "Only one Warehouse can exist in each ring band."
    elseif buildingType == "WaterCollector" then
        if effects.waterStorageBonus then
            lines[#lines + 1] = "Water Storage: +" .. tostring(effects.waterStorageBonus)
        end
        if effects.waterCollectionRate then
            lines[#lines + 1] = "Rain Collection: +" .. tostring(effects.waterCollectionRate) .. " / hour"
        end
        lines[#lines + 1] = "Only one Water Collector can exist per colony."
    elseif buildingType == "WaterTank" then
        if effects.waterStorageBonus then
            lines[#lines + 1] = "Water Storage: +" .. tostring(effects.waterStorageBonus)
        end
    elseif buildingType == "Greenhouse" then
        if effects.gardenSlots then
            lines[#lines + 1] = "Garden Slots: " .. tostring(effects.gardenSlots)
        end
        if effects.greenhouseWaterPerDayPerSlot then
            lines[#lines + 1] = "Water Use: " .. tostring(effects.greenhouseWaterPerDayPerSlot) .. " / day per planted slot"
        end
    elseif buildingType == "ElectricityGenerator" then
        lines[#lines + 1] = "Coming soon."
    elseif buildingType == "Infirmary" then
        if effects.infirmaryBaseCapacity then
            lines[#lines + 1] = "Base Medical Slots: +" .. tostring(effects.infirmaryBaseCapacity)
        end
        if effects.infirmaryCapacityCap then
            lines[#lines + 1] = "Medical Slot Cap: " .. tostring(effects.infirmaryCapacityCap)
        end
    elseif buildingType == "ResearchStation" then
        if effects.researchQueueSlots then
            lines[#lines + 1] = "Research Queue Slots: " .. tostring(effects.researchQueueSlots)
        end
        lines[#lines + 1] = "Accepts craftable Dynamic Trading items with a resolvable recipe."
    elseif buildingType == "Recycler" then
        if effects.recyclerSlots then
            lines[#lines + 1] = "Recycler Slots: +" .. tostring(effects.recyclerSlots)
        end
        lines[#lines + 1] = "Reclaims a random share of recipe materials from supported crafted items."
    elseif buildingType == "FabricationBench"
        or buildingType == "Forge"
        or buildingType == "Cookhouse"
        or buildingType == "TextileRoom"
        or buildingType == "Woodshop"
        or buildingType == "TinkerBench"
        or buildingType == "Armory"
        or buildingType == "ProvisionYard"
        or buildingType == "FuelDepot" then
        if effects.productionSlots then
            lines[#lines + 1] = "Production Slots: +" .. tostring(effects.productionSlots)
        end
        lines[#lines + 1] = "Used as a dedicated crafting station for researched real-item blueprints."
    end

    return lines
end

-- Returns { description, effectLines } for use in BuildPlotBuildOptions.
-- Falls back to a generic placeholder for unknown building types.
function Internal.GetBuildOptionText(buildingType, effects)
    local bt = tostring(buildingType or "")
    if DescriptionTexts[bt] then
        return {
            description = DescriptionTexts[bt],
            effectLines = buildEffectLines(bt, effects),
        }
    end
    return {
        description = "Planned for a future update. This building is shown as a placeholder for expansion.",
        effectLines = { "Currently unavailable in this build." },
    }
end

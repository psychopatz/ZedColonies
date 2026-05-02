DC_Buildings = DC_Buildings or {}
DC_Buildings.Internal = DC_Buildings.Internal or {}

local Internal = DC_Buildings.Internal

-- Static description strings keyed by buildingType.
-- These are presentation-only; no state is read or mutated here.
local DescriptionTexts = {
    Headquarters = "Establishes the settlement core. Unsafe-zone growth expands in circular frontier rings as you secure barricades around the perimeter.",
    Barracks = "Provides housing for your workers and improves recovery for the occupants living inside.",
    Warehouse = "Expands total warehouse storage for your settlement. Higher levels unlock extra storage installations.",
    WaterCollector = "A unique colony rain catcher that stores water and passively fills whenever it rains.",
    WaterTank = "A modular reservoir that expands total colony water storage.",
    Greenhouse = "Protected crop beds for the Farmer job. Plant seeds, set the thermostat, and spend water to raise harvests indoors.",
    ElectricityGenerator = "Reserved for the future electricity grid. The resource card exists now, but power modules are still placeholder.",
    Infirmary = "Treats injured workers while they sleep. Beds expand capacity, and Doctors can use medical provisions to speed recovery.",
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

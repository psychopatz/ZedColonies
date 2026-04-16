DC_Colony = DC_Colony or {}
DC_Colony.Resources = DC_Colony.Resources or {}
DC_Colony.Resources.Internal = DC_Colony.Resources.Internal or {}

local Buildings = DC_Buildings
local Resources = DC_Colony.Resources
local Internal = Resources.Internal

function Resources.GetGreenhouseSlotCountForLevel(level)
    local levelDefinition = Buildings.Config.GetLevelDefinition and Buildings.Config.GetLevelDefinition("Greenhouse", level) or nil
    return math.max(0, math.floor(tonumber(levelDefinition and levelDefinition.effects and levelDefinition.effects.gardenSlots) or 0))
end

function Resources.GetGreenhouseWaterPerDayForLevel(level)
    local levelDefinition = Buildings.Config.GetLevelDefinition and Buildings.Config.GetLevelDefinition("Greenhouse", level) or nil
    return math.max(0, tonumber(levelDefinition and levelDefinition.effects and levelDefinition.effects.greenhouseWaterPerDayPerSlot) or 0)
end

function Resources.NormalizeGreenhouseStates(ownerUsername)
    local owner = Internal.GetAuthorityOwner(ownerUsername)
    local ownerData = Resources.EnsureOwner(owner)
    local validIDs = {}

    for _, instance in ipairs(Buildings.GetBuildingsForOwner and Buildings.GetBuildingsForOwner(owner) or {}) do
        if tostring(instance and instance.buildingType or "") == "Greenhouse" and math.floor(tonumber(instance and instance.level) or 0) > 0 then
            local buildingID = tostring(instance.buildingID or "")
            local slotCount = Resources.GetGreenhouseSlotCountForLevel(instance.level)
            if buildingID ~= "" and slotCount > 0 then
                validIDs[buildingID] = true
                local state = type(ownerData.greenhouses[buildingID]) == "table" and ownerData.greenhouses[buildingID] or {
                    thermostatC = 20,
                    slots = {}
                }
                state.thermostatC = Internal.ClampNumber(state.thermostatC, 0, 40)
                local normalizedSlots = {}
                for slotIndex = 1, slotCount do
                    normalizedSlots[slotIndex] = Internal.NormalizeSlot(state.slots and state.slots[slotIndex], slotIndex)
                end
                state.slots = normalizedSlots
                ownerData.greenhouses[buildingID] = state
            end
        end
    end

    for buildingID, _ in pairs(ownerData.greenhouses or {}) do
        if not validIDs[tostring(buildingID or "")] then
            ownerData.greenhouses[buildingID] = nil
        end
    end

    return ownerData
end

function Internal.GetGreenhouseState(ownerUsername, buildingID)
    local ownerData = Resources.NormalizeGreenhouseStates(ownerUsername)
    return ownerData.greenhouses and ownerData.greenhouses[tostring(buildingID or "")] or nil
end
DC_Colony = DC_Colony or {}
DC_Colony.Resources = DC_Colony.Resources or {}
DC_Colony.Resources.Internal = DC_Colony.Resources.Internal or {}

local Resources = DC_Colony.Resources
local Internal = Resources.Internal

function Resources.SetGreenhouseThermostat(ownerUsername, buildingID, thermostatC)
    local owner = Internal.GetAuthorityOwner(ownerUsername)
    local state = Internal.GetGreenhouseState(owner, buildingID)
    if not state then
        return false, "That greenhouse is no longer available."
    end

    state.thermostatC = Internal.ClampNumber(thermostatC, 0, 40)
    Resources.Save(owner)
    return true, nil
end

function Resources.ClearGreenhouseSlot(ownerUsername, buildingID, slotIndex)
    local owner = Internal.GetAuthorityOwner(ownerUsername)
    local state = Internal.GetGreenhouseState(owner, buildingID)
    if not state or not state.slots or not state.slots[slotIndex] then
        return false, "That greenhouse slot is invalid."
    end

    state.slots[slotIndex] = Internal.NormalizeSlot(nil, slotIndex)
    Resources.Save(owner)
    return true, nil
end

function Resources.PlantGreenhouseSlot(player, buildingID, slotIndex, seedFullType)
    local owner = Internal.GetAuthorityOwner(player)
    local state = Internal.GetGreenhouseState(owner, buildingID)
    if not state or not state.slots or not state.slots[slotIndex] then
        return false, "That greenhouse slot is invalid."
    end

    local slot = state.slots[slotIndex]
    if slot.cropID and slot.state ~= "Dead" and slot.state ~= "Empty" then
        return false, "That slot is already planted."
    end

    local crop = Resources.GetCropForSeedType(seedFullType)
    if not crop then
        return false, "That seed is not supported by the greenhouse."
    end

    if not Resources.ConsumeSeedFromPlayer(player, seedFullType) then
        return false, "That seed was not found in player inventory."
    end

    state.slots[slotIndex] = Internal.NormalizeSlot({
        slotIndex = slotIndex,
        state = "Growing",
        cropID = crop.cropID,
        seedFullType = seedFullType,
        growthHours = 0,
        health = 100
    }, slotIndex)

    Resources.Save(owner)
    return true, nil
end
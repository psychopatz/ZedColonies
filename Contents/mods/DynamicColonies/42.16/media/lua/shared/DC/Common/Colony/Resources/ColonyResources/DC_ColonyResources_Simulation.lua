DC_Colony = DC_Colony or {}
DC_Colony.Resources = DC_Colony.Resources or {}
DC_Colony.Resources.Internal = DC_Colony.Resources.Internal or {}

local Config = DC_Colony.Config
local Registry = DC_Colony.Registry
local Buildings = DC_Buildings
local Resources = DC_Colony.Resources
local Internal = Resources.Internal

function Internal.ProcessOwner(ownerUsername, currentHour, deltaHours)
    local owner = Internal.GetAuthorityOwner(ownerUsername)
    local ownerData = Resources.NormalizeGreenhouseStates(owner)
    local changed = false
    local capacity = Resources.GetWaterCapacity(owner)
    local stored = math.min(capacity, math.max(0, tonumber(ownerData.waterStored) or 0))

    local raining, rainIntensity = Internal.GetRainState()
    if raining and deltaHours > 0 then
        local collectionRate = Resources.GetWaterCollectionRatePerHour(owner)
        if collectionRate > 0 then
            local collected = collectionRate * math.max(0.25, rainIntensity) * deltaHours
            local nextStored = math.min(capacity, stored + collected)
            if math.abs(nextStored - stored) > 0.0001 then
                stored = nextStored
                changed = true
            end
        end
    end

    for _, instance in ipairs(Buildings.GetBuildingsForOwner and Buildings.GetBuildingsForOwner(owner) or {}) do
        if tostring(instance and instance.buildingType or "") == "Greenhouse" and math.floor(tonumber(instance and instance.level) or 0) > 0 then
            local state = Internal.GetGreenhouseState(owner, instance.buildingID)
            local perSlotWater = Resources.GetGreenhouseWaterPerDayForLevel(instance.level) / math.max(1, tonumber(Config.HOURS_PER_DAY) or 24)
            for slotIndex, slot in ipairs(state and state.slots or {}) do
                local crop = slot and slot.cropID and Resources.CROP_CATALOG[slot.cropID] or nil
                if crop and slot.state == "Growing" and deltaHours > 0 then
                    local tempOkay = state.thermostatC >= crop.tempMinC and state.thermostatC <= crop.tempMaxC
                    local waterNeeded = perSlotWater * deltaHours
                    local hasWater = stored + 0.0001 >= waterNeeded

                    if tempOkay and hasWater then
                        stored = math.max(0, stored - waterNeeded)
                        slot.growthHours = math.max(0, tonumber(slot.growthHours) or 0) + deltaHours
                        slot.health = Internal.ClampNumber((tonumber(slot.health) or 100) + (deltaHours * 0.75), 0, 100)
                        if slot.growthHours + 0.0001 >= math.max(1, tonumber(crop.growthHours) or 1) then
                            slot.state = "Ready"
                        end
                        changed = true
                    else
                        local decayPerHour = tempOkay and 3 or 7
                        slot.health = Internal.ClampNumber((tonumber(slot.health) or 100) - (decayPerHour * deltaHours), 0, 100)
                        if slot.health <= 0 then
                            state.slots[slotIndex] = Internal.NormalizeSlot({
                                slotIndex = slotIndex,
                                cropID = slot.cropID,
                                seedFullType = slot.seedFullType,
                                growthHours = slot.growthHours,
                                health = 0,
                                state = "Dead"
                            }, slotIndex)
                        end
                        changed = true
                    end
                end
            end
        end
    end

    local clampedStored = math.min(capacity, math.max(0, stored))
    if math.abs(clampedStored - (tonumber(ownerData.waterStored) or 0)) > 0.0001 then
        ownerData.waterStored = clampedStored
        changed = true
    else
        ownerData.waterStored = clampedStored
    end

    ownerData.lastProcessedHour = currentHour
    return changed
end

function Resources.ProcessAllOwners(currentHour)
    if isClient() and not isServer() then
        return false
    end

    local changed = false
    for _, ownerUsername in ipairs(Registry.GetOwnerUsernames and Registry.GetOwnerUsernames() or {}) do
        local ownerData = Resources.EnsureOwner(ownerUsername)
        local lastHour = tonumber(ownerData.lastProcessedHour) or -1
        local deltaHours = 0
        if lastHour >= 0 then
            deltaHours = math.max(0, tonumber(currentHour) - lastHour)
        end

        if lastHour < 0 then
            ownerData.lastProcessedHour = currentHour
            changed = true
        elseif deltaHours > 0 then
            if Internal.ProcessOwner(ownerUsername, currentHour, deltaHours) then
                changed = true
            end
        end
    end

    if changed then
        Resources.Save()
    end

    return changed
end

return Resources
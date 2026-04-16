DC_Colony = DC_Colony or {}
DC_Colony.Resources = DC_Colony.Resources or {}
DC_Colony.Resources.Internal = DC_Colony.Resources.Internal or {}

local Buildings = DC_Buildings
local Resources = DC_Colony.Resources
local Internal = Resources.Internal

function Internal.FindHarvestableSlot(ownerUsername)
    local owner = Internal.GetAuthorityOwner(ownerUsername)
    Resources.NormalizeGreenhouseStates(owner)

    for _, instance in ipairs(Buildings.GetBuildingsForOwner and Buildings.GetBuildingsForOwner(owner) or {}) do
        if tostring(instance and instance.buildingType or "") == "Greenhouse" and math.floor(tonumber(instance and instance.level) or 0) > 0 then
            local state = Internal.GetGreenhouseState(owner, instance.buildingID)
            for _, slot in ipairs(state and state.slots or {}) do
                if slot.cropID and slot.state == "Ready" then
                    return instance, state, slot, Resources.CROP_CATALOG[slot.cropID]
                end
            end
        end
    end

    return nil, nil, nil, nil
end

function Resources.ProcessFarmWorkCycle(worker, ctx)
    local owner = Internal.GetAuthorityOwner(worker and worker.ownerUsername)
    local yieldMultiplier = math.max(0.1, tonumber(ctx and ctx.yieldMultiplier) or 1)
    local greenhouse, state, slot, crop = Internal.FindHarvestableSlot(owner)

    if not greenhouse or not slot or not crop then
        local label = Resources.GetAnyGreenhouseLabel(owner)
        if worker then
            worker.siteState = label
            worker.greenhouseWorkLabel = label
        end
        return {
            entries = {},
            totalQuantity = 0,
            success = false,
            failed = false,
            siteLabel = label
        }
    end

    local qty = ZombRand(crop.harvestMin, crop.harvestMax + 1)
    qty = math.max(1, math.floor((qty * yieldMultiplier) + 0.5))

    local slotIndex = tonumber(slot.slotIndex) or 1
    state.slots[slotIndex] = Internal.NormalizeSlot(nil, slotIndex)
    Resources.Save(owner)

    local label = "Greenhouse " .. tostring(greenhouse.plotX or 0) .. "," .. tostring(greenhouse.plotY or 0)
    if worker then
        worker.siteState = label
        worker.greenhouseWorkLabel = label
    end

    return {
        entries = {
            {
                fullType = crop.produceFullType,
                qty = qty
            }
        },
        totalQuantity = qty,
        success = true,
        failed = false,
        siteLabel = label,
        harvestLabel = crop.displayName
    }
end
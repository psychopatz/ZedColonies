DC_Colony = DC_Colony or {}
DC_Colony.Warehouse = DC_Colony.Warehouse or {}
DC_Colony.Warehouse.Internal = DC_Colony.Warehouse.Internal or {}

local Config = DC_Colony.Config
local Warehouse = DC_Colony.Warehouse

function Warehouse.GetMedicalProvisionUnitTotal(ownerUsername)
    local warehouse = Warehouse.GetOwnerWarehouse(ownerUsername)
    local totalUnits = 0
    for _, entry in ipairs(warehouse and warehouse.ledgers and warehouse.ledgers.provisions or {}) do
        if Config.IsMedicalProvisionEntry and Config.IsMedicalProvisionEntry(entry) then
            totalUnits = totalUnits + (math.max(0, tonumber(entry.treatmentUnitsRemaining) or 0) * math.max(1, tonumber(entry.qty) or 1))
        end
    end
    return totalUnits
end

function Warehouse.GetMedicalProvisionHourBudget(ownerUsername)
    local warehouse = Warehouse.GetOwnerWarehouse(ownerUsername)
    local totalHours = Warehouse.GetMedicalProvisionUnitTotal(ownerUsername) * 8
    local reservedHours = math.max(0, tonumber(warehouse and warehouse.medicalProvisionCarryoverHours) or 0)
    return math.max(0, totalHours - reservedHours)
end

function Warehouse.ConsumeMedicalProvisionHours(ownerUsername, usedHours)
    local hours = math.max(0, tonumber(usedHours) or 0)
    if hours <= 0 then
        return 0
    end

    local warehouse = Warehouse.GetOwnerWarehouse(ownerUsername)
    local totalHours = math.max(0, tonumber(warehouse.medicalProvisionCarryoverHours) or 0) + hours
    local unitsToConsume = math.floor(totalHours / 8)
    warehouse.medicalProvisionCarryoverHours = totalHours - (unitsToConsume * 8)

    if unitsToConsume <= 0 then
        Warehouse.Recalculate(warehouse)
        return 0
    end

    local consumedUnits = 0
    for index = #warehouse.ledgers.provisions, 1, -1 do
        local entry = warehouse.ledgers.provisions[index]
        if Config.IsMedicalProvisionEntry and Config.IsMedicalProvisionEntry(entry) then
            local unitsPerItem = math.max(0, tonumber(entry.treatmentUnitsRemaining) or 0)
            local availableQty = math.max(1, tonumber(entry.qty) or 1)
            local availableUnits = unitsPerItem * availableQty
            if availableUnits > 0 then
                local takeUnits = math.min(availableUnits, unitsToConsume - consumedUnits)
                if takeUnits > 0 then
                    local remainingUnits = availableUnits - takeUnits
                    if remainingUnits <= 0 then
                        table.remove(warehouse.ledgers.provisions, index)
                    else
                        entry.qty = math.max(1, math.ceil(remainingUnits / math.max(1, unitsPerItem)))
                    end
                    consumedUnits = consumedUnits + takeUnits
                    if consumedUnits >= unitsToConsume then
                        break
                    end
                end
            end
        end
    end

    if consumedUnits > 0 then
        Warehouse.TouchItemsVersion(ownerUsername)
        Warehouse.TouchSummaryVersion(ownerUsername)
    end
    Warehouse.Recalculate(warehouse)
    return consumedUnits
end

return Warehouse
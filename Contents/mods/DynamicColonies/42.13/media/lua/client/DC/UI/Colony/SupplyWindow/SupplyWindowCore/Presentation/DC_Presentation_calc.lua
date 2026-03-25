DC_SupplyWindow = DC_SupplyWindow or {}
DC_SupplyWindow.Internal = DC_SupplyWindow.Internal or {}

local Internal = DC_SupplyWindow.Internal

function Internal.getWorkerSupplyTotals(entries)
    local totals = {
        count = 0,
        calories = 0,
        hydration = 0,
        medicalUnits = 0,
        money = 0,
    }

    for _, entry in ipairs(entries or {}) do
        if entry.kind == "money" then
            totals.money = totals.money + math.max(0, math.floor(tonumber(entry.amount) or 0))
        else
            local qty = math.max(1, tonumber(entry.qty) or 1)
            totals.count = totals.count + qty
            totals.calories = totals.calories + ((tonumber(entry.totalCalories) or math.max(0, tonumber(entry.calories) or 0) * qty))
            totals.hydration = totals.hydration + ((tonumber(entry.totalHydration) or math.max(0, tonumber(entry.hydration) or 0) * qty))
            totals.medicalUnits = totals.medicalUnits + ((tonumber(entry.totalTreatmentUnits) or math.max(0, tonumber(entry.treatmentUnits) or 0) * qty))
        end
    end

    return totals
end

function Internal.getEntryWeightTotal(entries)
    local totalWeight = 0
    for _, entry in ipairs(entries or {}) do
        totalWeight = totalWeight + math.max(0, tonumber(entry and entry.totalWeight) or tonumber(entry and entry.unitWeight) or 0)
    end
    return totalWeight
end

function Internal.getWarehouseLedgerWeight(worker, tabID)
    local warehouse = worker and worker.warehouse or nil
    local ledgers = warehouse and warehouse.ledgers or {}
    local config = Internal.Config or {}
    local totalWeight = 0

    if tabID == Internal.Tabs.Provisions then
        for _, entry in ipairs(ledgers.provisions or {}) do
            local qty = math.max(1, tonumber(entry and entry.qty) or 1)
            totalWeight = totalWeight + (math.max(0, tonumber(config.GetItemWeight and config.GetItemWeight(entry and entry.fullType)) or 0) * qty)
        end
        return totalWeight
    end

    if tabID == Internal.Tabs.Equipment then
        for _, entry in ipairs(ledgers.equipment or {}) do
            local qty = math.max(1, tonumber(entry and entry.qty) or 1)
            totalWeight = totalWeight + (math.max(0, tonumber(config.GetItemWeight and config.GetItemWeight(entry and entry.fullType)) or 0) * qty)
        end
        return totalWeight
    end

    for _, entry in ipairs(ledgers.output or {}) do
        local qty = math.max(1, tonumber(entry and entry.qty) or 1)
        totalWeight = totalWeight + (math.max(0, tonumber(config.GetItemWeight and config.GetItemWeight(entry and entry.fullType)) or 0) * qty)
    end
    return totalWeight
end

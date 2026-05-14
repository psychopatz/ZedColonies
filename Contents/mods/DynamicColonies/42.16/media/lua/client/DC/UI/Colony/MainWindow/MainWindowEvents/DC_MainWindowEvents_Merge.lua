DC_MainWindow = DC_MainWindow or {}
DC_MainWindow.Internal = DC_MainWindow.Internal or {}

local EventSync = DC_MainWindow.Internal.Events or {}

function EventSync.copyTable(source)
    if type(source) ~= "table" then
        return nil
    end

    local copy = {}
    for key, value in pairs(source) do
        copy[key] = value
    end
    return copy
end

function EventSync.copyArrayEntries(source)
    if type(source) ~= "table" then
        return nil
    end

    local copy = {}
    for index, value in ipairs(source) do
        if type(value) == "table" then
            copy[index] = EventSync.copyTable(value)
        else
            copy[index] = value
        end
    end
    return copy
end

function EventSync.mergeWarehouseDetail(previousWarehouse, incomingWarehouse)
    if type(incomingWarehouse) ~= "table" then
        return EventSync.copyTable(previousWarehouse) or incomingWarehouse
    end

    local merged = EventSync.copyTable(previousWarehouse) or {}
    for key, value in pairs(incomingWarehouse) do
        merged[key] = value
    end

    if incomingWarehouse.ledgers == nil and type(previousWarehouse) == "table" and type(previousWarehouse.ledgers) == "table" then
        merged.ledgers = EventSync.copyTable(previousWarehouse.ledgers)
        if type(previousWarehouse.ledgers.provisions) == "table" then
            merged.ledgers.provisions = EventSync.copyArrayEntries(previousWarehouse.ledgers.provisions)
        end
        if type(previousWarehouse.ledgers.equipment) == "table" then
            merged.ledgers.equipment = EventSync.copyArrayEntries(previousWarehouse.ledgers.equipment)
        end
        if type(previousWarehouse.ledgers.output) == "table" then
            merged.ledgers.output = EventSync.copyArrayEntries(previousWarehouse.ledgers.output)
        end
    elseif type(incomingWarehouse.ledgers) == "table" then
        local previousLedgers = type(previousWarehouse) == "table" and type(previousWarehouse.ledgers) == "table" and previousWarehouse.ledgers or {}
        merged.ledgers = {
            provisions = type(incomingWarehouse.ledgers.provisions) == "table"
                and EventSync.copyArrayEntries(incomingWarehouse.ledgers.provisions)
                or EventSync.copyArrayEntries(previousLedgers.provisions)
                or {},
            equipment = type(incomingWarehouse.ledgers.equipment) == "table"
                and EventSync.copyArrayEntries(incomingWarehouse.ledgers.equipment)
                or EventSync.copyArrayEntries(previousLedgers.equipment)
                or {},
            output = type(incomingWarehouse.ledgers.output) == "table"
                and EventSync.copyArrayEntries(incomingWarehouse.ledgers.output)
                or EventSync.copyArrayEntries(previousLedgers.output)
                or {},
        }
    end

    return merged
end

function EventSync.mergeWorkerDetail(previousWorker, incomingWorker)
    if type(incomingWorker) ~= "table" then
        return incomingWorker
    end

    local merged = EventSync.copyTable(previousWorker) or {}
    for key, value in pairs(incomingWorker) do
        merged[key] = value
    end

    if incomingWorker.moneyStored == nil and type(previousWorker) == "table" then
        merged.moneyStored = previousWorker.moneyStored
    end
    if incomingWorker.ownerUsername == nil and type(previousWorker) == "table" then
        merged.ownerUsername = previousWorker.ownerUsername
    end

    if incomingWorker.nutritionLedger == nil and type(previousWorker) == "table" then
        merged.nutritionLedger = EventSync.copyArrayEntries(previousWorker.nutritionLedger)
    end
    if incomingWorker.skills == nil and type(previousWorker) == "table" then
        merged.skills = previousWorker.skills
    end
    if incomingWorker.toolLedger == nil and type(previousWorker) == "table" then
        merged.toolLedger = EventSync.copyArrayEntries(previousWorker.toolLedger)
    end
    if incomingWorker.haulLedger == nil and type(previousWorker) == "table" then
        merged.haulLedger = EventSync.copyArrayEntries(previousWorker.haulLedger)
    end
    if incomingWorker.outputLedger == nil and type(previousWorker) == "table" then
        merged.outputLedger = EventSync.copyArrayEntries(previousWorker.outputLedger)
    end
    if type(incomingWorker.nutritionLedger) == "table" then
        merged.nutritionLedger = EventSync.copyArrayEntries(incomingWorker.nutritionLedger)
    end
    if type(incomingWorker.toolLedger) == "table" then
        merged.toolLedger = EventSync.copyArrayEntries(incomingWorker.toolLedger)
    end
    if type(incomingWorker.haulLedger) == "table" then
        merged.haulLedger = EventSync.copyArrayEntries(incomingWorker.haulLedger)
    end
    if type(incomingWorker.outputLedger) == "table" then
        merged.outputLedger = EventSync.copyArrayEntries(incomingWorker.outputLedger)
    end

    if incomingWorker.warehouse == nil then
        if type(previousWorker) == "table" and previousWorker.warehouse ~= nil then
            merged.warehouse = EventSync.copyTable(previousWorker.warehouse) or previousWorker.warehouse
        end
    else
        merged.warehouse = EventSync.mergeWarehouseDetail(previousWorker and previousWorker.warehouse, incomingWorker.warehouse)
    end

    return merged
end

DC_MainWindow.MergeWorkerDetail = EventSync.mergeWorkerDetail

return EventSync

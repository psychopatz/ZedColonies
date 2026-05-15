DC_Colony = DC_Colony or {}
DC_Colony.Warehouse = DC_Colony.Warehouse or {}
DC_Colony.Warehouse.Internal = DC_Colony.Warehouse.Internal or {}

local Config = DC_Colony.Config
local Registry = DC_Colony.Registry
local Warehouse = DC_Colony.Warehouse
local Internal = Warehouse.Internal
local Data = Internal.Data or {}

Internal.Data = Data

local function normalizeLedgerMask(includeLedgers, ledgerMask)
    if type(ledgerMask) == "table" then
        local normalized = {}
        if ledgerMask.provisions == true then
            normalized.provisions = true
        end
        if ledgerMask.equipment == true then
            normalized.equipment = true
        end
        if ledgerMask.output == true then
            normalized.output = true
        end
        for _key, _value in pairs(normalized) do
            return normalized
        end
    end

    if includeLedgers == true then
        return {
            provisions = true,
            equipment = true,
            output = true,
        }
    end

    return nil
end

function Warehouse.GetClientSummary(ownerUsername)
    local warehouse = Warehouse.GetOwnerWarehouse(ownerUsername)
    if not warehouse then
        return nil
    end

    local summary = warehouse.__summary or warehouse
    return {
        colonyID = summary.colonyID,
        ownerUsername = summary.ownerUsername,
        version = summary.version,
        itemsVersion = warehouse.__items and warehouse.__items.version or 1,
        capacityBase = summary.capacityBase,
        manualCapacityBonus = summary.manualCapacityBonus,
        buildingCapacityBonus = summary.buildingCapacityBonus,
        capacityBonus = summary.capacityBonus,
        maxWeight = summary.maxWeight,
        usedWeight = summary.usedWeight,
        remainingWeight = summary.remainingWeight,
        upgradeLevel = summary.upgradeLevel,
        autoEquipEnabled = summary.autoEquipEnabled == true,
        counts = Registry.Internal.CopyShallow(summary.counts or {}),
        inventoryVersion = math.max(1, math.floor(tonumber(summary.inventoryVersion) or 1)),
        inventoryItemCount = math.max(0, math.floor(tonumber(summary.inventoryItemCount) or 0)),
        inventoryCategoryCount = math.max(0, math.floor(tonumber(summary.inventoryCategoryCount) or 0)),
        inventoryLiteralSpecialCount = math.max(0, math.floor(tonumber(summary.inventoryLiteralSpecialCount) or 0)),
        inventoryRowCount = math.max(0, math.floor(tonumber(summary.inventoryRowCount) or 0)),
        inventoryWeight = math.max(0, tonumber(summary.inventoryWeight) or 0),
        inventoryCalories = math.max(0, tonumber(summary.inventoryCalories) or 0),
        inventoryHydration = math.max(0, tonumber(summary.inventoryHydration) or 0),
        provisionCalories = math.max(0, tonumber(summary.provisionCalories) or 0),
        provisionHydration = math.max(0, tonumber(summary.provisionHydration) or 0),
        totalItemCount = math.max(0, math.floor(tonumber(summary.totalItemCount) or 0)),
        totalCalories = math.max(0, tonumber(summary.totalCalories) or 0),
        totalHydration = math.max(0, tonumber(summary.totalHydration) or 0),
    }
end

function Warehouse.GetClientSnapshot(ownerUsername, includeLedgers, ledgerMask)
    local snapshot = Warehouse.GetClientSummary(ownerUsername)
    if not snapshot then
        return nil
    end

    local normalizedMask = normalizeLedgerMask(includeLedgers, ledgerMask)
    if not normalizedMask then
        return snapshot
    end

    local warehouse = Warehouse.GetOwnerWarehouse(ownerUsername)
    snapshot.ledgers = {}
    if normalizedMask.provisions == true then
        snapshot.ledgers.provisions = Data.CopyArray(warehouse.ledgers.provisions)
    end
    if normalizedMask.equipment == true then
        snapshot.ledgers.equipment = Data.CopyArray(warehouse.ledgers.equipment)
    end
    if normalizedMask.output == true then
        snapshot.ledgers.output = Data.CopyArray(warehouse.ledgers.output)
    end
    return snapshot
end

function Warehouse.GetAutoEquipEnabled(ownerUsername)
    local warehouse = Warehouse.GetOwnerWarehouse(ownerUsername)
    return warehouse and warehouse.autoEquipEnabled == true or false
end

function Warehouse.SetAutoEquipEnabled(ownerUsername, enabled)
    local owner = Config.GetOwnerUsername(ownerUsername)
    local summary = Data.EnsureSummary(owner)
    local normalized = enabled == true
    if summary.autoEquipEnabled == normalized then
        return normalized
    end

    summary.autoEquipEnabled = normalized
    Warehouse.TouchSummaryVersion(owner)
    Warehouse.Recalculate(Data.GetCombinedWarehouse(owner))
    return normalized
end

return Warehouse

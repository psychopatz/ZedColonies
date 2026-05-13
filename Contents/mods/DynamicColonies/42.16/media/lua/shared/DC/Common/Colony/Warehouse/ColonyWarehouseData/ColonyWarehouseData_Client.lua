DC_Colony = DC_Colony or {}
DC_Colony.Warehouse = DC_Colony.Warehouse or {}
DC_Colony.Warehouse.Internal = DC_Colony.Warehouse.Internal or {}

local Config = DC_Colony.Config
local Registry = DC_Colony.Registry
local Warehouse = DC_Colony.Warehouse
local Internal = Warehouse.Internal
local Data = Internal.Data or {}

Internal.Data = Data

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
        counts = Registry.Internal.CopyShallow(summary.counts or {})
    }
end

function Warehouse.GetClientSnapshot(ownerUsername, includeLedgers)
    local snapshot = Warehouse.GetClientSummary(ownerUsername)
    if not snapshot then
        return nil
    end

    if includeLedgers ~= true then
        return snapshot
    end

    local warehouse = Warehouse.GetOwnerWarehouse(ownerUsername)
    snapshot.ledgers = {
        provisions = Data.CopyArray(warehouse.ledgers.provisions),
        equipment = Data.CopyArray(warehouse.ledgers.equipment),
        output = Data.CopyArray(warehouse.ledgers.output)
    }
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
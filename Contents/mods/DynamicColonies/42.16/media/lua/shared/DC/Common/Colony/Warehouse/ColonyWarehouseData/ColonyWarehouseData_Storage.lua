DC_Colony = DC_Colony or {}
DC_Colony.Warehouse = DC_Colony.Warehouse or {}
DC_Colony.Warehouse.Internal = DC_Colony.Warehouse.Internal or {}

local Config = DC_Colony.Config
local Registry = DC_Colony.Registry
local Warehouse = DC_Colony.Warehouse
local Internal = Warehouse.Internal
local Data = Internal.Data or {}

Internal.Data = Data

function Data.NormalizeSummary(colonyID, ownerUsername, summary)
    summary.__summary = nil
    summary.__items = nil
    summary.ledgers = nil

    summary.schemaVersion = Config.MOD_DATA_SCHEMA_VERSION or 3
    summary.colonyID = tostring(colonyID)
    summary.ownerUsername = Config.GetOwnerUsername(ownerUsername or summary.ownerUsername)
    summary.version = math.max(1, math.floor(tonumber(summary.version) or 1))
    summary.capacityBase = math.max(0, tonumber(summary.capacityBase) or tonumber(Config.DEFAULT_WAREHOUSE_CAPACITY) or 100)
    summary.manualCapacityBonus = math.max(0, tonumber(summary.manualCapacityBonus) or tonumber(summary.capacityBonus) or 0)
    summary.buildingCapacityBonus = math.max(0, tonumber(summary.buildingCapacityBonus) or 0)
    summary.capacityBonus = math.max(0, tonumber(summary.capacityBonus) or 0)
    summary.upgradeLevel = math.max(0, math.floor(tonumber(summary.upgradeLevel) or 0))
    summary.autoEquipEnabled = summary.autoEquipEnabled == true
    summary.medicalProvisionCarryoverHours = math.max(0, tonumber(summary.medicalProvisionCarryoverHours) or 0)
    summary.maxWeight = math.max(0, tonumber(summary.maxWeight) or 0)
    summary.usedWeight = math.max(0, tonumber(summary.usedWeight) or 0)
    summary.remainingWeight = math.max(0, tonumber(summary.remainingWeight) or 0)
    summary.counts = type(summary.counts) == "table" and summary.counts or {}
    summary.counts.provisions = math.max(0, math.floor(tonumber(summary.counts.provisions) or 0))
    summary.counts.equipment = math.max(0, math.floor(tonumber(summary.counts.equipment) or 0))
    summary.counts.output = math.max(0, math.floor(tonumber(summary.counts.output) or 0))
    summary.counts.categories = math.max(0, math.floor(tonumber(summary.counts.categories) or 0))
    summary.counts.special = math.max(0, math.floor(tonumber(summary.counts.special) or 0))
    return summary
end

function Data.NormalizeItems(colonyID, items)
    items.__summary = nil
    items.__items = nil

    items.schemaVersion = Data.GetWarehouseItemsSchemaVersion and Data.GetWarehouseItemsSchemaVersion() or (Config.MOD_DATA_SCHEMA_VERSION or 4)
    items.colonyID = tostring(colonyID)
    items.version = math.max(1, math.floor(tonumber(items.version) or 1))
    items.legacyOutputMigrationComplete = items.legacyOutputMigrationComplete == true
    items.abstractStock = Data.NormalizeAbstractStock(items.abstractStock)
    items.literalSpecialStock = Data.NormalizeLiteralSpecialStock(items.literalSpecialStock)
    items.ledgers = type(items.ledgers) == "table" and items.ledgers or {}
    items.ledgers.provisions = Data.StackProvisionEntries(items.ledgers.provisions)
    items.ledgers.equipment = Data.StackEquipmentEntries(items.ledgers.equipment)
    items.ledgers.output = Data.StackOutputEntries(items.ledgers.output)
    Data.MigrateLegacyOutputLedger(items)
    return items
end

function Data.EnsureSummary(ownerUsername)
    local colonyID = Registry.GetColonyIDForOwner(ownerUsername, true)
    return Data.NormalizeSummary(
        colonyID,
        ownerUsername,
        Registry.Internal.EnsureModDataTable(Data.GetSummaryKey(colonyID), Data.BuildEmptySummary(colonyID, ownerUsername))
    )
end

function Data.EnsureItems(ownerUsername)
    local colonyID = Registry.GetColonyIDForOwner(ownerUsername, true)
    return Data.NormalizeItems(
        colonyID,
        Registry.Internal.EnsureModDataTable(Data.GetItemsKey(colonyID), Data.BuildEmptyItems(colonyID))
    )
end

function Data.GetCombinedWarehouse(ownerUsername)
    local owner = Config.GetOwnerUsername(ownerUsername)
    local colonyID = Registry.GetColonyIDForOwner(owner, true)
    local summary = Data.EnsureSummary(owner)
    local items = Data.EnsureItems(owner)
    local combined = Registry.Internal.CopyShallow(summary)
    combined.colonyID = colonyID
    combined.ownerUsername = owner
    combined.__summary = summary
    combined.__items = items
    combined.abstractStock = items.abstractStock
    combined.literalSpecialStock = items.literalSpecialStock
    combined.ledgers = items.ledgers
    return combined
end

return Warehouse

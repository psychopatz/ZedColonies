DC_Colony = DC_Colony or {}
DC_Colony.Warehouse = DC_Colony.Warehouse or {}
DC_Colony.Warehouse.Internal = DC_Colony.Warehouse.Internal or {}

local Config = DC_Colony.Config
local Registry = DC_Colony.Registry
local Warehouse = DC_Colony.Warehouse
local Internal = Warehouse.Internal
local Data = Internal.Data or {}

Internal.Data = Data

function Data.CopyArray(source)
    local copy = {}
    for index, entry in ipairs(source or {}) do
        if type(entry) == "table" then
            copy[index] = Registry.Internal.CopyShallow(entry)
        else
            copy[index] = entry
        end
    end
    return copy
end

function Data.GetSummaryKey(colonyID)
    return tostring(Config.MOD_DATA_WAREHOUSE_PREFIX or "DColony_Warehouse_") .. tostring(colonyID)
end

function Data.GetItemsKey(colonyID)
    return tostring(Config.MOD_DATA_WAREHOUSE_ITEMS_PREFIX or "DColony_WarehouseItems_") .. tostring(colonyID)
end

function Data.GetEntryWeight(fullType, qty)
    return math.max(0, tonumber(Config.GetItemWeight and Config.GetItemWeight(fullType)) or 0) * math.max(1, tonumber(qty) or 1)
end

function Data.GetBuildingCapacityBonus(ownerUsername)
    local buildings = DC_Buildings
    if not buildings or not buildings.GetBuildingsForOwner or not buildings.GetWarehouseBuildingCapacityContribution then
        return 0
    end

    local total = 0
    for _, instance in ipairs(buildings.GetBuildingsForOwner(ownerUsername)) do
        if tostring(instance and instance.buildingType or "") == "Warehouse" and math.floor(tonumber(instance and instance.level) or 0) > 0 then
            total = total + math.max(0, tonumber(buildings.GetWarehouseBuildingCapacityContribution(instance)) or 0)
        end
    end
    return math.max(0, math.floor(total))
end

function Data.BuildEmptySummary(colonyID, ownerUsername)
    return {
        schemaVersion = Config.MOD_DATA_SCHEMA_VERSION or 3,
        colonyID = tostring(colonyID),
        ownerUsername = Config.GetOwnerUsername(ownerUsername),
        version = 1,
        capacityBase = Config.DEFAULT_WAREHOUSE_CAPACITY,
        manualCapacityBonus = 0,
        buildingCapacityBonus = 0,
        capacityBonus = 0,
        upgradeLevel = 0,
        autoEquipEnabled = false,
        medicalProvisionCarryoverHours = 0,
        maxWeight = Config.DEFAULT_WAREHOUSE_CAPACITY,
        usedWeight = 0,
        remainingWeight = Config.DEFAULT_WAREHOUSE_CAPACITY,
        counts = {
            provisions = 0,
            equipment = 0,
            output = 0,
        }
    }
end

function Data.BuildEmptyItems(colonyID)
    return {
        schemaVersion = Data.GetWarehouseItemsSchemaVersion and Data.GetWarehouseItemsSchemaVersion() or (Config.MOD_DATA_SCHEMA_VERSION or 4),
        colonyID = tostring(colonyID),
        version = 1,
        ledgers = {
            provisions = {},
            equipment = {},
            output = {},
        }
    }
end

Internal.GetEntryWeight = Data.GetEntryWeight
Internal.CopyArray = Data.CopyArray
Internal.GetSummaryKey = Data.GetSummaryKey
Internal.GetItemsKey = Data.GetItemsKey

return Warehouse

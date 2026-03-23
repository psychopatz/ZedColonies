DT_Labour = DT_Labour or {}
DT_Labour.Warehouse = DT_Labour.Warehouse or {}
DT_Labour.Warehouse.Internal = DT_Labour.Warehouse.Internal or {}

local Config = DT_Labour.Config
local Registry = DT_Labour.Registry
local Warehouse = DT_Labour.Warehouse
local Internal = Warehouse.Internal

local function ensureArray(value)
    return type(value) == "table" and value or {}
end

local function copyArray(source)
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

local function getEntryWeight(fullType, qty)
    return math.max(0, tonumber(Config.GetItemWeight and Config.GetItemWeight(fullType)) or 0) * math.max(1, tonumber(qty) or 1)
end

local function getBuildingCapacityBonus(ownerUsername)
    local buildings = DT_Buildings
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

function Warehouse.Recalculate(warehouse)
    if not warehouse then
        return nil
    end

    warehouse.ownerUsername = Config.GetOwnerUsername(warehouse.ownerUsername)
    warehouse.capacityBase = math.max(0, tonumber(warehouse.capacityBase) or tonumber(Config.DEFAULT_WAREHOUSE_CAPACITY) or 100)
    warehouse.manualCapacityBonus = math.max(
        0,
        tonumber(warehouse.manualCapacityBonus) or tonumber(warehouse.capacityBonus) or 0
    )
    warehouse.buildingCapacityBonus = getBuildingCapacityBonus(warehouse.ownerUsername)
    warehouse.capacityBonus = warehouse.manualCapacityBonus + warehouse.buildingCapacityBonus
    warehouse.upgradeLevel = math.max(0, math.floor(tonumber(warehouse.upgradeLevel) or 0))
    warehouse.medicalProvisionCarryoverHours = math.max(0, tonumber(warehouse.medicalProvisionCarryoverHours) or 0)
    warehouse.ledgers = type(warehouse.ledgers) == "table" and warehouse.ledgers or {}
    warehouse.ledgers.provisions = ensureArray(warehouse.ledgers.provisions)
    warehouse.ledgers.equipment = ensureArray(warehouse.ledgers.equipment)
    warehouse.ledgers.output = ensureArray(warehouse.ledgers.output)
    warehouse.maxWeight = warehouse.capacityBase + warehouse.capacityBonus

    local usedWeight = 0
    for _, entry in ipairs(warehouse.ledgers.provisions) do
        usedWeight = usedWeight + getEntryWeight(entry and entry.fullType, 1)
    end
    for _, entry in ipairs(warehouse.ledgers.equipment) do
        usedWeight = usedWeight + getEntryWeight(entry and entry.fullType, 1)
    end
    for _, entry in ipairs(warehouse.ledgers.output) do
        usedWeight = usedWeight + getEntryWeight(entry and entry.fullType, entry and entry.qty or 1)
    end

    warehouse.usedWeight = usedWeight
    warehouse.remainingWeight = math.max(0, warehouse.maxWeight - warehouse.usedWeight)
    return warehouse
end

function Warehouse.GetOwnerWarehouse(ownerUsername)
    local owner = Config.GetOwnerUsername(ownerUsername)
    local data = Registry.GetData()
    data.Warehouses = data.Warehouses or {}

    if not data.Warehouses[owner] then
        data.Warehouses[owner] = {
            ownerUsername = owner,
            capacityBase = Config.DEFAULT_WAREHOUSE_CAPACITY,
            capacityBonus = 0,
            manualCapacityBonus = 0,
            buildingCapacityBonus = 0,
            upgradeLevel = 0,
            medicalProvisionCarryoverHours = 0,
            ledgers = {
                provisions = {},
                equipment = {},
                output = {}
            }
        }
    end

    return Warehouse.Recalculate(data.Warehouses[owner])
end

function Warehouse.GetWorkerWarehouse(worker)
    if not worker then
        return nil
    end
    return Warehouse.GetOwnerWarehouse(worker.ownerUsername)
end

function Warehouse.GetRemainingCapacity(warehouse)
    warehouse = Warehouse.Recalculate(warehouse)
    return warehouse and warehouse.remainingWeight or 0
end

function Warehouse.GetClientSummary(ownerUsername)
    local warehouse = Warehouse.GetOwnerWarehouse(ownerUsername)
    if not warehouse then
        return nil
    end

    return {
        ownerUsername = warehouse.ownerUsername,
        capacityBase = warehouse.capacityBase,
        manualCapacityBonus = warehouse.manualCapacityBonus,
        buildingCapacityBonus = warehouse.buildingCapacityBonus,
        capacityBonus = warehouse.capacityBonus,
        maxWeight = warehouse.maxWeight,
        usedWeight = warehouse.usedWeight,
        remainingWeight = warehouse.remainingWeight,
        upgradeLevel = warehouse.upgradeLevel,
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
        provisions = copyArray(warehouse.ledgers.provisions),
        equipment = copyArray(warehouse.ledgers.equipment),
        output = copyArray(warehouse.ledgers.output)
    }
    return snapshot
end

Internal.GetEntryWeight = getEntryWeight
Internal.CopyArray = copyArray

return Warehouse

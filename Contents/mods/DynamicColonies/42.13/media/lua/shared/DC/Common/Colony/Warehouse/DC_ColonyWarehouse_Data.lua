DC_Colony = DC_Colony or {}
DC_Colony.Warehouse = DC_Colony.Warehouse or {}
DC_Colony.Warehouse.Internal = DC_Colony.Warehouse.Internal or {}

local Config = DC_Colony.Config
local Registry = DC_Colony.Registry
local Warehouse = DC_Colony.Warehouse
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

local function getSummaryKey(colonyID)
    return tostring(Config.MOD_DATA_WAREHOUSE_PREFIX or "DColony_Warehouse_") .. tostring(colonyID)
end

local function getItemsKey(colonyID)
    return tostring(Config.MOD_DATA_WAREHOUSE_ITEMS_PREFIX or "DColony_WarehouseItems_") .. tostring(colonyID)
end

local function getEntryWeight(fullType, qty)
    return math.max(0, tonumber(Config.GetItemWeight and Config.GetItemWeight(fullType)) or 0) * math.max(1, tonumber(qty) or 1)
end

local function getBuildingCapacityBonus(ownerUsername)
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

local function buildEmptySummary(colonyID, ownerUsername)
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

local function buildEmptyItems(colonyID)
    return {
        schemaVersion = Config.MOD_DATA_SCHEMA_VERSION or 3,
        colonyID = tostring(colonyID),
        version = 1,
        ledgers = {
            provisions = {},
            equipment = {},
            output = {},
        }
    }
end

local function normalizeProvisionEntry(entry)
    if type(entry) ~= "table" or not entry.fullType then
        return nil
    end

    local normalized = {
        fullType = tostring(entry.fullType),
        displayName = entry.displayName or Registry.Internal.GetDisplayNameForFullType(entry.fullType),
        provisionType = Config.IsMedicalProvisionEntry and Config.IsMedicalProvisionEntry(entry) and "medical" or tostring(entry.provisionType or "nutrition"),
        caloriesRemaining = math.max(0, tonumber(entry.caloriesRemaining) or 0),
        hydrationRemaining = math.max(0, tonumber(entry.hydrationRemaining) or 0),
        treatmentUnitsRemaining = math.max(0, tonumber(entry.treatmentUnitsRemaining) or 0),
        medicalUse = entry.medicalUse and tostring(entry.medicalUse) or nil,
        qty = math.max(1, math.floor(tonumber(entry.qty) or 1)),
    }
    if entry.consumedOutputFullType then
        normalized.consumedOutputFullType = tostring(entry.consumedOutputFullType)
        normalized.consumedOutputDisplayName = tostring(entry.consumedOutputDisplayName or Registry.Internal.GetDisplayNameForFullType(entry.consumedOutputFullType))
        if entry.consumedOutputFluidAmount ~= nil then
            normalized.consumedOutputFluidAmount = math.max(0, tonumber(entry.consumedOutputFluidAmount) or 0)
        end
    end
    return normalized
end

local function normalizeEquipmentEntry(entry)
    return Registry.Internal.NormalizeEquipmentEntry and Registry.Internal.NormalizeEquipmentEntry(entry) or nil
end

local function normalizeOutputEntry(entry)
    return Registry.Internal.NormalizeOutputEntry and Registry.Internal.NormalizeOutputEntry(entry) or nil
end

local function stackProvisionEntries(entries)
    local stacked = {}
    local byKey = {}

    for _, raw in ipairs(entries or {}) do
        local entry = normalizeProvisionEntry(raw)
        if entry then
            local key = table.concat({
                entry.fullType,
                entry.provisionType or "",
                tostring(entry.caloriesRemaining or 0),
                tostring(entry.hydrationRemaining or 0),
                tostring(entry.treatmentUnitsRemaining or 0),
                tostring(entry.medicalUse or ""),
                tostring(entry.consumedOutputFullType or ""),
                tostring(entry.consumedOutputDisplayName or ""),
                tostring(entry.consumedOutputFluidAmount ~= nil and string.format("%.4f", entry.consumedOutputFluidAmount) or "")
            }, "|")
            local existing = byKey[key]
            if existing then
                existing.qty = existing.qty + entry.qty
            else
                byKey[key] = entry
                stacked[#stacked + 1] = entry
            end
        end
    end

    return stacked
end

local function stackEquipmentEntries(entries)
    local normalizedEntries = {}
    for _, raw in ipairs(entries or {}) do
        local entry = normalizeEquipmentEntry(raw)
        if entry then
            normalizedEntries[#normalizedEntries + 1] = entry
        end
    end

    return normalizedEntries
end

local function stackOutputEntries(entries)
    local stacked = {}
    local byKey = {}

    for _, raw in ipairs(entries or {}) do
        local entry = normalizeOutputEntry(raw)
        if entry then
            local key = Registry.Internal.GetOutputEntryStateSignature and Registry.Internal.GetOutputEntryStateSignature(entry)
                or entry.fullType
            local existing = byKey[key]
            if existing then
                existing.qty = existing.qty + entry.qty
            else
                byKey[key] = entry
                stacked[#stacked + 1] = entry
            end
        end
    end

    return stacked
end

local function normalizeSummary(colonyID, ownerUsername, summary)
    -- Transient wrapper links must never live in persisted ModData tables.
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
    summary.medicalProvisionCarryoverHours = math.max(0, tonumber(summary.medicalProvisionCarryoverHours) or 0)
    summary.maxWeight = math.max(0, tonumber(summary.maxWeight) or 0)
    summary.usedWeight = math.max(0, tonumber(summary.usedWeight) or 0)
    summary.remainingWeight = math.max(0, tonumber(summary.remainingWeight) or 0)
    summary.counts = type(summary.counts) == "table" and summary.counts or {}
    summary.counts.provisions = math.max(0, math.floor(tonumber(summary.counts.provisions) or 0))
    summary.counts.equipment = math.max(0, math.floor(tonumber(summary.counts.equipment) or 0))
    summary.counts.output = math.max(0, math.floor(tonumber(summary.counts.output) or 0))
    return summary
end

local function normalizeItems(colonyID, items)
    items.__summary = nil
    items.__items = nil

    items.schemaVersion = Config.MOD_DATA_SCHEMA_VERSION or 3
    items.colonyID = tostring(colonyID)
    items.version = math.max(1, math.floor(tonumber(items.version) or 1))
    items.ledgers = type(items.ledgers) == "table" and items.ledgers or {}
    items.ledgers.provisions = stackProvisionEntries(items.ledgers.provisions)
    items.ledgers.equipment = stackEquipmentEntries(items.ledgers.equipment)
    items.ledgers.output = stackOutputEntries(items.ledgers.output)
    return items
end

local function ensureSummary(ownerUsername)
    local colonyID = Registry.GetColonyIDForOwner(ownerUsername, true)
    return normalizeSummary(
        colonyID,
        ownerUsername,
        Registry.Internal.EnsureModDataTable(getSummaryKey(colonyID), buildEmptySummary(colonyID, ownerUsername))
    )
end

local function ensureItems(ownerUsername)
    local colonyID = Registry.GetColonyIDForOwner(ownerUsername, true)
    return normalizeItems(
        colonyID,
        Registry.Internal.EnsureModDataTable(getItemsKey(colonyID), buildEmptyItems(colonyID))
    )
end

local function getCombinedWarehouse(ownerUsername)
    local owner = Config.GetOwnerUsername(ownerUsername)
    local colonyID = Registry.GetColonyIDForOwner(owner, true)
    local summary = ensureSummary(owner)
    local items = ensureItems(owner)
    local combined = Registry.Internal.CopyShallow(summary)
    combined.colonyID = colonyID
    combined.ownerUsername = owner
    combined.__summary = summary
    combined.__items = items
    combined.ledgers = items.ledgers
    return combined
end

function Warehouse.Recalculate(warehouse)
    if not warehouse then
        return nil
    end

    local summary = warehouse.__summary or warehouse
    local items = warehouse.__items
    if type(items) ~= "table" then
        items = {
            colonyID = tostring(summary.colonyID or ""),
            version = 1,
            ledgers = type(warehouse.ledgers) == "table" and warehouse.ledgers or {}
        }
    end

    normalizeSummary(summary.colonyID, summary.ownerUsername, summary)
    normalizeItems(summary.colonyID, items)

    summary.ownerUsername = Config.GetOwnerUsername(summary.ownerUsername)
    summary.buildingCapacityBonus = getBuildingCapacityBonus(summary.ownerUsername)
    summary.capacityBonus = summary.manualCapacityBonus + summary.buildingCapacityBonus
    summary.maxWeight = summary.capacityBase + summary.capacityBonus

    local usedWeight = 0
    local provisionCount = 0
    local equipmentCount = 0
    local outputCount = 0

    for _, entry in ipairs(items.ledgers.provisions or {}) do
        local qty = math.max(1, tonumber(entry and entry.qty) or 1)
        provisionCount = provisionCount + qty
        usedWeight = usedWeight + getEntryWeight(entry and entry.fullType, qty)
    end

    for _, entry in ipairs(items.ledgers.equipment or {}) do
        local qty = math.max(1, tonumber(entry and entry.qty) or 1)
        equipmentCount = equipmentCount + qty
        usedWeight = usedWeight + getEntryWeight(entry and entry.fullType, qty)
    end

    for _, entry in ipairs(items.ledgers.output or {}) do
        local qty = math.max(1, tonumber(entry and entry.qty) or 1)
        outputCount = outputCount + qty
        usedWeight = usedWeight + getEntryWeight(entry and entry.fullType, qty)
    end

    summary.usedWeight = usedWeight
    summary.remainingWeight = math.max(0, summary.maxWeight - summary.usedWeight)
    summary.counts.provisions = provisionCount
    summary.counts.equipment = equipmentCount
    summary.counts.output = outputCount

    warehouse.colonyID = summary.colonyID
    warehouse.ownerUsername = summary.ownerUsername
    warehouse.version = summary.version
    warehouse.itemsVersion = items.version
    warehouse.capacityBase = summary.capacityBase
    warehouse.manualCapacityBonus = summary.manualCapacityBonus
    warehouse.buildingCapacityBonus = summary.buildingCapacityBonus
    warehouse.capacityBonus = summary.capacityBonus
    warehouse.upgradeLevel = summary.upgradeLevel
    warehouse.medicalProvisionCarryoverHours = summary.medicalProvisionCarryoverHours
    warehouse.maxWeight = summary.maxWeight
    warehouse.usedWeight = summary.usedWeight
    warehouse.remainingWeight = summary.remainingWeight
    warehouse.counts = summary.counts
    warehouse.ledgers = items.ledgers
    return warehouse
end

function Warehouse.GetOwnerWarehouse(ownerUsername)
    return Warehouse.Recalculate(getCombinedWarehouse(ownerUsername))
end

function Warehouse.Init()
    local data = Registry and Registry.GetData and Registry.GetData() or nil
    local touched = false

    for _, summary in pairs(data and data.colonies or {}) do
        local owner = summary and summary.ownerUsername or nil
        if owner ~= nil then
            local colonyID = Registry.GetColonyIDForOwner(owner, true)
            local summaryKey = getSummaryKey(colonyID)
            local itemsKey = getItemsKey(colonyID)
            local rawSummary = Registry.Internal.EnsureModDataTable(summaryKey, buildEmptySummary(colonyID, owner))
            local rawItems = Registry.Internal.EnsureModDataTable(itemsKey, buildEmptyItems(colonyID))
            if rawSummary.__summary ~= nil or rawSummary.__items ~= nil or rawSummary.ledgers ~= nil or rawItems.__summary ~= nil or rawItems.__items ~= nil then
                touched = true
            end
            local warehouseSummary = ensureSummary(owner)
            local warehouseItems = ensureItems(owner)
        end
    end

    if touched and GlobalModData and GlobalModData.save then
        GlobalModData.save()
    end
end

Events.OnInitGlobalModData.Add(Warehouse.Init)

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

function Warehouse.TouchSummaryVersion(ownerUsername)
    local owner = Config.GetOwnerUsername(ownerUsername)
    local summary = ensureSummary(owner)
    local colonyData = Registry.GetColonyData(owner, true)
    summary.version = summary.version + 1
    if colonyData and colonyData.versions then
        colonyData.versions.warehouse = summary.version
    end
    return summary.version
end

function Warehouse.TouchItemsVersion(ownerUsername)
    local owner = Config.GetOwnerUsername(ownerUsername)
    local items = ensureItems(owner)
    local colonyData = Registry.GetColonyData(owner, true)
    items.version = items.version + 1
    if colonyData and colonyData.versions then
        colonyData.versions.warehouseItems = items.version
    end
    return items.version
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
        provisions = copyArray(warehouse.ledgers.provisions),
        equipment = copyArray(warehouse.ledgers.equipment),
        output = copyArray(warehouse.ledgers.output)
    }
    return snapshot
end

Internal.GetEntryWeight = getEntryWeight
Internal.CopyArray = copyArray
Internal.NormalizeProvisionEntry = normalizeProvisionEntry
Internal.NormalizeEquipmentEntry = normalizeEquipmentEntry
Internal.NormalizeOutputEntry = normalizeOutputEntry
Internal.GetSummaryKey = getSummaryKey
Internal.GetItemsKey = getItemsKey

return Warehouse

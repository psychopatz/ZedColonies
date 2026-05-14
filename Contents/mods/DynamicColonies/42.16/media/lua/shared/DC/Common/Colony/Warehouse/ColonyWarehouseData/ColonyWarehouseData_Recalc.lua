DC_Colony = DC_Colony or {}
DC_Colony.Warehouse = DC_Colony.Warehouse or {}
DC_Colony.Warehouse.Internal = DC_Colony.Warehouse.Internal or {}

local Config = DC_Colony.Config
local Registry = DC_Colony.Registry
local Warehouse = DC_Colony.Warehouse
local Internal = Warehouse.Internal
local Data = Internal.Data or {}

Internal.Data = Data

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

    Data.NormalizeSummary(summary.colonyID, summary.ownerUsername, summary)
    Data.NormalizeItems(summary.colonyID, items)

    summary.ownerUsername = Config.GetOwnerUsername(summary.ownerUsername)
    summary.buildingCapacityBonus = Data.GetBuildingCapacityBonus(summary.ownerUsername)
    summary.capacityBonus = summary.manualCapacityBonus + summary.buildingCapacityBonus
    summary.maxWeight = summary.capacityBase + summary.capacityBonus

    local usedWeight = 0
    local provisionCount = 0
    local equipmentCount = 0
    local outputCount = 0
    local categoryCount = Data.GetAbstractStockTotalCount(items.abstractStock)
    local specialCount = Data.GetLiteralSpecialCount(items.literalSpecialStock)

    for _, entry in ipairs(items.ledgers.provisions or {}) do
        local qty = math.max(1, tonumber(entry and entry.qty) or 1)
        provisionCount = provisionCount + qty
        usedWeight = usedWeight + Data.GetEntryWeight(entry and entry.fullType, qty)
    end

    for _, entry in ipairs(items.ledgers.equipment or {}) do
        local qty = math.max(1, tonumber(entry and entry.qty) or 1)
        equipmentCount = equipmentCount + qty
        usedWeight = usedWeight + Data.GetEntryWeight(entry and entry.fullType, qty)
    end

    for _, entry in ipairs(items.ledgers.output or {}) do
        local qty = math.max(1, tonumber(entry and entry.qty) or 1)
        outputCount = outputCount + qty
        usedWeight = usedWeight + Data.GetEntryWeight(entry and entry.fullType, qty)
    end

    usedWeight = usedWeight + Data.GetAbstractStockTotalWeight(items.abstractStock)
    usedWeight = usedWeight + Data.GetLiteralSpecialTotalWeight(items.literalSpecialStock)

    summary.usedWeight = usedWeight
    summary.remainingWeight = math.max(0, summary.maxWeight - summary.usedWeight)
    summary.counts.provisions = provisionCount
    summary.counts.equipment = equipmentCount
    summary.counts.output = outputCount
    summary.counts.categories = categoryCount
    summary.counts.special = specialCount

    warehouse.colonyID = summary.colonyID
    warehouse.ownerUsername = summary.ownerUsername
    warehouse.version = summary.version
    warehouse.itemsVersion = items.version
    warehouse.capacityBase = summary.capacityBase
    warehouse.manualCapacityBonus = summary.manualCapacityBonus
    warehouse.buildingCapacityBonus = summary.buildingCapacityBonus
    warehouse.capacityBonus = summary.capacityBonus
    warehouse.upgradeLevel = summary.upgradeLevel
    warehouse.autoEquipEnabled = summary.autoEquipEnabled == true
    warehouse.medicalProvisionCarryoverHours = summary.medicalProvisionCarryoverHours
    warehouse.maxWeight = summary.maxWeight
    warehouse.usedWeight = summary.usedWeight
    warehouse.remainingWeight = summary.remainingWeight
    warehouse.counts = summary.counts
    warehouse.abstractStock = items.abstractStock
    warehouse.literalSpecialStock = items.literalSpecialStock
    warehouse.ledgers = items.ledgers
    return warehouse
end

function Warehouse.GetOwnerWarehouse(ownerUsername)
    return Warehouse.Recalculate(Data.GetCombinedWarehouse(ownerUsername))
end

function Warehouse.Init()
    local data = Registry and Registry.GetData and Registry.GetData() or nil
    local touched = false

    for _, summary in pairs(data and data.colonies or {}) do
        local owner = summary and summary.ownerUsername or nil
        if owner ~= nil then
            local colonyID = Registry.GetColonyIDForOwner(owner, true)
            local summaryKey = Data.GetSummaryKey(colonyID)
            local itemsKey = Data.GetItemsKey(colonyID)
            local rawSummary = Registry.Internal.EnsureModDataTable(summaryKey, Data.BuildEmptySummary(colonyID, owner))
            local rawItems = Registry.Internal.EnsureModDataTable(itemsKey, Data.BuildEmptyItems(colonyID))
            if rawSummary.__summary ~= nil or rawSummary.__items ~= nil or rawSummary.ledgers ~= nil or rawItems.__summary ~= nil or rawItems.__items ~= nil then
                touched = true
            end
            Data.EnsureSummary(owner)
            Data.EnsureItems(owner)
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
    local summary = Data.EnsureSummary(owner)
    local colonyData = Registry.GetColonyData(owner, true)
    summary.version = summary.version + 1
    if colonyData and colonyData.versions then
        colonyData.versions.warehouse = summary.version
    end
    return summary.version
end

function Warehouse.TouchItemsVersion(ownerUsername)
    local owner = Config.GetOwnerUsername(ownerUsername)
    local items = Data.EnsureItems(owner)
    local colonyData = Registry.GetColonyData(owner, true)
    items.version = items.version + 1
    if colonyData and colonyData.versions then
        colonyData.versions.warehouseItems = items.version
    end
    return items.version
end

return Warehouse

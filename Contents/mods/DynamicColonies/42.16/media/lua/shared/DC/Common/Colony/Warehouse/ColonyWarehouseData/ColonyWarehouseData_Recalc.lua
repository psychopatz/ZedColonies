DC_Colony = DC_Colony or {}
DC_Colony.Warehouse = DC_Colony.Warehouse or {}
DC_Colony.Warehouse.Internal = DC_Colony.Warehouse.Internal or {}

local Config = DC_Colony.Config
local Registry = DC_Colony.Registry
local Warehouse = DC_Colony.Warehouse
local Internal = Warehouse.Internal
local Data = Internal.Data or {}

Internal.Data = Data

local function getPerfNowMs()
    if getTimestampMs then
        return getTimestampMs()
    end
    if getTimestamp then
        return math.floor((tonumber(getTimestamp()) or 0) * 1000)
    end
    return math.floor(os.clock() * 1000)
end

local function isDebugLoggingEnabled()
    return DynamicTrading
        and DynamicTrading.ShouldLogLevel
        and DynamicTrading.ShouldLogLevel("trace", "DynamicColonies", "Warehouse")
end

local function debugPerf(tag, startMs, thresholdMs, fields)
    if not isDebugLoggingEnabled() then
        return 0
    end

    local elapsed = math.max(0, getPerfNowMs() - math.max(0, tonumber(startMs) or 0))
    if elapsed < math.max(0, tonumber(thresholdMs) or 0) then
        return elapsed
    end

    local parts = {}
    for key, value in pairs(fields or {}) do
        parts[#parts + 1] = tostring(key) .. "=" .. tostring(value)
    end
    table.sort(parts)
    local message = table.concat(parts, " ") .. " ms=" .. tostring(elapsed)
    if DynamicTrading and DynamicTrading.LogTrace then
        DynamicTrading.LogTrace("DynamicColonies", "Warehouse", tostring(tag or "Perf"), message)
    elseif DynamicTrading and DynamicTrading.Log then
        DynamicTrading.Log("DynamicColonies", "Warehouse", tostring(tag or "Perf"), message)
    end
    return elapsed
end

function Warehouse.Recalculate(warehouse)
    local startedAt = getPerfNowMs()
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
    local abstractInventory = DC_Colony and DC_Colony.AbstractInventory or nil
    local abstractSummary = abstractInventory and abstractInventory.GetSummary and abstractInventory.GetSummary(summary.ownerUsername) or nil
    summary.buildingCapacityBonus = Data.GetBuildingCapacityBonus(summary.ownerUsername)
    summary.capacityBonus = summary.manualCapacityBonus + summary.buildingCapacityBonus
    summary.maxWeight = summary.capacityBase + summary.capacityBonus

    local usedWeight = 0
    local provisionCount = 0
    local equipmentCount = 0
    local outputCount = 0
    local provisionCalories = 0
    local provisionHydration = 0

    for _, entry in ipairs(items.ledgers.provisions or {}) do
        local qty = math.max(1, tonumber(entry and entry.qty) or 1)
        provisionCount = provisionCount + qty
        usedWeight = usedWeight + Data.GetEntryWeight(entry and entry.fullType, qty)
        provisionCalories = provisionCalories + math.max(
            0,
            tonumber(entry and entry.totalCaloriesRemaining)
                or ((tonumber(entry and entry.caloriesRemaining) or 0) * qty)
        )
        provisionHydration = provisionHydration + math.max(
            0,
            tonumber(entry and entry.totalHydrationRemaining)
                or ((tonumber(entry and entry.hydrationRemaining) or 0) * qty)
        )
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

    usedWeight = usedWeight + math.max(0, tonumber(abstractSummary and abstractSummary.totalWeight) or 0)

    summary.usedWeight = usedWeight
    summary.remainingWeight = math.max(0, summary.maxWeight - summary.usedWeight)
    summary.counts.provisions = provisionCount
    summary.counts.equipment = equipmentCount
    summary.counts.output = outputCount
    summary.counts.categories = math.max(0, tonumber(abstractSummary and abstractSummary.totalItemCount) or 0)
        - math.max(0, tonumber(abstractSummary and abstractSummary.literalSpecialCount) or 0)
    summary.counts.special = math.max(0, tonumber(abstractSummary and abstractSummary.literalSpecialCount) or 0)
    summary.inventoryVersion = math.max(1, math.floor(tonumber(abstractSummary and abstractSummary.version) or 1))
    summary.inventoryItemCount = math.max(0, tonumber(abstractSummary and abstractSummary.totalItemCount) or 0)
    summary.inventoryCategoryCount = math.max(0, tonumber(abstractSummary and abstractSummary.totalCategoryCount) or 0)
    summary.inventoryLiteralSpecialCount = math.max(0, tonumber(abstractSummary and abstractSummary.literalSpecialCount) or 0)
    summary.inventoryRowCount = math.max(0, tonumber(abstractSummary and abstractSummary.inventoryRowCount) or 0)
    summary.inventoryWeight = math.max(0, tonumber(abstractSummary and abstractSummary.totalWeight) or 0)
    summary.inventoryCalories = math.max(0, tonumber(abstractSummary and abstractSummary.totalCalories) or 0)
    summary.inventoryHydration = math.max(0, tonumber(abstractSummary and abstractSummary.totalHydration) or 0)
    summary.provisionCalories = provisionCalories
    summary.provisionHydration = provisionHydration
    summary.totalItemCount = provisionCount + equipmentCount + outputCount + summary.inventoryItemCount
    summary.totalCalories = provisionCalories + summary.inventoryCalories
    summary.totalHydration = provisionHydration + summary.inventoryHydration

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
    warehouse.inventoryVersion = summary.inventoryVersion
    warehouse.inventoryItemCount = summary.inventoryItemCount
    warehouse.inventoryCategoryCount = summary.inventoryCategoryCount
    warehouse.inventoryLiteralSpecialCount = summary.inventoryLiteralSpecialCount
    warehouse.inventoryRowCount = summary.inventoryRowCount
    warehouse.inventoryWeight = summary.inventoryWeight
    warehouse.inventoryCalories = summary.inventoryCalories
    warehouse.inventoryHydration = summary.inventoryHydration
    warehouse.provisionCalories = summary.provisionCalories
    warehouse.provisionHydration = summary.provisionHydration
    warehouse.totalItemCount = summary.totalItemCount
    warehouse.totalCalories = summary.totalCalories
    warehouse.totalHydration = summary.totalHydration
    warehouse.ledgers = items.ledgers
    debugPerf("Recalculate", startedAt, 5, {
        owner = summary.ownerUsername,
        provisions = provisionCount,
        equipment = equipmentCount,
        output = outputCount,
        inventoryItems = summary.inventoryItemCount,
        inventoryRows = summary.inventoryRowCount,
        usedWeight = summary.usedWeight,
        maxWeight = summary.maxWeight,
    })
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

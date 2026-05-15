DC_Colony = DC_Colony or {}
DC_Colony.DebugArchive = DC_Colony.DebugArchive or {}
DC_Colony.DebugArchive.Internal = DC_Colony.DebugArchive.Internal or {}

local DebugArchive = DC_Colony.DebugArchive
local Internal = DebugArchive.Internal
local Registry = DC_Colony.Registry
local Warehouse = DC_Colony.Warehouse
local AbstractInventory = DC_Colony.AbstractInventory
local Resources = DC_Colony.Resources
local Research = DC_Colony.Research
local Buildings = DC_Buildings

local function buildCompactSnapshotVersion(ownerUsername, workerSummary, warehouseSummary, abstractSummary, researchSnapshot, buildingSnapshot, rawState)
    local rawVersions = rawState and rawState.versions or {}
    local rawCounts = rawState and rawState.counts or {}

    local parts = {
        "debug-colony",
        tostring(ownerUsername or ""),
        tostring(rawVersions and rawVersions.workerListVersion or "workers:1"),
        tostring(rawVersions and rawVersions.warehouseVersion or "warehouse:1"),
        tostring(rawVersions and rawVersions.warehouseInventoryVersion or "warehouseinv:1"),
        tostring(rawVersions and rawVersions.abstractInventoryVersion or "abstract:1"),
        tostring(rawVersions and rawVersions.researchVersion or "research:1"),
        "bld:" .. tostring(buildingSnapshot and buildingSnapshot.ownerVersion or 1),
        "workers:" .. tostring(workerSummary and workerSummary.totalCount or 0),
        "living:" .. tostring(workerSummary and workerSummary.livingCount or 0),
        "dead:" .. tostring(workerSummary and workerSummary.deadCount or 0),
        "whW:" .. tostring(math.floor((tonumber(warehouseSummary and warehouseSummary.usedWeight) or 0) * 100 + 0.5)),
        "absI:" .. tostring(abstractSummary and abstractSummary.totalItemCount or 0),
        "absC:" .. tostring(abstractSummary and abstractSummary.totalCategoryCount or 0),
        "absW:" .. tostring(math.floor((tonumber(abstractSummary and abstractSummary.totalWeight) or 0) * 100 + 0.5)),
        "rq:" .. tostring(researchSnapshot and researchSnapshot.queueCount or 0),
        "bp:" .. tostring(researchSnapshot and researchSnapshot.unlockedCount or 0),
        "map:" .. tostring(buildingSnapshot and buildingSnapshot.colonyId or ownerUsername or ""),
        "bc:" .. tostring(rawCounts and rawCounts.buildings or 0),
        "pc:" .. tostring(rawCounts and rawCounts.activeProjects or 0),
    }

    return table.concat(parts, ":")
end

local function sortCountsTable(source)
    local rows = {}
    for key, count in pairs(source or {}) do
        rows[#rows + 1] = {
            key = tostring(key or ""),
            count = math.max(0, math.floor(tonumber(count) or 0)),
        }
    end

    table.sort(rows, function(a, b)
        if tonumber(a.count) == tonumber(b.count) then
            return tostring(a.key or "") < tostring(b.key or "")
        end
        return tonumber(a.count) > tonumber(b.count)
    end)

    return rows
end

local function summarizeWorkers(workers)
    local stateCounts = {}
    local jobCounts = {}
    local workersSorted = {}
    local livingCount = 0
    local deadCount = 0

    for _, worker in ipairs(workers or {}) do
        workersSorted[#workersSorted + 1] = worker
        local state = tostring(worker and worker.state or "Unknown")
        local jobType = tostring(worker and worker.jobType or "Idle")
        stateCounts[state] = math.max(0, tonumber(stateCounts[state]) or 0) + 1
        jobCounts[jobType] = math.max(0, tonumber(jobCounts[jobType]) or 0) + 1

        if state == "Dead" or tostring(worker and worker.deathCause or "") ~= "" then
            deadCount = deadCount + 1
        else
            livingCount = livingCount + 1
        end
    end

    table.sort(workersSorted, function(a, b)
        return tostring(a and a.name or a and a.workerID or "") < tostring(b and b.name or b and b.workerID or "")
    end)

    return {
        totalCount = #workersSorted,
        livingCount = livingCount,
        deadCount = deadCount,
        workers = workersSorted,
        stateCounts = sortCountsTable(stateCounts),
        jobCounts = sortCountsTable(jobCounts),
    }
end

local function getEntryCount(entry)
    local count = tonumber(entry and entry.count)
    if count == nil then
        count = tonumber(entry and entry.qty)
    end
    if count == nil then
        count = 1
    end
    return math.max(0, math.floor(count + 0.5))
end

local function getEntryWeight(entry)
    local value = tonumber(entry and entry.totalWeight)
    if value == nil then
        value = tonumber(entry and entry.weightTotal)
    end
    if value == nil then
        value = tonumber(entry and entry.weight)
    end
    return math.max(0, value or 0)
end

local function getEntryCalories(entry)
    local value = tonumber(entry and entry.totalCalories)
    if value == nil then
        value = tonumber(entry and entry.calories)
    end
    return math.max(0, value or 0)
end

local function getEntryHydration(entry)
    local value = tonumber(entry and entry.totalHydration)
    if value == nil then
        value = tonumber(entry and entry.hydration)
    end
    return math.max(0, value or 0)
end

local function summarizeLedgerEntries(entries)
    local summary = {
        stackCount = 0,
        itemCount = 0,
        totalWeight = 0,
        totalCalories = 0,
        totalHydration = 0,
        entries = {},
    }

    for _, entry in ipairs(entries or {}) do
        local count = getEntryCount(entry)
        summary.stackCount = summary.stackCount + 1
        summary.itemCount = summary.itemCount + count
        summary.totalWeight = summary.totalWeight + getEntryWeight(entry)
        summary.totalCalories = summary.totalCalories + getEntryCalories(entry)
        summary.totalHydration = summary.totalHydration + getEntryHydration(entry)
        summary.entries[#summary.entries + 1] = {
            fullType = tostring(entry and entry.fullType or ""),
            displayName = tostring(entry and entry.displayName or Internal.getItemDisplayName(entry and entry.fullType)),
            count = count,
            totalWeight = getEntryWeight(entry),
            totalCalories = getEntryCalories(entry),
            totalHydration = getEntryHydration(entry),
            itemID = entry and entry.itemID or nil,
            itemName = entry and entry.itemName or nil,
            pending = entry and entry.pending == true or false,
        }
    end

    table.sort(summary.entries, function(a, b)
        local aName = string.lower(tostring(a and a.displayName or ""))
        local bName = string.lower(tostring(b and b.displayName or ""))
        if aName == bName then
            return tostring(a and a.fullType or "") < tostring(b and b.fullType or "")
        end
        return aName < bName
    end)

    return summary
end

local function buildAbstractInventoryState(ownerUsername)
    local summary = AbstractInventory and AbstractInventory.GetSummary and AbstractInventory.GetSummary(ownerUsername) or nil
    local snapshot = AbstractInventory and AbstractInventory.GetSnapshot and AbstractInventory.GetSnapshot(ownerUsername) or nil
    local rows = {}
    local specialEntries = {}

    for categoryId, stockEntry in pairs(snapshot and snapshot.categoryStock or {}) do
        local definition = Internal.getCategoryDefinition(categoryId) or {}
        local foodEntry = snapshot and snapshot.foodNutritionPools and snapshot.foodNutritionPools[categoryId] or nil
        rows[#rows + 1] = {
            category = tostring(categoryId or ""),
            displayName = tostring(definition.displayName or categoryId or ""),
            group = tostring(definition.group or "Waste"),
            count = math.max(0, math.floor(tonumber(stockEntry and stockEntry.count) or 0)),
            totalWeight = math.max(0, tonumber(stockEntry and stockEntry.totalWeight) or 0),
            totalCalories = math.max(0, tonumber(foodEntry and foodEntry.calories) or 0),
            totalHydration = math.max(0, tonumber(foodEntry and foodEntry.hydration) or 0),
        }
    end

    table.sort(rows, function(a, b)
        local aName = string.lower(tostring(a and a.displayName or ""))
        local bName = string.lower(tostring(b and b.displayName or ""))
        if aName == bName then
            return tostring(a and a.category or "") < tostring(b and b.category or "")
        end
        return aName < bName
    end)

    for _, entry in ipairs(snapshot and snapshot.literalSpecialStock or {}) do
        local qty = math.max(1, math.floor(tonumber(entry and entry.qty) or 1))
        specialEntries[#specialEntries + 1] = {
            fullType = tostring(entry and entry.fullType or ""),
            displayName = tostring(entry and entry.displayName or Internal.getItemDisplayName(entry and entry.fullType)),
            qty = qty,
            totalWeight = math.max(0, tonumber(entry and entry.totalWeight) or 0),
            specialStockType = tostring(entry and entry.specialStockType or ""),
            researchJobID = tostring(entry and entry.researchJobID or ""),
        }
    end

    table.sort(specialEntries, function(a, b)
        local aName = string.lower(tostring(a and a.displayName or ""))
        local bName = string.lower(tostring(b and b.displayName or ""))
        if aName == bName then
            return tostring(a and a.fullType or "") < tostring(b and b.fullType or "")
        end
        return aName < bName
    end)

    return {
        summary = summary,
        rows = rows,
        literalSpecialEntries = specialEntries,
    }
end

local function buildRawState(ownerUsername, ownerView, colonyData, workersData, sitesData, workerSummary, warehouseSummary, abstractSummary, researchSnapshot, buildingSnapshot)
    local siteIDs = {}
    for siteID, _value in pairs(sitesData and sitesData.sites or {}) do
        siteIDs[#siteIDs + 1] = tostring(siteID or "")
    end
    table.sort(siteIDs)

    return {
        ownerUsername = tostring(ownerUsername or ""),
        colonyID = tostring(ownerView and ownerView.colonyID or ownerUsername),
        colonyName = tostring(ownerView and ownerView.colonyName or ""),
        leaderUsername = tostring(ownerView and ownerView.leaderUsername or ownerUsername),
        memberUsernames = Internal.copyArray(ownerView and ownerView.memberUsernames or {}),
        workerIDs = Internal.copyArray(ownerView and ownerView.workerIDs or {}),
        siteIDs = siteIDs,
        versions = {
            workerListVersion = DC_Colony
                and DC_Colony.Network
                and DC_Colony.Network.Internal
                and DC_Colony.Network.Internal.ColonyNetShared
                and DC_Colony.Network.Internal.ColonyNetShared.getWorkerListVersion
                and DC_Colony.Network.Internal.ColonyNetShared.getWorkerListVersion(ownerUsername)
                or tostring(workerSummary and workerSummary.totalCount or 0),
            warehouseVersion = warehouseSummary and warehouseSummary.version or 1,
            warehouseInventoryVersion = warehouseSummary and warehouseSummary.inventoryVersion or 1,
            abstractInventoryVersion = abstractSummary and abstractSummary.version or 1,
            researchVersion = researchSnapshot and researchSnapshot.version or 1,
            colonyWorkersVersion = workersData and workersData.version or nil,
            colonyRegistryVersions = colonyData and Internal.copyShallow(colonyData.versions or {}) or {},
            buildingMapColonyID = buildingSnapshot and buildingSnapshot.colonyId or nil,
        },
        counts = {
            workers = workerSummary and workerSummary.totalCount or 0,
            livingWorkers = workerSummary and workerSummary.livingCount or 0,
            deadWorkers = workerSummary and workerSummary.deadCount or 0,
            members = #(ownerView and ownerView.memberUsernames or {}),
            sites = #siteIDs,
            buildings = #(buildingSnapshot and buildingSnapshot.buildings or {}),
            activeProjects = #(buildingSnapshot and buildingSnapshot.activeProjects or {}),
        },
        recruitAttempts = ownerView and ownerView.recruitAttempts or nil,
        permissions = ownerView and ownerView.permissions or nil,
    }
end

function DebugArchive.GetColonySnapshot(ownerUsername)
    local owner = Internal.normalizeOwnerUsername(ownerUsername)
    if owner == "" then
        return nil
    end

    local ownerView = Registry and Registry.GetOwnerData and Registry.GetOwnerData(owner) or nil
    if not ownerView then
        return nil
    end

    local workers = Registry and Registry.GetWorkerSummariesForOwner and Registry.GetWorkerSummariesForOwner(owner) or {}
    local workerSummary = summarizeWorkers(workers)
    local warehouseSnapshot = Warehouse and Warehouse.GetClientSnapshot and Warehouse.GetClientSnapshot(owner, true, {
        provisions = true,
        equipment = true,
        output = true,
    }) or nil
    local warehouseSummary = warehouseSnapshot or {}
    local abstractInventory = buildAbstractInventoryState(owner)
    local resourcesSnapshot = Resources and Resources.GetClientSnapshot and Resources.GetClientSnapshot(owner) or nil
    local researchSnapshot = Research and Research.GetClientSnapshot and Research.GetClientSnapshot(owner) or nil
    local buildingSnapshot = Buildings and Buildings.BuildOwnerSnapshot and Buildings.BuildOwnerSnapshot(owner) or nil
    local colonyData = Registry and Registry.GetColonyData and Registry.GetColonyData(owner, false) or nil
    local workersData = Registry and Registry.GetWorkersData and Registry.GetWorkersData(owner, false) or nil
    local sitesData = Registry and Registry.GetSitesData and Registry.GetSitesData(owner, false) or nil

    local snapshot = {
        ownerUsername = owner,
        colonyID = tostring(ownerView.colonyID or owner),
        colonyName = tostring(ownerView.colonyName or ""),
        leaderUsername = tostring(ownerView.leaderUsername or owner),
        workers = workerSummary,
        warehouse = {
            summary = Warehouse and Warehouse.GetClientSummary and Warehouse.GetClientSummary(owner) or warehouseSummary,
            provisions = summarizeLedgerEntries(warehouseSnapshot and warehouseSnapshot.ledgers and warehouseSnapshot.ledgers.provisions or {}),
            equipment = summarizeLedgerEntries(warehouseSnapshot and warehouseSnapshot.ledgers and warehouseSnapshot.ledgers.equipment or {}),
            output = summarizeLedgerEntries(warehouseSnapshot and warehouseSnapshot.ledgers and warehouseSnapshot.ledgers.output or {}),
        },
        abstractInventory = abstractInventory,
        resources = resourcesSnapshot,
        research = researchSnapshot,
        buildings = buildingSnapshot,
    }

    snapshot.rawState = buildRawState(
        owner,
        ownerView,
        colonyData,
        workersData,
        sitesData,
        workerSummary,
        snapshot.warehouse.summary,
        abstractInventory.summary,
        researchSnapshot,
        buildingSnapshot
    )

    snapshot.version = buildCompactSnapshotVersion(
        owner,
        workerSummary,
        snapshot.warehouse.summary,
        abstractInventory.summary,
        researchSnapshot,
        buildingSnapshot,
        snapshot.rawState
    )
    return snapshot
end

return DebugArchive

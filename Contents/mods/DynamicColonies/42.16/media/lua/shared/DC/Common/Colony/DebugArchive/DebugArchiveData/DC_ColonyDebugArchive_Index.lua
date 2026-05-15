DC_Colony = DC_Colony or {}
DC_Colony.DebugArchive = DC_Colony.DebugArchive or {}
DC_Colony.DebugArchive.Internal = DC_Colony.DebugArchive.Internal or {}

local DebugArchive = DC_Colony.DebugArchive
local Internal = DebugArchive.Internal
local Registry = DC_Colony.Registry
local Warehouse = DC_Colony.Warehouse
local AbstractInventory = DC_Colony.AbstractInventory
local Research = DC_Colony.Research
local Resources = DC_Colony.Resources
local Buildings = DC_Buildings

local function countWorkers(workers)
    local counts = {
        total = 0,
        living = 0,
        dead = 0,
    }

    for _, worker in ipairs(workers or {}) do
        counts.total = counts.total + 1
        if tostring(worker and worker.state or "") == "Dead" or tostring(worker and worker.deathCause or "") ~= "" then
            counts.dead = counts.dead + 1
        else
            counts.living = counts.living + 1
        end
    end

    return counts
end

local function buildIndexEntry(ownerUsername)
    local owner = Internal.normalizeOwnerUsername(ownerUsername)
    local workerSummaries = Registry and Registry.GetWorkerSummariesForOwner and Registry.GetWorkerSummariesForOwner(owner) or {}
    local workerCounts = countWorkers(workerSummaries)
    local buildings = Buildings and Buildings.GetBuildingsForOwner and Buildings.GetBuildingsForOwner(owner) or {}
    local projects = Buildings and Buildings.GetProjectsForOwner and Buildings.GetProjectsForOwner(owner) or {}
    local warehouseSummary = Warehouse and Warehouse.GetClientSummary and Warehouse.GetClientSummary(owner) or nil
    local inventorySummary = AbstractInventory and AbstractInventory.GetSummary and AbstractInventory.GetSummary(owner) or nil
    local researchSnapshot = Research and Research.GetClientSnapshot and Research.GetClientSnapshot(owner) or nil
    local resourcesSnapshot = Resources and Resources.GetClientSnapshot and Resources.GetClientSnapshot(owner) or nil
    local ownerView = Registry and Registry.GetOwnerData and Registry.GetOwnerData(owner) or nil
    local water = resourcesSnapshot and resourcesSnapshot.water or {}

    local version = Internal.buildVersionToken({
        owner = owner,
        workerListVersion = DC_Colony
            and DC_Colony.Network
            and DC_Colony.Network.Internal
            and DC_Colony.Network.Internal.ColonyNetShared
            and DC_Colony.Network.Internal.ColonyNetShared.getWorkerListVersion
            and DC_Colony.Network.Internal.ColonyNetShared.getWorkerListVersion(owner)
            or tostring(#workerSummaries),
        warehouseVersion = warehouseSummary and warehouseSummary.version or 1,
        inventoryVersion = inventorySummary and inventorySummary.version or 1,
        researchVersion = researchSnapshot and researchSnapshot.version or 1,
        buildingCount = #buildings,
        projectCount = #projects,
        waterStored = water and water.stored or 0,
        waterCapacity = water and water.capacity or 0,
    })

    return {
        ownerUsername = owner,
        colonyID = tostring(ownerView and ownerView.colonyID or owner),
        colonyName = tostring(ownerView and ownerView.colonyName or ""),
        leaderUsername = tostring(ownerView and ownerView.leaderUsername or owner),
        version = version,
        workerCount = workerCounts.total,
        livingWorkerCount = workerCounts.living,
        deadWorkerCount = workerCounts.dead,
        buildingCount = #buildings,
        activeProjectCount = #projects,
        warehouseUsedWeight = warehouseSummary and warehouseSummary.usedWeight or 0,
        warehouseMaxWeight = warehouseSummary and warehouseSummary.maxWeight or 0,
        inventoryItemCount = inventorySummary and inventorySummary.totalItemCount or 0,
        inventoryCategoryCount = inventorySummary and inventorySummary.totalCategoryCount or 0,
        inventoryWeight = inventorySummary and inventorySummary.totalWeight or 0,
        researchQueueCount = researchSnapshot and researchSnapshot.queueCount or 0,
        researchUnlockedCount = researchSnapshot and researchSnapshot.unlockedCount or 0,
        waterStored = water and water.stored or 0,
        waterCapacity = water and water.capacity or 0,
    }
end

function DebugArchive.GetIndexSnapshot()
    local colonies = {}
    local owners = Registry and Registry.GetOwnerUsernames and Registry.GetOwnerUsernames() or {}

    for _, ownerUsername in ipairs(owners) do
        colonies[#colonies + 1] = buildIndexEntry(ownerUsername)
    end

    table.sort(colonies, function(a, b)
        local aName = string.lower(tostring(a and a.ownerUsername or ""))
        local bName = string.lower(tostring(b and b.ownerUsername or ""))
        if aName == bName then
            return tostring(a and a.colonyID or "") < tostring(b and b.colonyID or "")
        end
        return aName < bName
    end)

    return {
        version = Internal.buildVersionToken(colonies),
        colonyCount = #colonies,
        colonies = colonies,
    }
end

return DebugArchive

DC_Colony = DC_Colony or {}
DC_Colony.Network = DC_Colony.Network or {}
DC_Colony.Network.Internal = DC_Colony.Network.Internal or {}

local Internal = DC_Colony.Network.Internal
local Transport = Internal.Transport or {}
local Registry = Transport.Registry or {}
local Buildings = Transport.Buildings or {}
local Resources = Transport.Resources or {}

function Transport.getBuildingVersion(ownerUsername)
    local ownerData = Buildings.EnsureOwner and Buildings.EnsureOwner(ownerUsername) or nil
    return math.max(1, math.floor(tonumber(ownerData and ownerData.version) or 1))
end

function Transport.getWorkerListVersion(ownerUsername)
    local workersData = Registry.GetWorkersData and Registry.GetWorkersData(ownerUsername, false) or nil
    if workersData and workersData.version then
        return math.max(1, math.floor(tonumber(workersData.version) or 1))
    end
    local colonyData = Registry.GetColonyData and Registry.GetColonyData(ownerUsername, false) or nil
    local versions = colonyData and colonyData.versions or nil
    return math.max(1, math.floor(tonumber(versions and versions.workers) or 1))
end

function Transport.getWorkerDetailVersion(worker)
    return math.max(1, math.floor(tonumber(worker and worker.detailVersion) or 1))
end

function Transport.getWarehouseSummaryVersion(ownerUsername)
    local Warehouse = DC_Colony and DC_Colony.Warehouse or nil
    local summary = Warehouse and Warehouse.GetClientSummary and Warehouse.GetClientSummary(ownerUsername) or nil
    return math.max(1, math.floor(tonumber(summary and summary.version) or 1))
end

function Transport.getWarehouseItemsVersion(ownerUsername)
    local Warehouse = DC_Colony and DC_Colony.Warehouse or nil
    local summary = Warehouse and Warehouse.GetClientSummary and Warehouse.GetClientSummary(ownerUsername) or nil
    return math.max(1, math.floor(tonumber(summary and summary.itemsVersion) or 1))
end

function Transport.getWarehouseInventoryVersion(ownerUsername)
    local Warehouse = DC_Colony and DC_Colony.Warehouse or nil
    local summary = Warehouse and Warehouse.GetClientSummary and Warehouse.GetClientSummary(ownerUsername) or nil
    return math.max(1, math.floor(tonumber(summary and summary.inventoryVersion) or 1))
end

function Transport.getResourcesVersion(ownerUsername)
    local ownerData = Resources.EnsureOwner and Resources.EnsureOwner(ownerUsername) or nil
    return math.max(1, math.floor(tonumber(ownerData and ownerData.version) or 1))
end

function Transport.buildFactionStatusSummary(ownerUsername)
    if not DynamicTrading_Factions or not DynamicTrading_Factions.GetOwnedFactionStatus then
        return {
            ownerUsername = ownerUsername,
            authorityOwner = ownerUsername,
            canCreate = false,
            workerCount = 0,
            faction = nil,
            memberUsernames = {},
            createBlockedReason = "factions_unavailable",
        }
    end

    local fullStatus = DynamicTrading_Factions.GetOwnedFactionStatus(ownerUsername) or {}
    local faction = type(fullStatus.faction) == "table" and fullStatus.faction or nil
    local memberUsernames = Transport.copyArray(fullStatus.memberUsernames or (faction and faction.memberUsernames) or {})

    return {
        ownerUsername = fullStatus.ownerUsername or ownerUsername,
        memberUsername = fullStatus.memberUsername or ownerUsername,
        authorityOwner = fullStatus.authorityOwner or ownerUsername,
        canCreate = fullStatus.canCreate == true,
        workerCount = math.max(0, math.floor(tonumber(fullStatus.workerCount) or 0)),
        role = fullStatus.role,
        isLeader = fullStatus.isLeader == true,
        isMember = fullStatus.isMember == true,
        createBlockedReason = fullStatus.createBlockedReason,
        memberUsernames = memberUsernames,
        faction = faction and {
            id = faction.id,
            name = faction.name,
            leaderUsername = faction.leaderUsername,
            authorityOwner = faction.authorityOwner or fullStatus.authorityOwner or faction.leaderUsername,
            leadershipState = faction.leadershipState,
            homeCoords = type(faction.homeCoords) == "table" and {
                x = faction.homeCoords.x,
                y = faction.homeCoords.y,
                z = faction.homeCoords.z,
            } or nil,
            memberUsernames = Transport.copyArray(faction.memberUsernames),
        } or nil,
    }
end

function Transport.getFactionStatusVersion(ownerUsername)
    local summary = Transport.buildFactionStatusSummary(ownerUsername)
    local faction = summary.faction or {}
    return table.concat({
        tostring(summary.authorityOwner or ownerUsername),
        tostring(faction.id or "none"),
        tostring(faction.leadershipState or "none"),
        tostring(#(summary.memberUsernames or {})),
        tostring(summary.workerCount or 0),
        tostring(Transport.getBuildingVersion(ownerUsername)),
        tostring(Transport.getWorkerListVersion(ownerUsername)),
    }, ":")
end

function Transport.buildResourcesSummary(ownerUsername)
    local snapshot = Resources.GetClientSnapshot and Resources.GetClientSnapshot(ownerUsername) or nil
    if type(snapshot) ~= "table" then
        return {
            ownerUsername = ownerUsername,
            categories = {},
            water = nil,
        }
    end

    local water = snapshot.water or {}
    return {
        ownerUsername = ownerUsername,
        categories = Transport.copyArray(snapshot.categories),
        water = {
            stored = tonumber(water.stored) or 0,
            capacity = tonumber(water.capacity) or 0,
            available = tonumber(water.available) or 0,
            baseCollectionRatePerHour = tonumber(water.baseCollectionRatePerHour) or 0,
            activeCollectionRatePerHour = tonumber(water.activeCollectionRatePerHour) or 0,
            raining = water.raining == true,
            rainIntensity = tonumber(water.rainIntensity) or 0,
            outdoorTemperatureC = tonumber(water.outdoorTemperatureC) or 0,
            dailyDemand = tonumber(water.dailyDemand) or 0,
            collectorCount = #(water.collectors or {}),
            tankCount = #(water.tanks or {}),
            greenhouseCount = #(water.greenhouses or {}),
        },
    }
end

function Transport.buildVersions(ownerUsername)
    return {
        building = Transport.getBuildingVersion(ownerUsername),
        workerList = Transport.getWorkerListVersion(ownerUsername),
        warehouseSummary = Transport.getWarehouseSummaryVersion(ownerUsername),
        warehouseItems = Transport.getWarehouseItemsVersion(ownerUsername),
        warehouseInventory = Transport.getWarehouseInventoryVersion(ownerUsername),
        resources = Transport.getResourcesVersion(ownerUsername),
        factionStatus = Transport.getFactionStatusVersion(ownerUsername),
    }
end

function Internal.buildVersionsForOwner(ownerUsername)
    return Transport.buildVersions(Transport.getOwnerUsername(ownerUsername))
end

return Transport

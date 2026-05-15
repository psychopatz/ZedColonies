require "DC/UI/Colony/DebugArchive/DebugArchiveRender/DC_DebugArchiveRender_Common"

DC_DebugArchiveSections_Overview = DC_DebugArchiveSections_Overview or {}

local Render = DC_DebugArchiveRender
local Section = DC_DebugArchiveSections_Overview

function Section.Build(window, snapshot)
    local lines = {}
    local workerSummary = snapshot and snapshot.workers or {}
    local warehouse = snapshot and snapshot.warehouse and snapshot.warehouse.summary or {}
    local inventory = snapshot and snapshot.abstractInventory and snapshot.abstractInventory.summary or {}
    local research = snapshot and snapshot.research or {}
    local resources = snapshot and snapshot.resources and snapshot.resources.water or {}
    local buildings = snapshot and snapshot.buildings or {}

    Render.AppendHeader(lines, "Colony Overview")
    Render.AppendLine(lines, "Owner", snapshot and snapshot.ownerUsername or "")
    Render.AppendLine(lines, "Colony ID", snapshot and snapshot.colonyID or "")
    Render.AppendLine(lines, "Colony Name", snapshot and snapshot.colonyName or "")
    Render.AppendLine(lines, "Leader", snapshot and snapshot.leaderUsername or "")
    Render.AppendLine(lines, "Snapshot Version", snapshot and snapshot.version or "")

    Render.AppendSubHeader(lines, "Workers")
    Render.AppendLine(lines, "Total Workers", Render.FormatInt(workerSummary and workerSummary.totalCount or 0))
    Render.AppendLine(lines, "Living", Render.FormatInt(workerSummary and workerSummary.livingCount or 0))
    Render.AppendLine(lines, "Dead", Render.FormatInt(workerSummary and workerSummary.deadCount or 0))
    Render.AppendLine(lines, "States", Render.FormatCountRows(workerSummary and workerSummary.stateCounts or {}, 12))
    Render.AppendLine(lines, "Jobs", Render.FormatCountRows(workerSummary and workerSummary.jobCounts or {}, 12))

    Render.AppendSubHeader(lines, "Warehouse")
    Render.AppendLine(lines, "Used Weight", Render.FormatWeight(warehouse and warehouse.usedWeight or 0))
    Render.AppendLine(lines, "Capacity", Render.FormatWeight(warehouse and warehouse.maxWeight or 0))
    Render.AppendLine(lines, "Remaining", Render.FormatWeight(warehouse and warehouse.remainingWeight or 0))
    Render.AppendLine(lines, "Literal Item Total", Render.FormatInt(warehouse and warehouse.totalItemCount or 0))
    Render.AppendLine(lines, "Provision Calories", Render.FormatInt(warehouse and warehouse.provisionCalories or 0))
    Render.AppendLine(lines, "Provision Hydration", Render.FormatInt(warehouse and warehouse.provisionHydration or 0))

    Render.AppendSubHeader(lines, "Abstract Inventory")
    Render.AppendLine(lines, "Categories", Render.FormatInt(inventory and inventory.totalCategoryCount or 0))
    Render.AppendLine(lines, "Total Items", Render.FormatInt(inventory and inventory.totalItemCount or 0))
    Render.AppendLine(lines, "Literal Special Entries", Render.FormatInt(inventory and inventory.literalSpecialCount or 0))
    Render.AppendLine(lines, "Stored Weight", Render.FormatWeight(inventory and inventory.totalWeight or 0))
    Render.AppendLine(lines, "Stored Calories", Render.FormatInt(inventory and inventory.totalCalories or 0))
    Render.AppendLine(lines, "Stored Hydration", Render.FormatInt(inventory and inventory.totalHydration or 0))

    Render.AppendSubHeader(lines, "Research")
    Render.AppendLine(lines, "Queue Count", Render.FormatInt(research and research.queueCount or 0))
    Render.AppendLine(lines, "Unlocked Blueprints", Render.FormatInt(research and research.unlockedCount or 0))

    Render.AppendSubHeader(lines, "Buildings")
    Render.AppendLine(lines, "Building Types", Render.FormatInt(buildings and buildings.buildings and #buildings.buildings or 0))
    Render.AppendLine(lines, "Active Projects", Render.FormatInt(buildings and buildings.activeProjects and #buildings.activeProjects or 0))
    Render.AppendLine(lines, "Housing Capacity", Render.FormatInt(buildings and buildings.housing and buildings.housing.capacity or 0))
    Render.AppendLine(lines, "Unhoused Workers", Render.FormatInt(buildings and buildings.housing and buildings.housing.unhousedCount or 0))
    Render.AppendLine(lines, "Medical Capacity", Render.FormatInt(buildings and buildings.medical and buildings.medical.totalCapacity or 0))

    Render.AppendSubHeader(lines, "Resources")
    Render.AppendLine(lines, "Water Stored", Render.FormatInt(resources and resources.stored or 0))
    Render.AppendLine(lines, "Water Capacity", Render.FormatInt(resources and resources.capacity or 0))
    Render.AppendLine(lines, "Water Demand / Day", Render.FormatInt(resources and resources.dailyDemand or 0))
    Render.AppendLine(lines, "Collection / Hour", Render.FormatInt(resources and resources.activeCollectionRatePerHour or 0))

    return table.concat(lines)
end

return Section

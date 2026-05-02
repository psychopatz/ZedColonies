DC_Buildings = DC_Buildings or {}
DC_Buildings.Internal = DC_Buildings.Internal or {}

local Buildings = DC_Buildings
local Config = Buildings.Config
local Internal = Buildings.Internal

-- Shared deferred-access helpers

local function getColonyConfig()
    return DC_Colony and DC_Colony.Config or {}
end

local function getRegistry()
    return DC_Colony and DC_Colony.Registry or nil
end

local function getWarehouse()
    return DC_Colony and DC_Colony.Warehouse or nil
end

local function getOwnerUsername(playerOrUsername)
    local labourConfig = getColonyConfig()
    return labourConfig.GetOwnerUsername and labourConfig.GetOwnerUsername(playerOrUsername) or tostring(playerOrUsername or "local")
end

local function getDisplayName(fullType)
    local registry = getRegistry()
    local internal = registry and registry.Internal or nil
    return internal and internal.GetDisplayNameForFullType and internal.GetDisplayNameForFullType(fullType) or tostring(fullType or "Unknown")
end

-- Recipe primitives

local function buildRecipeMap(recipe)
    local required = {}
    for _, entry in ipairs(recipe or {}) do
        local fullType = tostring(entry.fullType or "")
        local count = math.max(0, math.floor(tonumber(entry.count) or 0))
        if fullType ~= "" and count > 0 then
            required[fullType] = (required[fullType] or 0) + count
        end
    end
    return required
end

local function hasRecipeEntries(required)
    for _, _ in pairs(required or {}) do
        return true
    end
    return false
end

local function normalizeMaterialCountMap(value)
    local counts = type(value) == "table" and value or {}
    local normalized = {}
    for fullType, count in pairs(counts) do
        local key = tostring(fullType or "")
        if key ~= "" then
            normalized[key] = math.max(0, math.floor(tonumber(count) or 0))
        end
    end
    return normalized
end

local function countRecipeUnits(recipe)
    local total = 0
    for _, entry in ipairs(recipe or {}) do
        total = total + math.max(0, math.floor(tonumber(entry.count) or 0))
    end
    return total
end

local function countSuppliedRecipeUnits(recipe, suppliedCounts)
    local total = 0
    for _, entry in ipairs(recipe or {}) do
        local fullType = tostring(entry.fullType or "")
        local required = math.max(0, math.floor(tonumber(entry.count) or 0))
        total = total + math.min(required, math.max(0, tonumber(suppliedCounts and suppliedCounts[fullType]) or 0))
    end
    return total
end

-- Material source access

local function getWarehouseOutputCounts(ownerUsername)
    local warehouseApi = getWarehouse()
    local warehouse = warehouseApi and warehouseApi.GetOwnerWarehouse and warehouseApi.GetOwnerWarehouse(ownerUsername) or nil
    local counts = {}
    for _, entry in ipairs(warehouse and warehouse.ledgers and warehouse.ledgers.output or {}) do
        local fullType = tostring(entry.fullType or "")
        local qty = math.max(0, math.floor(tonumber(entry.qty) or 0))
        if fullType ~= "" and qty > 0 then
            counts[fullType] = (counts[fullType] or 0) + qty
        end
    end
    return counts
end

local function getInventoryItemQuantity(item)
    if not item then
        return 0
    end

    local count = item.getCount and item:getCount() or nil
    count = math.floor(tonumber(count) or 0)
    if count > 0 then
        return count
    end

    return 1
end

local function collectInventoryCountsRecursive(container, counts)
    if not container or not counts then
        return
    end

    local items = container:getItems()
    if not items then
        return
    end

    for index = 0, items:size() - 1 do
        local item = items:get(index)
        if item then
            local fullType = item.getFullType and item:getFullType() or nil
            if fullType then
                counts[fullType] = (counts[fullType] or 0) + getInventoryItemQuantity(item)
            end

            if instanceof(item, "InventoryContainer") then
                collectInventoryCountsRecursive(item:getItemContainer(), counts)
            end
        end
    end
end

local function canReadInventory(value)
    local valueType = type(value)
    return (valueType == "table" or valueType == "userdata") and value.getInventory ~= nil
end

local function resolveSourcePlayer(ownerUsername, sourcePlayer)
    if canReadInventory(sourcePlayer) then
        return sourcePlayer
    end

    if canReadInventory(ownerUsername) then
        return ownerUsername
    end

    local colonyConfig = getColonyConfig()
    local player = colonyConfig and colonyConfig.GetPlayerObject and colonyConfig.GetPlayerObject() or nil
    if canReadInventory(player) then
        local owner = getOwnerUsername(ownerUsername)
        if getOwnerUsername(player) == owner then
            return player
        end
    end

    return nil
end

local function getPlayerInventoryCounts(ownerUsername, sourcePlayer)
    local player = resolveSourcePlayer(ownerUsername, sourcePlayer)
    local inventory = player and player.getInventory and player:getInventory() or nil
    local counts = {}
    if not inventory then
        return counts
    end

    collectInventoryCountsRecursive(inventory, counts)
    return counts
end

local function mergeCounts(baseCounts, extraCounts)
    local merged = {}

    for fullType, qty in pairs(baseCounts or {}) do
        merged[fullType] = math.max(0, math.floor(tonumber(qty) or 0))
    end

    for fullType, qty in pairs(extraCounts or {}) do
        local key = tostring(fullType or "")
        if key ~= "" then
            merged[key] = (merged[key] or 0) + math.max(0, math.floor(tonumber(qty) or 0))
        end
    end

    return merged
end

local function getAvailableMaterialCounts(ownerUsername, sourcePlayer)
    return mergeCounts(
        getWarehouseOutputCounts(ownerUsername),
        getPlayerInventoryCounts(ownerUsername, sourcePlayer)
    )
end

-- Recipe availability check

local function buildRecipeAvailability(ownerUsername, recipe, sourcePlayer, availableCounts)
    local resolvedAvailableCounts = availableCounts or getAvailableMaterialCounts(ownerUsername, sourcePlayer)
    local entries = {}
    local hasAll = true

    for _, entry in ipairs(recipe or {}) do
        local fullType = tostring(entry.fullType or "")
        local required = math.max(0, math.floor(tonumber(entry.count) or 0))
        local available = resolvedAvailableCounts[fullType] or 0
        local recipeEntry = {
            fullType = fullType,
            displayName = getDisplayName(fullType),
            count = required,
            available = available,
            satisfied = available >= required
        }
        if recipeEntry.satisfied ~= true then
            hasAll = false
        end
        entries[#entries + 1] = recipeEntry
    end

    return {
        hasAll = hasAll,
        entries = entries
    }
end

-- Project material tracking

local function ensureProjectMaterialTracking(project)
    if type(project) ~= "table" then
        return nil
    end

    project.materialTrackingVersion = math.max(0, math.floor(tonumber(project.materialTrackingVersion) or 0))
    project.materialCounts = normalizeMaterialCountMap(project.materialCounts)

    if project.materialTrackingVersion <= 0 then
        project.materialTrackingVersion = 1
        project.materialCounts = buildRecipeMap(project.recipe)
        project.materialState = "Ready"
    end

    return project
end

local function pullProjectMaterialsFromWarehouse(project)
    local warehouseApi = getWarehouse()
    local owner = project and getOwnerUsername(project.ownerUsername) or nil
    local warehouse = owner and warehouseApi and warehouseApi.GetOwnerWarehouse and warehouseApi.GetOwnerWarehouse(owner) or nil
    if not project or not warehouse then
        return 0
    end

    ensureProjectMaterialTracking(project)

    local required = buildRecipeMap(project.recipe)
    if not hasRecipeEntries(required) then
        return 0
    end

    local moved = 0
    local outputLedger = warehouse.ledgers and warehouse.ledgers.output or {}
    for index = #outputLedger, 1, -1 do
        local entry = outputLedger[index]
        local fullType = tostring(entry and entry.fullType or "")
        local needed = math.max(0, (required[fullType] or 0) - (project.materialCounts[fullType] or 0))
        if fullType ~= "" and needed > 0 and entry then
            local qty = math.max(0, math.floor(tonumber(entry.qty) or 0))
            local toTake = math.min(qty, needed)
            if toTake > 0 then
                project.materialCounts[fullType] = math.max(0, tonumber(project.materialCounts[fullType]) or 0) + toTake
                qty = qty - toTake
                moved = moved + toTake
                if qty <= 0 then
                    table.remove(outputLedger, index)
                else
                    entry.qty = qty
                end
            end
        end
    end

    if moved > 0 and warehouseApi and warehouseApi.Recalculate then
        warehouseApi.Recalculate(warehouse)
    end

    return moved
end

local function buildProjectMaterialStatus(project, sourcePlayer, availableCounts)
    ensureProjectMaterialTracking(project)

    local owner = project and getOwnerUsername(project.ownerUsername) or nil
    local resolvedAvailableCounts = availableCounts or (owner and getAvailableMaterialCounts(owner, sourcePlayer) or {})
    local entries = {}
    local hasAll = true
    local totalRequired = countRecipeUnits(project and project.recipe or {})
    local totalSupplied = countSuppliedRecipeUnits(project and project.recipe or {}, project and project.materialCounts or nil)

    for _, entry in ipairs(project and project.recipe or {}) do
        local fullType = tostring(entry.fullType or "")
        local required = math.max(0, math.floor(tonumber(entry.count) or 0))
        local supplied = math.min(required, math.max(0, tonumber(project and project.materialCounts and project.materialCounts[fullType]) or 0))
        local available = math.max(0, resolvedAvailableCounts[fullType] or 0)
        local remaining = math.max(0, required - supplied)
        local recipeEntry = {
            fullType = fullType,
            displayName = getDisplayName(fullType),
            count = required,
            available = available,
            supplied = supplied,
            remaining = remaining,
            satisfied = remaining <= 0
        }
        if recipeEntry.satisfied ~= true then
            hasAll = false
        end
        entries[#entries + 1] = recipeEntry
    end

    return {
        hasAll = hasAll,
        entries = entries,
        totalRequired = totalRequired,
        totalSupplied = totalSupplied,
        progressRatio = totalRequired > 0 and math.max(0, math.min(1, totalSupplied / totalRequired)) or 1
    }
end

local function consumeRecipe(ownerUsername, recipe)
    local warehouseApi = getWarehouse()
    local warehouse = warehouseApi and warehouseApi.GetOwnerWarehouse and warehouseApi.GetOwnerWarehouse(ownerUsername) or nil
    if not warehouse then
        return false
    end

    local required = buildRecipeMap(recipe)
    if not hasRecipeEntries(required) then
        return true
    end

    local outputLedger = warehouse.ledgers and warehouse.ledgers.output or {}

    for fullType, needed in pairs(required) do
        local available = 0
        for _, entry in ipairs(outputLedger) do
            if entry.fullType == fullType then
                available = available + math.max(0, math.floor(tonumber(entry.qty) or 0))
            end
        end
        if available < needed then
            return false
        end
    end

    for index = #outputLedger, 1, -1 do
        local entry = outputLedger[index]
        local fullType = tostring(entry and entry.fullType or "")
        local needed = required[fullType]
        if needed and needed > 0 and entry then
            local qty = math.max(0, math.floor(tonumber(entry.qty) or 0))
            local toTake = math.min(qty, needed)
            qty = qty - toTake
            required[fullType] = needed - toTake
            if qty <= 0 then
                table.remove(outputLedger, index)
            else
                entry.qty = qty
            end
        end
    end

    if warehouseApi and warehouseApi.Recalculate then
        warehouseApi.Recalculate(warehouse)
    end
    return true
end

-- Internal exports

Internal.BuildingsConsumeRecipe = consumeRecipe
Internal.GetAvailableMaterialCounts = getAvailableMaterialCounts
Internal.BuildRecipeAvailability = buildRecipeAvailability

-- Public API

function Buildings.GetProjectMaterialStatus(project, sourcePlayer, availableCounts)
    return buildProjectMaterialStatus(project, sourcePlayer, availableCounts)
end

function Buildings.RefreshProjectMaterialState(project)
    if not project or tostring(project.status or "") ~= "Active" then
        return buildProjectMaterialStatus(project)
    end

    ensureProjectMaterialTracking(project)
    pullProjectMaterialsFromWarehouse(project)

    local materialStatus = buildProjectMaterialStatus(project)
    project.materialState = materialStatus.hasAll and "Ready" or "Stalled"
    project.materialProgressRatio = materialStatus.progressRatio
    return materialStatus
end

function Buildings.RefreshOwnerProjectMaterials(ownerUsername)
    local owner = getOwnerUsername(ownerUsername)
    local changed = false

    for _, project in pairs(Buildings.GetProjectsForOwner(owner)) do
        if tostring(project.status or "") == "Active" then
            local beforeState = tostring(project.materialState or "")
            local beforeRatio = tonumber(project.materialProgressRatio) or -1
            local beforeCounts = normalizeMaterialCountMap(project.materialCounts)
            local beforeTotal = 0
            for _, count in pairs(beforeCounts) do
                beforeTotal = beforeTotal + count
            end

            local materialStatus = Buildings.RefreshProjectMaterialState(project)
            local afterTotal = 0
            for _, count in pairs(project.materialCounts or {}) do
                afterTotal = afterTotal + (tonumber(count) or 0)
            end

            if beforeState ~= tostring(project.materialState or "")
                or math.abs(beforeRatio - (tonumber(project.materialProgressRatio) or 0)) > 0.0001
                or beforeTotal ~= afterTotal
                or (materialStatus and materialStatus.hasAll and beforeState ~= "Ready") then
                changed = true
            end
        end
    end

    if changed then
        Buildings.Save()
    end

    return changed
end

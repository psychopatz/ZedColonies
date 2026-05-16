DC_Colony = DC_Colony or {}
DC_Colony.Recycler = DC_Colony.Recycler or {}
DC_Colony.Recycler.Internal = DC_Colony.Recycler.Internal or {}

local Recycler = DC_Colony.Recycler
local Internal = Recycler.Internal
local Research = DC_Colony.Research
local Skills = DC_Colony.Skills
local Registry = DC_Colony.Registry
local Config = DC_Colony.Config
local Warehouse = DC_Colony.Warehouse

local function getDisplayName(fullType)
    local registry = DC_Colony and DC_Colony.Registry or nil
    local internal = registry and registry.Internal or nil
    return internal and internal.GetDisplayNameForFullType and internal.GetDisplayNameForFullType(fullType) or tostring(fullType or "Unknown")
end

local function getCategoryDisplayName(categoryId)
    local definition = Config and Config.GetItemCategoryDefinition and Config.GetItemCategoryDefinition(categoryId) or nil
    return tostring(definition and definition.displayName or categoryId or "Unknown")
end

function Internal.GetLeadCrafterStats(ownerUsername)
    local bestName = ""
    local bestLevel = 0
    local deadState = tostring(Config and Config.States and Config.States.Dead or "Dead")

    for _, worker in ipairs(Registry and Registry.GetWorkersForOwnerRaw and Registry.GetWorkersForOwnerRaw(ownerUsername) or {}) do
        if tostring(worker and worker.state or "") ~= deadState then
            local entry = Skills and Skills.GetSkillEntry and Skills.GetSkillEntry(worker, "Crafting") or nil
            local level = math.max(0, math.floor(tonumber(entry and entry.level) or 0))
            if level > bestLevel or bestName == "" then
                bestLevel = level
                bestName = tostring(worker and worker.name or worker and worker.workerID or "")
            end
        end
    end

    return {
        name = bestName,
        level = bestLevel,
        recoveryChance = Recycler.Config and Recycler.Config.GetRecoveryChance and Recycler.Config.GetRecoveryChance(bestLevel) or 0.20,
    }
end

local function appendRecoveredEntry(target, key, entry)
    if not target[key] then
        target[key] = entry
    else
        target[key].count = math.max(0, tonumber(target[key].count) or 0) + math.max(0, tonumber(entry.count) or 0)
    end
end

local function buildRecoveryPreview(fullType, ownerUsername)
    local blueprint = Research and Research.Internal and Research.Internal.BuildBlueprintRecord
        and Research.Internal.BuildBlueprintRecord(fullType) or nil
    if not blueprint then
        return nil
    end

    local crafter = Internal.GetLeadCrafterStats(ownerUsername)
    local recovered = {}
    for _, input in ipairs(blueprint.inputs or {}) do
        local count = math.max(1, math.floor(tonumber(input and input.count) or 1))
        local expected = math.max(0, math.floor((count * crafter.recoveryChance) + 0.0001))
        if tostring(input and input.kind or "") == "fullType" and tostring(input and input.fullType or "") ~= "" then
            appendRecoveredEntry(recovered, "fullType:" .. tostring(input.fullType), {
                kind = "fullType",
                fullType = tostring(input.fullType),
                displayName = getDisplayName(input.fullType),
                count = expected,
            })
        elseif tostring(input and input.category or "") ~= "" then
            appendRecoveredEntry(recovered, "category:" .. tostring(input.category), {
                kind = "category",
                category = tostring(input.category),
                displayName = getCategoryDisplayName(input.category),
                count = expected,
            })
        end
    end

    local recoveredList = {}
    for _, entry in pairs(recovered) do
        recoveredList[#recoveredList + 1] = entry
    end
    table.sort(recoveredList, function(a, b)
        return tostring(a and a.displayName or "") < tostring(b and b.displayName or "")
    end)

    return {
        fullType = tostring(fullType or ""),
        displayName = getDisplayName(fullType),
        buildingType = tostring(blueprint.buildingType or ""),
        buildingDisplayName = tostring(blueprint.buildingDisplayName or blueprint.buildingType or "Unknown"),
        recipeName = tostring(blueprint.recipeName or "Unknown Recipe"),
        inputs = blueprint.inputs or {},
        expectedRecovered = recoveredList,
        crafterName = tostring(crafter.name or ""),
        craftingLevel = math.max(0, math.floor(tonumber(crafter.level) or 0)),
        recoveryChance = math.max(0, tonumber(crafter.recoveryChance) or 0),
    }
end

function Recycler.CanRecycleItem(fullType)
    return buildRecoveryPreview(fullType, "") ~= nil
end

function Recycler.BuildRecyclePreview(fullType, ownerUsername)
    return buildRecoveryPreview(fullType, ownerUsername)
end

function Recycler.RecycleItem(ownerUsername, fullType)
    local preview = buildRecoveryPreview(fullType, ownerUsername)
    if not preview then
        return false, "That item has no supported craft recipe to recycle.", nil
    end

    local recoveredEntries = {}
    for _, input in ipairs(preview.inputs or {}) do
        local count = math.max(1, math.floor(tonumber(input and input.count) or 1))
        local recoveredCount = 0
        local rollIndex = 1
        while rollIndex <= count do
            if ZombRandFloat and ZombRandFloat(0, 1) < preview.recoveryChance then
                recoveredCount = recoveredCount + 1
            end
            rollIndex = rollIndex + 1
        end

        if recoveredCount > 0 then
            if tostring(input and input.kind or "") == "fullType" and tostring(input and input.fullType or "") ~= "" then
                local added = Warehouse.DepositOutputEntry(ownerUsername, {
                    fullType = tostring(input.fullType),
                    qty = recoveredCount,
                    forceLiteral = true,
                })
                if added > 0 then
                    recoveredEntries[#recoveredEntries + 1] = {
                        kind = "fullType",
                        fullType = tostring(input.fullType),
                        displayName = getDisplayName(input.fullType),
                        count = added,
                    }
                end
            elseif tostring(input and input.category or "") ~= "" then
                local added = Warehouse.AddCategory(ownerUsername, tostring(input.category), recoveredCount, {
                    totalWeight = 0,
                })
                if added > 0 then
                    recoveredEntries[#recoveredEntries + 1] = {
                        kind = "category",
                        category = tostring(input.category),
                        displayName = getCategoryDisplayName(input.category),
                        count = added,
                    }
                end
            end
        end
    end

    return true, nil, {
        fullType = preview.fullType,
        displayName = preview.displayName,
        crafterName = preview.crafterName,
        craftingLevel = preview.craftingLevel,
        recoveryChance = preview.recoveryChance,
        recoveredEntries = recoveredEntries,
    }
end

return Recycler

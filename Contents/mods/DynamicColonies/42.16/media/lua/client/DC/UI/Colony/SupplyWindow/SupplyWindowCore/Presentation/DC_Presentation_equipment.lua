DC_SupplyWindow = DC_SupplyWindow or {}
DC_SupplyWindow.Internal = DC_SupplyWindow.Internal or {}

local Internal = DC_SupplyWindow.Internal

local function getRequirementDefinitions(worker)
    local config = Internal.Config or {}
    if config.GetWorkerEquipmentRequirementDefinitions then
        return config.GetWorkerEquipmentRequirementDefinitions(worker) or {}
    end
    if config.GetEquipmentRequirementDefinitions then
        return config.GetEquipmentRequirementDefinitions(worker and worker.jobType) or {}
    end
    return {}
end

local function getWorkerToolTagMap(worker)
    local tagMap = {}
    local config = Internal.Config or {}
    local registryInternal = DC_Colony and DC_Colony.Registry and DC_Colony.Registry.Internal or nil

    for _, ledgerEntry in ipairs(worker and worker.toolLedger or {}) do
        if not registryInternal or not registryInternal.IsEquipmentEntryUsable or registryInternal.IsEquipmentEntryUsable(ledgerEntry) then
            local tags = ledgerEntry and ledgerEntry.tags or {}
            if config.GetItemCombinedTags and ledgerEntry and ledgerEntry.fullType then
                tags = config.GetItemCombinedTags(ledgerEntry.fullType)
            end

            for _, tag in ipairs(tags or {}) do
                local key = tostring(tag or "")
                if key ~= "" then
                    tagMap[key] = true
                end
            end
        end
    end

    return tagMap
end

local function workerHasRequirementDefinition(worker, definition)
    local config = Internal.Config or {}
    local tagMap = getWorkerToolTagMap(worker)

    for itemTag, enabled in pairs(tagMap) do
        if enabled then
            for _, requirementTag in ipairs(definition and definition.requirementTags or {}) do
                if config.TagMatches and config.TagMatches(itemTag, requirementTag) then
                    return true
                end
                if tostring(itemTag or "") == tostring(requirementTag or "") then
                    return true
                end
            end
        end
    end

    return false
end

local function getRequirementProgress(worker, definition)
    local currentCount = tonumber(definition and definition.currentCount)
    if currentCount == nil then
        currentCount = workerHasRequirementDefinition(worker, definition) and 1 or 0
    end

    local minimumCount = math.max(0, tonumber(definition and definition.minimumCount) or 0)
    local targetCount = math.max(minimumCount, tonumber(definition and definition.targetCount) or minimumCount)
    if targetCount <= 0 then
        targetCount = math.max(1, currentCount)
    end

    return {
        currentCount = math.max(0, math.floor(currentCount)),
        minimumCount = minimumCount,
        targetCount = targetCount,
    }
end

function Internal.getMissingEquipmentPlaceholderEntries(worker)
    local entries = {}

    for _, definition in ipairs(getRequirementDefinitions(worker)) do
        local requirementKey = tostring(definition and definition.requirementKey or "")
        local skipRequirement = requirementKey == "Colony.Combat.Ammo"
            and not (Internal.isAmmoRequirementActive and Internal.isAmmoRequirementActive(worker))
        local progress = getRequirementProgress(worker, definition)
        local missingTarget = progress.currentCount < progress.targetCount

        if not skipRequirement and missingTarget then
            local iconFullType = definition.iconFullType
            if requirementKey == "Colony.Combat.Ammo" and Internal.getWorkerRangedAmmoFullType then
                iconFullType = Internal.getWorkerRangedAmmoFullType(worker) or iconFullType
            end
            entries[#entries + 1] = Internal.buildWorkerToolPlaceholderEntry({
                requirementKey = requirementKey,
                displayName = definition.label,
                hintText = definition.hintText,
                reasonText = definition.reasonText,
                searchText = definition.searchText or requirementKey,
                requirementTags = definition.requirementTags or { definition.requirementKey },
                supportedFullTypes = definition.supportedFullTypes,
                iconFullType = iconFullType,
                currentCount = progress.currentCount,
                minimumCount = progress.minimumCount,
                targetCount = progress.targetCount,
                blocking = definition.blocking == true and progress.currentCount < progress.minimumCount,
                statusText = definition.statusText or definition.hintText,
            })
        end
    end

    return entries
end

function Internal.getMissingEquipmentSummary(worker, maxCount)
    local placeholders = Internal.getMissingEquipmentPlaceholderEntries(worker)
    if #placeholders <= 0 then
        local config = Internal.Config or {}
        local normalizedJob = config.NormalizeJobType and config.NormalizeJobType(worker and worker.jobType) or tostring(worker and worker.jobType or "")
        if normalizedJob == ((config.JobTypes or {}).Scavenge) then
            return "Scavenger loadout ready"
        end
        if normalizedJob == ((config.JobTypes or {}).Gatherer) then
            return "Gatherer loadout ready"
        end
        return "Required equipment already equipped"
    end

    local limit = math.max(1, math.floor(tonumber(maxCount) or 3))
    local labels = {}
    for index = 1, math.min(limit, #placeholders) do
        labels[#labels + 1] = tostring(placeholders[index].displayName or "Tool")
    end

    local summary = "Needs: " .. table.concat(labels, ", ")
    if #placeholders > limit then
        summary = summary .. " +" .. tostring(#placeholders - limit) .. " more"
    end

    return summary
end

function Internal.getRequiredToolSummary(worker)
    local definitions = getRequirementDefinitions(worker)
    if #definitions <= 0 then
        return "Any equipment"
    end

    local labels = {}
    for _, definition in ipairs(definitions) do
        local progress = getRequirementProgress(worker, definition)
        local label = tostring(definition.label or definition.requirementKey or "Tool")
        if progress.targetCount > 1 then
            label = label .. " x" .. tostring(progress.targetCount)
        end
        labels[#labels + 1] = label
    end

    return table.concat(labels, ", ")
end

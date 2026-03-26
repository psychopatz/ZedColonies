DC_SupplyWindow = DC_SupplyWindow or {}
DC_SupplyWindow.Internal = DC_SupplyWindow.Internal or {}

local Internal = DC_SupplyWindow.Internal

local function getRequirementDefinitions(worker)
    local config = Internal.Config or {}
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

function Internal.getMissingEquipmentPlaceholderEntries(worker)
    local entries = {}

    for _, definition in ipairs(getRequirementDefinitions(worker)) do
        if not workerHasRequirementDefinition(worker, definition) then
            entries[#entries + 1] = Internal.buildWorkerToolPlaceholderEntry({
                requirementKey = definition.requirementKey,
                displayName = definition.label,
                hintText = definition.hintText,
                reasonText = definition.reasonText,
                searchText = definition.searchText or definition.requirementKey,
                requirementTags = definition.requirementTags or { definition.requirementKey },
                supportedFullTypes = definition.supportedFullTypes,
                iconFullType = definition.iconFullType,
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
        return "Required tools already equipped"
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
        return "Any labour tool"
    end

    local labels = {}
    for _, definition in ipairs(definitions) do
        labels[#labels + 1] = tostring(definition.label or definition.requirementKey or "Tool")
    end

    return table.concat(labels, ", ")
end

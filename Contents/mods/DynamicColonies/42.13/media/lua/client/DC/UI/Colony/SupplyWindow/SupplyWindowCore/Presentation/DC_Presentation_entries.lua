DC_SupplyWindow = DC_SupplyWindow or {}
DC_SupplyWindow.Internal = DC_SupplyWindow.Internal or {}

local Internal = DC_SupplyWindow.Internal

local function entryMatchesAnyRequirementTag(entry, requirementTags)
    if entry and entry.kind == "player" and Internal.ensurePlayerEntryEquipmentData then
        Internal.ensurePlayerEntryEquipmentData(entry)
    end

    if not entry or entry.kind == "money" or entry.canAssignTool ~= true then
        return false
    end

    local config = Internal.Config or {}
    local entryTags = entry.tags or {}
    for _, requiredTag in ipairs(requirementTags or {}) do
        local requiredKey = tostring(requiredTag or "")
        for _, itemTag in ipairs(entryTags) do
            local itemKey = tostring(itemTag or "")
            if itemKey == requiredKey then
                return true
            end
            if config.TagMatches and config.TagMatches(itemKey, requiredKey) then
                return true
            end
        end
    end

    return false
end

local function buildSupportEntriesFromFullTypes(fullTypes)
    local entries = {}
    local seen = {}

    for _, fullType in ipairs(fullTypes or {}) do
        local key = tostring(fullType or "")
        if key ~= "" and not seen[key] then
            seen[key] = true
            entries[#entries + 1] = {
                fullType = key,
                displayName = Internal.getDisplayNameForFullType(key),
                texture = Internal.getTextureForFullType(key),
            }
        end
    end

    return entries
end

function Internal.getPlaceholderSupportDisplay(window, entry)
    if not entry or entry.kind ~= "placeholder" then
        return {
            title = "",
            entries = {},
            hasMatches = false,
        }
    end

    local matches = {}
    local seenMatches = {}
    for _, playerEntry in ipairs(window and window.playerEntries or {}) do
        if entryMatchesAnyRequirementTag(playerEntry, entry.requirementTags or entry.tags or {}) then
            local key = tostring(playerEntry.fullType or playerEntry.itemID or "")
            if key ~= "" and not seenMatches[key] then
                seenMatches[key] = true
                matches[#matches + 1] = {
                    fullType = playerEntry.fullType,
                    displayName = playerEntry.displayName,
                    texture = playerEntry.texture or Internal.getTextureForFullType(playerEntry.fullType),
                }
            end
        end
    end

    if #matches > 0 then
        return {
            title = "Available Matches",
            entries = matches,
            hasMatches = true,
        }
    end

    return {
        title = "Supported Examples",
        entries = buildSupportEntriesFromFullTypes(entry.supportedFullTypes),
        hasMatches = false,
    }
end

local function appendWeightText(baseText, entry)
    local weight = math.max(0, tonumber(entry and entry.totalWeight) or tonumber(entry and entry.unitWeight) or 0)
    local weightText = "W " .. Internal.formatWeightValue(weight)
    if not baseText or baseText == "" then
        return weightText
    end
    return tostring(baseText) .. " | " .. weightText
end

local function isMedicalProvisionEntry(entry)
    return tostring(entry and entry.provisionType or "") == "medical" or (tonumber(entry and entry.treatmentUnits) or 0) > 0
end

local function getEquipmentMatchSummary(entry, worker)
    local config = Internal.Config or {}
    if not entry
        or not worker
        or not worker.jobType
        or not (config.GetMatchingEquipmentRequirementDefinitionsForWorker or config.GetMatchingEquipmentRequirementDefinitions) then
        return nil
    end

    if entry.kind == "player" and Internal.ensurePlayerEntryEquipmentData then
        Internal.ensurePlayerEntryEquipmentData(entry)
    end

    local matches = Internal.getPlayerEntryEquipmentMatches
        and Internal.getPlayerEntryEquipmentMatches(entry, worker)
        or (config.GetMatchingEquipmentRequirementDefinitionsForWorker
            and config.GetMatchingEquipmentRequirementDefinitionsForWorker(entry.fullType, worker)
            or config.GetMatchingEquipmentRequirementDefinitions(entry.fullType, worker.jobType)
            or {})
    if #matches <= 0 then
        return nil
    end

    local labels = {}
    for _, definition in ipairs(matches) do
        labels[#labels + 1] = tostring(definition.label or definition.requirementKey or "Equipment")
    end

    return table.concat(labels, ", ")
end

local function getGroupCountLabel(entry)
    local count = math.max(1, tonumber(entry and entry.childCount) or 1)
    return tostring(count) .. " item" .. (count == 1 and "" or "s")
end

local function appendWorkerInventoryWeight(summary, worker)
    local inventoryState = Internal.getWorkerInventoryWeightState and Internal.getWorkerInventoryWeightState(worker) or nil
    if not inventoryState then
        return summary
    end

    return summary
        .. " | Inv "
        .. Internal.formatWeightValue(inventoryState.usedWeight)
        .. " / "
        .. Internal.formatWeightValue(inventoryState.maxWeight)
end

local function appendSegment(baseText, extraText)
    local normalizedExtra = tostring(extraText or "")
    if normalizedExtra == "" then
        return baseText
    end
    if not baseText or baseText == "" then
        return normalizedExtra
    end
    return tostring(baseText) .. " | " .. normalizedExtra
end

local function applyRottenTitleSuffix(presentation, entry)
    if type(presentation) ~= "table" then
        return presentation
    end

    if type(entry) ~= "table" then
        return presentation
    end

    if entry.isRottenProvision == true or tostring(entry.provisionBlockedReason or "") ~= "" then
        presentation.titleSuffixText = " (Rotten)"
        presentation.titleSuffixColor = { r = 0.92, g = 0.34, b = 0.34 }
    end

    return presentation
end

local function shouldShowEquipmentDurability(entry)
    if type(entry) ~= "table" then
        return false
    end

    if entry.kind == "tool" then
        return true
    end

    if entry.canAssignTool == true or entry.hasEquipmentRequirementMatch == true then
        return true
    end

    local fullType = tostring(entry.fullType or "")
    return fullType ~= ""
        and Internal.Config
        and Internal.Config.IsColonyToolFullType
        and Internal.Config.IsColonyToolFullType(fullType)
        or false
end

local function getDurabilityText(entry)
    if type(entry) ~= "table" then
        return ""
    end

    if not shouldShowEquipmentDurability(entry) then
        return ""
    end

    local parts = {}
    local conditionMax = math.max(0, tonumber(entry.conditionMax) or 0)
    if conditionMax > 0 then
        local condition = math.max(0, math.floor(tonumber(entry.condition) or 0))
        parts[#parts + 1] = "Cond " .. tostring(condition) .. "/" .. tostring(conditionMax)
        if condition <= 0 then
            parts[#parts + 1] = "Broken"
        end
    end

    if entry.isDrainable == true then
        local remaining = math.max(0, tonumber(entry.usedDelta) or 0)
        local percent = math.max(0, math.min(100, math.floor((remaining * 100) + 0.5)))
        parts[#parts + 1] = "Charge " .. tostring(percent) .. "%"

        local useDelta = math.max(0, tonumber(entry.useDelta) or 0)
        if useDelta > 0 and remaining + 0.0001 < useDelta then
            parts[#parts + 1] = entry.keepOnDeplete == true and "Empty" or "Depleted"
        end
    end

    return table.concat(parts, " | ")
end

local function getEquipmentConditionBarData(entry)
    if type(entry) ~= "table" then
        return nil
    end

    if not shouldShowEquipmentDurability(entry) then
        return nil
    end

    local conditionMax = math.max(0, tonumber(entry.conditionMax) or 0)
    if conditionMax > 0 then
        local condition = math.max(0, math.min(conditionMax, tonumber(entry.condition) or 0))
        return {
            fillPercent = math.max(0, math.min(1, condition / conditionMax)),
            label = "Cond " .. tostring(math.floor(condition)) .. "/" .. tostring(conditionMax),
        }
    end

    if entry.isDrainable == true then
        local remaining = math.max(0, math.min(1, tonumber(entry.usedDelta) or 0))
        return {
            fillPercent = remaining,
            label = "Charge " .. tostring(math.floor((remaining * 100) + 0.5)) .. "%",
        }
    end

    return nil
end

Internal.getEquipmentConditionBarData = getEquipmentConditionBarData
Internal.getEquipmentDurabilityText = getDurabilityText

local function getOutputStateText(entry)
    if type(entry) ~= "table" or entry.fluidAmount == nil then
        return ""
    end

    local fluidAmount = math.max(0, tonumber(entry.fluidAmount) or 0)
    if fluidAmount <= 0.0001 then
        return "Empty"
    end

    return "Fluid " .. string.format("%.0f", fluidAmount)
end

function Internal.getWorkerTabSummary(window, entries)
    local activeTab = window and window.activeTab or Internal.Tabs.Provisions

    if activeTab == Internal.Tabs.Equipment then
        local equippedCount = 0
        local missingCount = 0
        for _, entry in ipairs(entries or {}) do
            if entry and entry.kind == "placeholder" then
                missingCount = missingCount + 1
            else
                equippedCount = equippedCount + math.max(1, tonumber(entry and entry.qty) or 1)
            end
        end

        local summary = tostring(equippedCount) .. " equipped"
        if Internal.isWarehouseView and Internal.isWarehouseView(window) then
            summary = summary .. " | Weight " .. Internal.formatWeightValue(Internal.getWarehouseLedgerWeight(window and window.workerData, activeTab)) .. " total"
        else
            summary = summary .. " | Tab Weight " .. Internal.formatWeightValue(Internal.getWorkerLedgerWeight(window and window.workerData, activeTab))
            summary = appendWorkerInventoryWeight(summary, window and window.workerData)
        end
        if missingCount > 0 then
            summary = summary .. " | " .. tostring(missingCount) .. " missing"
        end
        return summary
    end

    if activeTab == Internal.Tabs.Output then
        local stacks = 0
        local totalQty = 0
        for _, entry in ipairs(entries or {}) do
            stacks = stacks + 1
            totalQty = totalQty + math.max(1, tonumber(entry.qty) or 1)
        end
        local worker = window and window.workerData or nil
        local config = Internal.Config or {}
        local normalizedJob = config.NormalizeJobType and config.NormalizeJobType(worker and worker.jobType) or tostring(worker and worker.jobType or "")
        if Internal.isWarehouseView and Internal.isWarehouseView(window) then
            local warehouse = worker and worker.warehouse or nil
            local tabWeight = Internal.getEntryWeightTotal(entries)
            return tostring(stacks)
                .. " stacks | "
                .. tostring(totalQty)
                .. " total | Tab Weight "
                .. Internal.formatWeightValue(tabWeight)
                .. " | Warehouse "
                .. Internal.formatWeightValue(warehouse and warehouse.usedWeight)
                .. " / "
                .. Internal.formatWeightValue(warehouse and warehouse.maxWeight)
        end

        local summary = tostring(stacks)
            .. " stacks | "
            .. tostring(totalQty)
            .. " total | Tab Weight "
            .. Internal.formatWeightValue(Internal.getWorkerLedgerWeight(window and window.workerData, activeTab))
        if normalizedJob == ((config.JobTypes or {}).Scavenge) then
            summary = summary
                .. " | Carry "
                .. Internal.formatWeightValue(worker and worker.haulRawWeight)
                .. " carried"
        end
        return appendWorkerInventoryWeight(summary, worker)
    end

    local totals = Internal.getWorkerSupplyTotals(entries)
    local summary = tostring(totals.count) .. " entries | "
        .. string.format("%.0f cal", totals.calories) .. " | "
        .. string.format("%.0f hyd", totals.hydration)
    if totals.medicalUnits > 0 then
        summary = summary .. " | " .. tostring(math.floor(totals.medicalUnits + 0.5)) .. " treatment"
    end
    if Internal.isWarehouseView and Internal.isWarehouseView(window) then
        summary = summary .. " | Weight " .. Internal.formatWeightValue(Internal.getWarehouseLedgerWeight(window and window.workerData, activeTab)) .. " total"
    else
        summary = summary .. " | Tab Weight " .. Internal.formatWeightValue(Internal.getWorkerLedgerWeight(window and window.workerData, activeTab))
        summary = appendWorkerInventoryWeight(summary, window and window.workerData)
    end
    if totals.money > 0 then
        summary = summary .. " | $" .. tostring(totals.money)
    end
    return summary
end

function Internal.getPlayerEntryPresentation(entry, activeTab, worker, window)
    if Internal.isGroupEntry and Internal.isGroupEntry(entry) then
        if activeTab == Internal.Tabs.Equipment then
            local durabilityText = getDurabilityText(entry)
            return {
                statText = appendWeightText(appendSegment(getGroupCountLabel(entry), durabilityText), entry),
                badgeText = entry.canAssignTool and "Tool" or "Preview",
                dimmed = entry.canAssignTool ~= true,
            }
        end

        if activeTab == Internal.Tabs.Output then
            if Internal.isWarehouseView and Internal.isWarehouseView(window) then
                return applyRottenTitleSuffix({
                    statText = appendWeightText(
                        appendSegment(
                            getGroupCountLabel(entry) .. " | Qty " .. tostring(entry.totalQty or entry.qty or 0),
                            appendSegment(getDurabilityText(entry), getOutputStateText(entry))
                        ),
                        entry
                    ),
                    badgeText = "Ready",
                    dimmed = false,
                }, entry)
            end
            return applyRottenTitleSuffix({
                statText = appendWeightText(
                    appendSegment(
                        getGroupCountLabel(entry) .. " in worker storage view",
                        appendSegment(getDurabilityText(entry), getOutputStateText(entry))
                    ),
                    entry
                ),
                badgeText = "Read Only",
                dimmed = true,
            }, entry)
        end

        if isMedicalProvisionEntry(entry) then
            return {
                statText = appendWeightText(
                    getGroupCountLabel(entry) .. " | " .. tostring(math.floor((tonumber(entry.treatmentUnits) or 0) + 0.5)) .. " treatment total",
                    entry
                ),
                badgeText = "Medical",
                dimmed = false,
            }
        end

        if entry.canDeposit then
            return applyRottenTitleSuffix({
                statText = appendWeightText(
                    getGroupCountLabel(entry) .. " | +" .. string.format("%.0f cal | +%.0f hyd", entry.calories or 0, entry.hydration or 0),
                    entry
                ),
                badgeText = "Ready",
                dimmed = false,
            }, entry)
        end

        if tostring(entry.provisionBlockedReason or "") ~= "" then
            return applyRottenTitleSuffix({
                statText = appendWeightText(
                    getGroupCountLabel(entry) .. " | +" .. string.format("%.0f cal | +%.0f hyd", entry.calories or 0, entry.hydration or 0),
                    entry
                ),
                badgeText = "",
                dimmed = true,
            }, entry)
        end

        return {
            statText = appendWeightText(getGroupCountLabel(entry) .. " not valid as provisions", entry),
            badgeText = "Preview",
            dimmed = true,
        }
    end

    if entry.kind == "money" then
        return {
            statText = "$" .. tostring(math.max(0, math.floor(tonumber(entry.amount) or 0))) .. " available to deposit",
            badgeText = "Cash",
            dimmed = false,
        }
    end

    if activeTab == Internal.Tabs.Equipment then
        if entry.kind == "player" and Internal.ensurePlayerEntryEquipmentData then
            Internal.ensurePlayerEntryEquipmentData(entry)
        end
        local durabilityText = getDurabilityText(entry)
        return {
            statText = appendWeightText(durabilityText ~= "" and durabilityText or "No condition data", entry),
            badgeText = entry.canAssignTool and "Tool" or "Preview",
            dimmed = entry.canAssignTool ~= true,
        }
    end

    if activeTab == Internal.Tabs.Output then
        if Internal.isWarehouseView and Internal.isWarehouseView(window) then
            return applyRottenTitleSuffix({
                statText = appendWeightText(
                    appendSegment("Store in warehouse storage", appendSegment(getDurabilityText(entry), getOutputStateText(entry))),
                    entry
                ),
                badgeText = "Ready",
                dimmed = false,
            }, entry)
        end
        return applyRottenTitleSuffix({
            statText = appendWeightText(
                appendSegment("Worker storage tab", appendSegment(getDurabilityText(entry), getOutputStateText(entry))),
                entry
            ),
            badgeText = "Read Only",
            dimmed = true,
        }, entry)
    end

    if entry.canDeposit and isMedicalProvisionEntry(entry) then
        return applyRottenTitleSuffix({
            statText = appendWeightText("+" .. tostring(math.floor((tonumber(entry.treatmentUnits) or 0) + 0.5)) .. " treatment units", entry),
            badgeText = "Medical",
            dimmed = false,
        }, entry)
    end

    if entry.canDeposit then
        return applyRottenTitleSuffix({
            statText = appendWeightText(string.format("+%.0f cal | +%.0f hyd", entry.calories or 0, entry.hydration or 0), entry),
            badgeText = "Ready",
            dimmed = false,
        }, entry)
    end

    if tostring(entry.provisionBlockedReason or "") ~= "" then
        return applyRottenTitleSuffix({
            statText = appendWeightText(string.format("+%.0f cal | +%.0f hyd", entry.calories or 0, entry.hydration or 0), entry),
            badgeText = "",
            dimmed = true,
        }, entry)
    end

    return {
        statText = appendWeightText("Not a valid provision item", entry),
        badgeText = "Preview",
        dimmed = true,
    }
end

function Internal.getWorkerEntryPresentation(entry, activeTab)
    if Internal.isGroupEntry and Internal.isGroupEntry(entry) then
        if activeTab == Internal.Tabs.Equipment then
            return {
                statText = appendWeightText(appendSegment(getGroupCountLabel(entry) .. " assigned", getDurabilityText(entry)), entry),
                badgeText = "",
            }
        end

        if activeTab == Internal.Tabs.Output then
            return applyRottenTitleSuffix({
                statText = appendWeightText(
                    appendSegment(
                        getGroupCountLabel(entry) .. " | Qty " .. tostring(entry.totalQty or entry.qty or 0),
                        appendSegment(getDurabilityText(entry), getOutputStateText(entry))
                    ),
                    entry
                ),
                badgeText = "",
            }, entry)
        end

        if isMedicalProvisionEntry(entry) then
            return {
                statText = appendWeightText(
                    getGroupCountLabel(entry) .. " | " .. tostring(math.floor((tonumber(entry.treatmentUnits) or 0) + 0.5)) .. " treatment total",
                    entry
                ),
                badgeText = "Medical",
            }
        end

        return {
            statText = appendWeightText(
                getGroupCountLabel(entry) .. " | " .. string.format("%.0f cal | %.0f hyd", entry.calories or 0, entry.hydration or 0),
                entry
            ),
            badgeText = "",
        }
    end

    if entry.kind == "money" then
        return {
            statText = "$" .. tostring(math.max(0, math.floor(tonumber(entry.amount) or 0))) .. " stored with the worker",
            badgeText = "Cash",
        }
    end

    if activeTab == Internal.Tabs.Equipment then
        if entry.kind == "placeholder" then
            return {
                statText = tostring(entry.hintText or "Assign a matching tool from the player inventory"),
                badgeText = "Needed",
                dimmed = false,
            }
        end

        return {
            statText = appendWeightText(getDurabilityText(entry) ~= "" and getDurabilityText(entry) or "No condition data", entry),
            badgeText = "",
        }
    end

    if activeTab == Internal.Tabs.Output then
        return applyRottenTitleSuffix({
            statText = appendWeightText(
                appendSegment("Qty " .. tostring(entry.qty or 1), appendSegment(getDurabilityText(entry), getOutputStateText(entry))),
                entry
            ),
            badgeText = "",
        }, entry)
    end

    if isMedicalProvisionEntry(entry) then
        local qty = math.max(1, tonumber(entry.qty) or 1)
        local totalUnits = tonumber(entry.totalTreatmentUnits) or ((tonumber(entry.treatmentUnits) or 0) * qty)
        local unitText = tostring(math.floor(totalUnits + 0.5)) .. " treatment units"
        if qty > 1 then
            unitText = "Qty " .. tostring(qty) .. " | " .. unitText
        end
        return {
            statText = appendWeightText(unitText, entry),
            badgeText = "Medical",
        }
    end

    local qty = math.max(1, tonumber(entry.qty) or 1)
    local calories = tonumber(entry.totalCalories) or ((tonumber(entry.calories) or 0) * qty)
    local hydration = tonumber(entry.totalHydration) or ((tonumber(entry.hydration) or 0) * qty)
    local statText = string.format("%.0f cal left | %.0f hyd left", calories, hydration)
    if qty > 1 then
        statText = "Qty " .. tostring(qty) .. " | " .. statText
    end
    return {
        statText = appendWeightText(statText, entry),
        badgeText = "",
    }
end

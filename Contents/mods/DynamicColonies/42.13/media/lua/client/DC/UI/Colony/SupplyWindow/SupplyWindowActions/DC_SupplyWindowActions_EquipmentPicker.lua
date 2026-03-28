DC_SupplyWindow = DC_SupplyWindow or {}
DC_SupplyWindow.Internal = DC_SupplyWindow.Internal or {}

local Internal = DC_SupplyWindow.Internal

local function getRequirementDefinitionForEntry(entry, worker)
    local config = Internal.Config or {}
    if not entry or not worker then
        return nil
    end

    if Internal.isGroupEntry and Internal.isGroupEntry(entry) then
        local children = entry.childEntries or {}
        entry = children[1]
    end

    if not entry then
        return nil
    end

    if entry.kind == "placeholder" and config.GetEquipmentRequirementDefinition then
        return config.GetEquipmentRequirementDefinition(entry.requirementKey)
    end

    local matches = config.GetMatchingEquipmentRequirementDefinitionsForWorker
        and config.GetMatchingEquipmentRequirementDefinitionsForWorker(entry.fullType, worker)
        or (config.GetMatchingEquipmentRequirementDefinitions
            and config.GetMatchingEquipmentRequirementDefinitions(entry.fullType, worker.jobType)
            or {})
    return matches[1]
end

local function getRequirementMatch(entry, definition, worker)
    local config = Internal.Config or {}
    if not entry or not definition or not worker or tostring(definition.requirementKey or "") == "" then
        return false
    end

    if config.ItemMatchesEquipmentRequirement then
        return config.ItemMatchesEquipmentRequirement(entry.fullType, definition.requirementKey)
    end

    local matches = config.GetMatchingEquipmentRequirementDefinitionsForWorker
        and config.GetMatchingEquipmentRequirementDefinitionsForWorker(entry.fullType, worker)
        or (config.GetMatchingEquipmentRequirementDefinitions
            and config.GetMatchingEquipmentRequirementDefinitions(entry.fullType, worker.jobType)
            or {})
    for _, match in ipairs(matches) do
        if tostring(match and match.requirementKey or "") == tostring(definition.requirementKey or "") then
            return true
        end
    end
    return false
end

local function formatPickerStatText(entry)
    local weightText = Internal.formatWeightValue and Internal.formatWeightValue(entry.totalWeight or entry.unitWeight or 0) or tostring(entry.totalWeight or entry.unitWeight or 0)
    local durabilityText = Internal.getEquipmentDurabilityText and Internal.getEquipmentDurabilityText(entry) or ""
    if durabilityText ~= "" then
        return durabilityText .. " | W " .. tostring(weightText)
    end
    return "W " .. tostring(weightText)
end

local function buildPlayerCandidate(entry)
    return {
        source = "player",
        sourceLabel = "Player",
        itemID = entry.itemID,
        displayName = entry.displayName,
        fullType = entry.fullType,
        texture = entry.texture or (Internal.getTextureForFullType and Internal.getTextureForFullType(entry.fullType) or nil),
        statText = formatPickerStatText(entry),
        tags = entry.tags or {},
        condition = entry.condition,
        conditionMax = entry.conditionMax,
        isDrainable = entry.isDrainable == true,
        useDelta = entry.useDelta,
        usedDelta = entry.usedDelta,
        keepOnDeplete = entry.keepOnDeplete == true,
        unitWeight = entry.unitWeight,
        totalWeight = entry.totalWeight,
    }
end

local function buildWarehouseCandidate(entry)
    return {
        source = "warehouse",
        sourceLabel = "Warehouse",
        ledgerIndex = entry.ledgerIndex,
        displayName = entry.displayName,
        fullType = entry.fullType,
        texture = entry.texture or (Internal.getTextureForFullType and Internal.getTextureForFullType(entry.fullType) or nil),
        statText = formatPickerStatText(entry),
        tags = entry.tags or {},
        qty = entry.qty,
        condition = entry.condition,
        conditionMax = entry.conditionMax,
        isDrainable = entry.isDrainable == true,
        useDelta = entry.useDelta,
        usedDelta = entry.usedDelta,
        keepOnDeplete = entry.keepOnDeplete == true,
        unitWeight = entry.unitWeight,
        totalWeight = entry.totalWeight,
    }
end

local function compareCandidates(a, b)
    local sourceA = tostring(a and a.source or "")
    local sourceB = tostring(b and b.source or "")
    if sourceA ~= sourceB then
        return sourceA < sourceB
    end
    return tostring(a and a.displayName or a and a.fullType or "") < tostring(b and b.displayName or b and b.fullType or "")
end

function DC_SupplyWindow:getEquipmentPickerCandidates(definition)
    local options = {}
    local worker = self.workerData
    local warehouse = worker and worker.warehouse or nil
    local warehouseEquipment = warehouse and warehouse.ledgers and warehouse.ledgers.equipment or {}

    for _, entry in ipairs(self.playerEntries or {}) do
        if entry and entry.kind == "player" then
            Internal.ensurePlayerEntryEquipmentData(entry)
            if entry.canAssignTool == true and entry.isLocked ~= true and getRequirementMatch(entry, definition, worker) then
                options[#options + 1] = buildPlayerCandidate(entry)
            end
        end
    end

    for index, ledgerEntry in ipairs(warehouseEquipment or {}) do
        local entry = Internal.buildWorkerToolEntry(ledgerEntry, index)
        if entry and entry.isUsableEquipment == true and getRequirementMatch(entry, definition, worker) then
            options[#options + 1] = buildWarehouseCandidate(entry)
        end
    end

    table.sort(options, compareCandidates)
    return options
end

function DC_SupplyWindow:onEquipmentPickerConfirmed(option, definition)
    if not option or not definition or not self.workerID then
        return
    end

    local requirementKey = tostring(definition.requirementKey or "")
    local label = tostring(definition.label or "equipment")

    if option.source == "warehouse" then
        if self:sendColonyCommand("AssignWarehouseToolToWorker", {
                workerID = self.workerID,
                ledgerIndex = option.ledgerIndex,
                requirementKey = requirementKey
            }) then
            self:applyOptimisticWarehouseToolAssign(option, requirementKey)
            self:updateStatus("Assigning " .. tostring(option.displayName or option.fullType or label) .. " from warehouse...")
        end
        return
    end

    if self:sendColonyCommand("AssignWorkerToolset", {
            workerID = self.workerID,
            itemID = option.itemID,
            requirementKey = requirementKey
        }) then
        self:applyOptimisticToolAssign({ option }, requirementKey)
        self:updateStatus("Assigning " .. tostring(option.displayName or option.fullType or label) .. "...")
    end
end

function DC_SupplyWindow:openEquipmentPickerForEntry(entry)
    local worker = self.workerData
    local config = Internal.Config or {}
    local warehouseLoaded = worker and worker.warehouse and worker.warehouse.ledgers and type(worker.warehouse.ledgers.equipment) == "table"

    if not entry
        or (self.activeTab or Internal.Tabs.Provisions) ~= Internal.Tabs.Equipment
        or not (Internal.isInventoryView and Internal.isInventoryView(self)) then
        return false
    end

    local definition = getRequirementDefinitionForEntry(entry, worker)
    if not definition then
        return false
    end

    if config.IsEquipmentRequirementAvailableForWorker
        and not config.IsEquipmentRequirementAvailableForWorker(definition, worker) then
        self:updateStatus(tostring(self.workerName or "This worker") .. " cannot use that combat slot.")
        return true
    end

    if not warehouseLoaded then
        self:sendColonyCommand("RequestWarehouse", {
            knownVersion = self.warehouseVersion,
            includeLedgers = true
        })
    end

    local options = self:getEquipmentPickerCandidates(definition)
    if #options <= 0 then
        if not warehouseLoaded then
            self:updateStatus("Fetching warehouse equipment for " .. tostring(definition.label or "equipment") .. ". Try that slot again in a moment.")
            return true
        end
        self:updateStatus("No unlocked " .. tostring(definition.label or "equipment") .. " is available in your inventory or warehouse.")
        return true
    end

    DC_EquipmentPickerModal.Open({
        title = "Choose " .. tostring(definition.label or "Equipment"),
        promptText = "Choose a " .. string.lower(tostring(definition.label or "piece of equipment")) .. " for " .. tostring(self.workerName or self.workerID or "this companion") .. ".",
        confirmLabel = "Equip",
        options = options,
        onConfirm = function(option)
            self:onEquipmentPickerConfirmed(option, definition)
        end
    })
    return true
end

return DC_SupplyWindow

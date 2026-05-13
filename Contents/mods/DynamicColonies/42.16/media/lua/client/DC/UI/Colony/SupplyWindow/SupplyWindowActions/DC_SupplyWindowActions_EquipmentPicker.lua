DC_SupplyWindow = DC_SupplyWindow or {}
DC_SupplyWindow.Internal = DC_SupplyWindow.Internal or {}

require "DC/UI/Colony/EquipmentPickerModal/EquipmentPickerModal"

local Internal = DC_SupplyWindow.Internal

local function getRequirementDefinition(requirementKey)
    local config = Internal.Config or {}
    return config.GetEquipmentRequirementDefinition and config.GetEquipmentRequirementDefinition(requirementKey) or nil
end

local function getRequirementLabel(requirementKey)
    local definition = getRequirementDefinition(requirementKey)
    return tostring(definition and definition.label or requirementKey or "Equipment")
end

function DC_SupplyWindow:assignEquipmentPickerCandidate(candidate, requirementKey)
    if not candidate or not self.workerID then
        return
    end

    local label = getRequirementLabel(requirementKey)
    if candidate.source == "warehouse" then
        if not self:sendColonyCommand("AssignWarehouseToolToWorker", {
                workerID = self.workerID,
                ledgerIndex = candidate.ledgerIndex,
                entryID = candidate.entryID,
                requirementKey = requirementKey
            }) then
            self:updateStatus("Unable to move that warehouse item into " .. tostring(self.workerName or "this worker") .. ".")
            return
        end

        self:updateStatus("Equipping " .. tostring(candidate.displayName or candidate.fullType or label) .. " from warehouse storage...")
        return
    end

    local sourceEntry = candidate.sourceEntry
    if not sourceEntry or not sourceEntry.itemID then
        self:updateStatus("That player item is no longer available.")
        return
    end

    sourceEntry.assignedRequirementKey = requirementKey
    if not self:beginSupplyTransfer("equipment", "AssignWorkerToolset", {
            workerID = self.workerID,
            itemIDs = { sourceEntry.itemID },
            requirementKey = requirementKey
        }, { sourceEntry }) then
        self:updateStatus("Unable to equip that player item right now.")
        return
    end

    self:updateStatus("Equipping " .. tostring(sourceEntry.displayName or sourceEntry.fullType or label) .. " from player inventory...")
end

function DC_SupplyWindow:openEquipmentPickerForWorkerEntry(entry)
    if not entry
        or (self.activeTab or Internal.Tabs.Provisions) ~= Internal.Tabs.Equipment
        or not (Internal.isInventoryView and Internal.isInventoryView(self)) then
        return false
    end

    if self.requireCanonicalWorkerDetail == true and not self:canTransferWithWorker(true) then
        return true
    end

    local targetEntry = entry
    if Internal.isGroupEntry and Internal.isGroupEntry(entry) then
        targetEntry = (entry.childEntries and entry.childEntries[1]) or nil
    end

    local requirementKey = entry.kind == "placeholder"
        and tostring(entry.requirementKey or "")
        or tostring(Internal.resolveWorkerEquipmentRequirementKey and Internal.resolveWorkerEquipmentRequirementKey(targetEntry, self.workerData) or "")
    if requirementKey == "" then
        self:updateStatus("That row does not map to an equipment requirement.")
        return true
    end

    local warehouseLedger = self.workerData and self.workerData.warehouse and self.workerData.warehouse.ledgers and self.workerData.warehouse.ledgers.equipment or nil
    if type(warehouseLedger) ~= "table" then
        self:sendColonyCommand("RequestWarehouse", {
            knownVersion = self.warehouseVersion,
            includeLedgers = true
        })
    end

    local candidates = Internal.buildEquipmentPickerCandidates and Internal.buildEquipmentPickerCandidates(self, requirementKey) or {}
    local label = getRequirementLabel(requirementKey)
    DC_EquipmentPickerModal.Open({
        title = "Choose " .. label,
        promptText = "Pick a " .. label .. " from player inventory or warehouse storage.",
        candidates = candidates,
        sourceFilter = "all",
        confirmLabel = "Equip",
        onConfirm = function(candidate)
            self:assignEquipmentPickerCandidate(candidate, requirementKey)
        end
    })

    if #candidates <= 0 then
        self:updateStatus("No matching " .. string.lower(label) .. " is available in player inventory or warehouse storage.")
    else
        self:updateStatus("Choose a " .. string.lower(label) .. " to equip.")
    end

    return true
end

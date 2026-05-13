DC_Colony = DC_Colony or {}
DC_Colony.Network = DC_Colony.Network or {}
DC_Colony.Network.Workers = DC_Colony.Network.Workers or {}

local Config = DC_Colony.Config
local Registry = DC_Colony.Registry
local Warehouse = DC_Colony.Warehouse
local Network = DC_Colony.Network
local Equipment = (Network.Workers or {}).Equipment or {}

function Equipment.getRequirementLabel(requirementKey)
    local definition = Config.GetEquipmentRequirementDefinition and Config.GetEquipmentRequirementDefinition(requirementKey) or nil
    return tostring(definition and definition.label or requirementKey or Equipment.FlavorText.selectedRequirement or "the selected requirement")
end

function Equipment.formatWeight(value)
    return string.format("%.2f", math.max(0, tonumber(value) or 0))
end

function Equipment.getEquipmentEntryWeight(entry)
    local fullType = entry and entry.fullType
    if not fullType then
        return 0
    end
    local qty = math.max(1, tonumber(entry and entry.qty) or 1)
    return math.max(0, tonumber(Config.GetItemWeight and Config.GetItemWeight(fullType)) or 0) * qty
end

function Equipment.getRequirementEntry(worker, requirementKey)
    local targetKey = tostring(requirementKey or "")
    if targetKey == "" then
        return nil
    end

    for _, entry in ipairs(worker and worker.toolLedger or {}) do
        if tostring(entry and entry.assignedRequirementKey or "") == targetKey then
            return entry
        end
    end

    for _, entry in ipairs(worker and worker.toolLedger or {}) do
        if Config.ItemMatchesWorkerEquipmentRequirement
            and Config.ItemMatchesWorkerEquipmentRequirement(entry and entry.fullType, targetKey, worker) then
            return entry
        end
    end

    return nil
end

function Equipment.buildWorkerCapacityDetail(worker, toolEntry, requirementKey)
    local itemWeight = Equipment.getEquipmentEntryWeight(toolEntry)
    local state = Registry.GetInventoryWeightState and Registry.GetInventoryWeightState(worker) or nil
    local remaining = math.max(0, tonumber(state and state.remainingWeight) or 0)
    local replacingEntry = Equipment.getRequirementEntry(worker, requirementKey)
    local replacingWeight = Equipment.getEquipmentEntryWeight(replacingEntry)
    local adjustedRemaining = replacingEntry and (remaining + replacingWeight) or remaining
    if itemWeight <= 0 then
        return nil
    end

    return string.format(
        tostring(Equipment.FlavorText.workerCapacityDetail or "NPC inventory does not have enough carry capacity (item weight %s, remaining %s)"),
        Equipment.formatWeight(itemWeight),
        Equipment.formatWeight(adjustedRemaining)
    )
end

function Equipment.buildWarehouseCapacityDetail(owner, toolEntry)
    local warehouse = Warehouse.GetOrCreate and Warehouse.GetOrCreate(owner) or nil
    local remaining = warehouse and Warehouse.GetRemainingCapacity and Warehouse.GetRemainingCapacity(warehouse) or 0
    local itemWeight = Warehouse.Internal and Warehouse.Internal.GetEntryWeight
        and Warehouse.Internal.GetEntryWeight(toolEntry and toolEntry.fullType, math.max(1, tonumber(toolEntry and toolEntry.qty) or 1))
        or Equipment.getEquipmentEntryWeight(toolEntry)
    if itemWeight <= 0 then
        return nil
    end

    return string.format(
        tostring(Equipment.FlavorText.warehouseCapacityDetail or "warehouse storage does not have enough capacity (item weight %s, remaining %s)"),
        Equipment.formatWeight(itemWeight),
        Equipment.formatWeight(remaining)
    )
end

return Equipment
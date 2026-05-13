DC_Colony = DC_Colony or {}
DC_Colony.Network = DC_Colony.Network or {}
DC_Colony.Network.Workers = DC_Colony.Network.Workers or {}

local Network = DC_Colony.Network
local Equipment = (Network.Workers or {}).Equipment or {}

function Equipment.rejectItem(rejected, itemID, reason, fullType, detailText)
    rejected[#rejected + 1] = {
        itemID = itemID,
        reason = tostring(reason or "rejected"),
        fullType = fullType and tostring(fullType) or nil,
        detailText = detailText and tostring(detailText) or nil,
    }
end

function Equipment.countRejectedReasons(rejected)
    local counts = {}
    local examples = {}
    local total = 0
    for _, entry in ipairs(rejected or {}) do
        local reason = tostring(entry and entry.reason or "rejected")
        counts[reason] = (counts[reason] or 0) + 1
        examples[reason] = examples[reason] or entry
        total = total + 1
    end
    return counts, total, examples
end

function Equipment.buildFailureReason(targetLabel, reason, requirementKey, example)
    local detailText = tostring(example and example.detailText or "")
    if detailText ~= "" then
        return detailText
    end

    local label = Equipment.getRequirementLabel(requirementKey)
    local flavor = Equipment.FlavorText or {}
    local warehouseLabel = tostring(flavor.warehouseLabel or "warehouse")

    if reason == "capacity" then
        if tostring(targetLabel or "") == warehouseLabel then
            return tostring(flavor.warehouseCapacityRejected or "warehouse storage is full or the item exceeds remaining warehouse capacity")
        end
        return tostring(flavor.workerCapacityRejected or "NPC inventory is full or the item exceeds remaining carry capacity")
    end
    if reason == "broken" then
        return tostring(flavor.brokenRejected or "the selected equipment is broken or unusable")
    end
    if reason == "not_required_equipment" then
        return string.format(
            tostring(flavor.notRequiredRejected or "the selected item does not match the %s requirement for this worker"),
            label
        )
    end
    if reason == "missing" then
        return tostring(flavor.missingRejected or "the item is no longer in your inventory")
    end
    return tostring(flavor.genericRejected or "the item was rejected")
end

function Equipment.buildEquipmentTransferMessage(targetLabel, movedCount, rejected, requirementKey)
    local reasonCounts, rejectedCount, reasonExamples = Equipment.countRejectedReasons(rejected)
    local flavor = Equipment.FlavorText or {}
    local targetText = tostring(targetLabel or "")
    local warehouseLabel = tostring(flavor.warehouseLabel or "warehouse")
    local isWarehouse = targetText == warehouseLabel
    local movedVerb = tostring(isWarehouse and (flavor.storedVerb or "Stored") or (flavor.assignedVerb or "Assigned"))
    local targetPhrase = isWarehouse and (" in " .. warehouseLabel) or (" to " .. targetText)
    local nonePrefix = tostring(isWarehouse and (flavor.noEquipmentStored or "No equipment stored") or (flavor.noEquipmentAssigned or "No equipment assigned"))
    local rejectedReasonText = nil

    if rejectedCount > 0 then
        local primaryReason = nil
        for reason, count in pairs(reasonCounts) do
            if count == rejectedCount then
                primaryReason = reason
                break
            end
        end

        if primaryReason then
            rejectedReasonText = Equipment.buildFailureReason(targetLabel, primaryReason, requirementKey, reasonExamples[primaryReason])
        else
            local parts = {}
            for reason, count in pairs(reasonCounts) do
                parts[#parts + 1] = tostring(count) .. " " .. Equipment.buildFailureReason(targetLabel, reason, requirementKey, reasonExamples[reason])
            end
            table.sort(parts)
            rejectedReasonText = table.concat(parts, "; ")
        end
    end

    if movedCount > 0 and rejectedCount > 0 then
        return movedVerb .. " " .. tostring(movedCount) .. " equipment item" .. (movedCount == 1 and "" or "s")
            .. targetPhrase .. "; " .. tostring(rejectedCount) .. " failed: " .. rejectedReasonText .. "."
    end
    if movedCount > 0 then
        return movedVerb .. " " .. tostring(movedCount) .. " equipment item" .. (movedCount == 1 and "" or "s")
            .. targetPhrase .. "."
    end
    if rejectedCount <= 0 then
        return tostring(flavor.noEquipmentSelected or "No equipment was selected.")
    end

    return nonePrefix .. ": " .. rejectedReasonText .. "."
end

return Equipment
local Config = DT_Labour.Config
local Registry = DT_Labour.Registry
local Presentation = DT_Labour.Presentation
local Warehouse = DT_Labour.Warehouse
local Internal = DT_Labour.Sim.Internal

Internal.clampHours = function(value)
    return math.max(0, tonumber(value) or 0)
end

Internal.hasWarehouseCapacityForScavenge = function(worker)
    if not worker or not Warehouse or not Warehouse.GetRemainingCapacity or not Warehouse.GetWorkerWarehouse then
        return true
    end

    local warehouse = Warehouse.GetWorkerWarehouse(worker)
    return math.max(0, tonumber(Warehouse.GetRemainingCapacity(warehouse)) or 0) > 0
end

Internal.isAutoRepeatEnabled = function(worker)
    return worker and (worker.autoRepeatJob == true or worker.autoRepeatScavenge == true)
end

Internal.clampCheckpoint = function(value, fallback)
    local safeValue = math.floor(tonumber(value) or tonumber(fallback) or 0)
    return math.max(0, safeValue)
end

Internal.clampHp = function(value, maxHp)
    local safeMax = math.max(1, tonumber(maxHp) or Config.DEFAULT_WORKER_MAX_HP or 100)
    return math.max(0, math.min(safeMax, tonumber(value) or safeMax))
end

Internal.freezeWorkerForOfflineOwner = function(worker, currentHour)
    if not worker then
        return false
    end

    if not Config.IsOwnerOnline or Config.IsOwnerOnline(worker.ownerUsername) then
        return false
    end

    worker.lastSimHour = tonumber(currentHour) or tonumber(worker.lastSimHour) or 0
    worker.lastNutritionCheckpoint = Config.GetMealCheckpointCountAtHour(worker.lastSimHour)
    if Presentation and Presentation.RemoveProjection then
        Presentation.RemoveProjection(worker)
    end
    return true
end

Internal.appendWorkerLog = function(worker, message, worldHour, category)
    local registryInternal = DT_Labour and DT_Labour.Registry and DT_Labour.Registry.Internal or nil
    if registryInternal and registryInternal.AppendActivityLog then
        registryInternal.AppendActivityLog(worker, message, worldHour, category)
    end
end

Internal.getOutputDisplayName = function(fullType)
    local registryInternal = DT_Labour and DT_Labour.Registry and DT_Labour.Registry.Internal or nil
    if registryInternal and registryInternal.GetDisplayNameForFullType then
        return registryInternal.GetDisplayNameForFullType(fullType)
    end
    return tostring(fullType or "Unknown Item")
end

Internal.formatNaturalList = function(values)
    local count = #(values or {})
    if count <= 0 then
        return ""
    end
    if count == 1 then
        return tostring(values[1])
    end
    if count == 2 then
        return tostring(values[1]) .. " and " .. tostring(values[2])
    end
    return tostring(values[1]) .. ", " .. tostring(values[2]) .. ", and " .. tostring(count - 2) .. " more"
end

Internal.buildFoundItemsClause = function(entries)
    local names = {}
    local hiddenCount = 0

    for _, entry in ipairs(entries or {}) do
        if entry and entry.fullType then
            local qty = math.max(1, tonumber(entry.qty) or 1)
            local itemName = Internal.getOutputDisplayName(entry.fullType)
            local displayName = qty > 1 and (itemName .. " x" .. tostring(qty)) or itemName
            if #names < 2 then
                names[#names + 1] = displayName
            else
                hiddenCount = hiddenCount + 1
            end
        end
    end

    if #names <= 0 then
        return ""
    end

    local text = Internal.formatNaturalList(names)
    if hiddenCount > 0 then
        if #names == 1 then
            text = text .. " and " .. tostring(hiddenCount) .. " more"
        else
            text = text .. ", and " .. tostring(hiddenCount) .. " more"
        end
    end

    return text
end

Internal.buildWarehouseProvisionClause = function(sampleNames, hiddenCount)
    local text = Internal.formatNaturalList(sampleNames or {})
    local extras = math.max(0, tonumber(hiddenCount) or 0)
    if extras > 0 then
        if text ~= "" then
            text = text .. ", and " .. tostring(extras) .. " more"
        else
            text = tostring(extras) .. " more"
        end
    end
    return text
end

DT_Labour = DT_Labour or {}
DT_Labour.Config = DT_Labour.Config or {}

local Config = DT_Labour.Config

function Config.GetItemWeight(fullType)
    if not fullType or not getScriptManager then
        return 0
    end

    local item = getScriptManager():getItem(fullType)
    if not item then
        return 0
    end

    local actualWeight = item.getActualWeight and tonumber(item:getActualWeight()) or nil
    if actualWeight and actualWeight > 0 then
        return actualWeight
    end

    local weight = item.getWeight and tonumber(item:getWeight()) or nil
    if weight and weight > 0 then
        return weight
    end

    return 0
end

function Config.GetCarryContainerProfile(fullType)
    if not fullType or fullType == "" then
        return nil
    end

    local tags = Config.FindItemTags(fullType)
    if not Config.HasMatchingTag(tags, "Container") then
        return nil
    end

    local capacity = 0
    local weightReduction = 0
    local item = getScriptManager and getScriptManager():getItem(fullType) or nil

    if item then
        if item.getCapacity then
            capacity = math.max(capacity, tonumber(item:getCapacity()) or 0)
        end
        if item.getWeightReduction then
            local rawReduction = tonumber(item:getWeightReduction()) or 0
            if rawReduction > 1 then
                rawReduction = rawReduction / 100
            end
            weightReduction = math.max(weightReduction, rawReduction)
        end
    end

    for sizeTag, fallbackCapacity in pairs(Config.CONTAINER_CAPACITY_BY_TAG or {}) do
        if Config.HasMatchingTag(tags, "Container.Capacity." .. sizeTag) then
            capacity = math.max(capacity, fallbackCapacity)
        end
    end

    for sizeTag, fallbackReduction in pairs(Config.CONTAINER_WEIGHT_REDUCTION_BY_TAG or {}) do
        if Config.HasMatchingTag(tags, "Container.WeightReduction." .. sizeTag) then
            weightReduction = math.max(weightReduction, fallbackReduction)
        end
    end

    if capacity <= 0 or weightReduction <= 0 then
        return nil
    end

    return {
        fullType = fullType,
        displayName = (getScriptManager and getScriptManager():getItem(fullType) and getScriptManager():getItem(fullType):getDisplayName()) or tostring(fullType),
        capacity = capacity,
        weightReduction = math.max(0, math.min(1, weightReduction))
    }
end

function Config.CalculateEffectiveCarryWeight(rawWeight, carryProfile)
    local remainingWeight = math.max(0, tonumber(rawWeight) or 0)
    local effectiveWeight = 0

    for _, container in ipairs(carryProfile and carryProfile.containers or {}) do
        if remainingWeight <= 0 then
            break
        end

        local usableWeight = math.min(remainingWeight, math.max(0, tonumber(container.capacity) or 0))
        local reduction = math.max(0, math.min(1, tonumber(container.weightReduction) or 0))
        effectiveWeight = effectiveWeight + (usableWeight * (1 - reduction))
        remainingWeight = remainingWeight - usableWeight
    end

    effectiveWeight = effectiveWeight + remainingWeight
    return math.max(0, effectiveWeight)
end

function Config.GetScavengeCarryProfile(worker)
    local containers = {}
    for _, entry in ipairs(worker and worker.toolLedger or {}) do
        local fullType = entry and entry.fullType or nil
        local container = Config.GetCarryContainerProfile(fullType)
        if container then
            containers[#containers + 1] = container
        end
    end

    table.sort(containers, function(a, b)
        local reductionA = tonumber(a and a.weightReduction) or 0
        local reductionB = tonumber(b and b.weightReduction) or 0
        if reductionA == reductionB then
            return (tonumber(a and a.capacity) or 0) > (tonumber(b and b.capacity) or 0)
        end
        return reductionA > reductionB
    end)

    local bodyCapacity = Config.GetWorkerBaseCarryWeight and Config.GetWorkerBaseCarryWeight(worker)
        or (Config.GetDefaultWorkerCarryWeight and Config.GetDefaultWorkerCarryWeight())
        or math.max(0, tonumber(Config.DEFAULT_WORKER_CARRY_WEIGHT) or 8)
    local rawAllowance = bodyCapacity
    for _, container in ipairs(containers) do
        rawAllowance = rawAllowance + ((tonumber(container.capacity) or 0) * (tonumber(container.weightReduction) or 0))
    end

    return {
        bodyCapacity = bodyCapacity,
        effectiveCarryLimit = bodyCapacity,
        maxCarryWeight = rawAllowance,
        rawAllowance = rawAllowance,
        containers = containers
    }
end

return Config

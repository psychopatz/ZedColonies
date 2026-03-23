DT_Labour = DT_Labour or {}
DT_Labour.Registry = DT_Labour.Registry or {}
DT_Labour.Registry.Internal = DT_Labour.Registry.Internal or {}

local Registry = DT_Labour.Registry
local Internal = Registry.Internal
local Nutrition = DT_Labour.Nutrition
local Config = DT_Labour.Config

local function mergeOutputLikeEntry(targetLedger, entry)
    if not targetLedger or not entry or not entry.fullType then
        return false
    end

    local qtyDelta = math.max(1, tonumber(entry.qty) or 1)
    for _, existing in ipairs(targetLedger) do
        if existing.fullType == entry.fullType then
            existing.qty = (existing.qty or 0) + qtyDelta
            return true
        end
    end

    targetLedger[#targetLedger + 1] = {
        fullType = entry.fullType,
        qty = qtyDelta
    }
    return true
end

function Registry.AddNutritionEntry(worker, entry)
    if not worker or not entry then return end
    worker.nutritionLedger = worker.nutritionLedger or {}
    local calories = 0
    local hydration = 0
    if Nutrition and Nutrition.SanitizeLedgerEntry then
        calories, hydration = Nutrition.SanitizeLedgerEntry(entry)
    end
    worker.nutritionLedger[#worker.nutritionLedger + 1] = entry
    if not Internal.ApplyNutritionCacheDelta(worker, calories, hydration) then
        Internal.MarkNutritionCacheDirty(worker)
    end
end

function Registry.AddToolEntry(worker, entry)
    if not worker or not entry then return end
    worker.toolLedger = worker.toolLedger or {}
    worker.toolLedger[#worker.toolLedger + 1] = entry
    if not Internal.ApplyToolTags(worker, entry.tags or {}) then
        Internal.MarkToolCacheDirty(worker)
    end
end

function Registry.AddOutputEntry(worker, entry)
    if not worker or not entry or not entry.fullType then return end
    worker.outputLedger = worker.outputLedger or {}
    if mergeOutputLikeEntry(worker.outputLedger, entry) then
        Internal.MarkOutputCacheDirty(worker)
    end
end

function Registry.AddHaulEntry(worker, entry)
    if not worker or not entry or not entry.fullType then return end
    worker.haulLedger = worker.haulLedger or {}
    mergeOutputLikeEntry(worker.haulLedger, entry)
end

function Registry.GetHaulMetrics(worker)
    local rawWeight = 0
    local count = 0
    for _, entry in ipairs(worker and worker.haulLedger or {}) do
        local qty = math.max(1, tonumber(entry.qty) or 1)
        count = count + qty
        rawWeight = rawWeight + (Config.GetItemWeight(entry.fullType) * qty)
    end

    local carryProfile = Config.GetScavengeCarryProfile and Config.GetScavengeCarryProfile(worker) or nil
    local effectiveWeight = Config.CalculateEffectiveCarryWeight and Config.CalculateEffectiveCarryWeight(rawWeight, carryProfile) or rawWeight
    return {
        count = count,
        rawWeight = rawWeight,
        effectiveWeight = effectiveWeight,
        effectiveCarryLimit = carryProfile and carryProfile.effectiveCarryLimit
            or (Config.GetWorkerBaseCarryWeight and Config.GetWorkerBaseCarryWeight(worker))
            or (Config.GetDefaultWorkerCarryWeight and Config.GetDefaultWorkerCarryWeight())
            or (tonumber(Config.DEFAULT_WORKER_CARRY_WEIGHT) or 8),
        maxCarryWeight = carryProfile and carryProfile.maxCarryWeight
            or (Config.GetWorkerBaseCarryWeight and Config.GetWorkerBaseCarryWeight(worker))
            or (Config.GetDefaultWorkerCarryWeight and Config.GetDefaultWorkerCarryWeight())
            or (tonumber(Config.DEFAULT_WORKER_CARRY_WEIGHT) or 8)
    }
end

function Registry.DumpCarriedHaul(worker)
    if not worker then
        return 0, 0, 0
    end

    local metrics = Registry.GetHaulMetrics(worker)
    local haulEntries = worker.haulLedger or {}
    local movedStacks = 0
    for _, entry in ipairs(haulEntries) do
        Registry.AddOutputEntry(worker, entry)
        movedStacks = movedStacks + 1
    end

    worker.haulLedger = {}
    return movedStacks, metrics.count, metrics.rawWeight
end

function Registry.AddMoney(worker, amount)
    if not worker then return end
    worker.moneyStored = math.max(0, math.floor(tonumber(worker.moneyStored) or 0) + math.floor(tonumber(amount) or 0))
end

function Registry.RemoveMoney(worker, amount)
    if not worker then
        return 0
    end

    local available = math.max(0, math.floor(tonumber(worker.moneyStored) or 0))
    local requested = math.max(0, math.floor(tonumber(amount) or 0))
    local removed = math.min(available, requested)
    worker.moneyStored = available - removed
    return removed
end

function Registry.CollectOutput(worker)
    local output = worker and worker.outputLedger or {}
    if not worker then
        return output
    end
    worker.outputLedger = {}
    Internal.ResetOutputCount(worker)
    worker.outputWeight = 0
    return output
end

return Registry

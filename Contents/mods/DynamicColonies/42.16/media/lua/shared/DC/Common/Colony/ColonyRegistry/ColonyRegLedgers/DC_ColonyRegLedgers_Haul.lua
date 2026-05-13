DC_Colony = DC_Colony or {}
DC_Colony.Registry = DC_Colony.Registry or {}
DC_Colony.Registry.Internal = DC_Colony.Registry.Internal or {}

local Registry = DC_Colony.Registry
local Internal = Registry.Internal
local Config = DC_Colony.Config
local Data = Internal.ColonyRegLedgers or {}

function Registry.GetHaulMetrics(worker)
    local rawWeight = 0
    local count = 0
    for _, entry in ipairs(worker and worker.haulLedger or {}) do
        local qty = math.max(1, tonumber(entry.qty) or 1)
        count = count + qty
        rawWeight = rawWeight + (Config.GetItemWeight(entry.fullType) * qty)
    end

    local carryProfile = Config.GetWorkerCarryProfile and Config.GetWorkerCarryProfile(worker)
        or (Config.GetScavengeCarryProfile and Config.GetScavengeCarryProfile(worker))
        or nil
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

    local haulEntries = worker.haulLedger or {}
    local remainingEntries = {}
    local movedStacks = 0
    local movedCount = 0
    local movedWeight = 0
    for _, entry in ipairs(haulEntries) do
        local requestedQty = math.max(1, tonumber(entry and entry.qty) or 1)
        local movedQty = Registry.AddOutputEntry(worker, entry)
        if movedQty > 0 then
            movedStacks = movedStacks + 1
            movedCount = movedCount + movedQty
            movedWeight = movedWeight + Data.getEntryWeight(entry and entry.fullType, movedQty)
        end

        local leftoverQty = requestedQty - movedQty
        if leftoverQty > 0 then
            local leftoverEntry = Internal.NormalizeOutputEntry and Internal.NormalizeOutputEntry(entry) or Internal.CopyShallow(entry)
            leftoverEntry.qty = leftoverQty
            remainingEntries[#remainingEntries + 1] = leftoverEntry
        end
    end

    worker.haulLedger = remainingEntries
    return movedStacks, movedCount, movedWeight
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

return Data
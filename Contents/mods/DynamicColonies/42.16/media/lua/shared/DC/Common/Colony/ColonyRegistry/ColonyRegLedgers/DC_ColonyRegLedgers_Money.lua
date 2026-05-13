DC_Colony = DC_Colony or {}
DC_Colony.Registry = DC_Colony.Registry or {}
DC_Colony.Registry.Internal = DC_Colony.Registry.Internal or {}

local Registry = DC_Colony.Registry
local Internal = Registry.Internal
local Data = Internal.ColonyRegLedgers or {}

function Registry.AddMoney(worker, amount)
    if not worker then
        return
    end
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

return Data
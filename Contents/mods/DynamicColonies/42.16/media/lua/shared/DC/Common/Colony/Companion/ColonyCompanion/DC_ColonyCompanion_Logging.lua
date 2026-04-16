DC_Colony = DC_Colony or {}
DC_Colony.Companion = DC_Colony.Companion or {}

local Internal = DC_Colony.Companion.Internal

function Internal.Debug(message)
    local text = "[DC Companion Debug] " .. tostring(message)
    print(text)
    if DynamicTrading and DynamicTrading.Log then
        DynamicTrading.Log("DTCommons", "Colony", "Companion", tostring(message))
    end
end

function Internal.AppendLog(worker, text, currentHour, category)
    local internal = DC_Colony and DC_Colony.Sim and DC_Colony.Sim.Internal or nil
    if internal and internal.appendWorkerLog then
        internal.appendWorkerLog(worker, text, currentHour or Internal.GetCurrentWorldHours(), category or "travel")
    end
end
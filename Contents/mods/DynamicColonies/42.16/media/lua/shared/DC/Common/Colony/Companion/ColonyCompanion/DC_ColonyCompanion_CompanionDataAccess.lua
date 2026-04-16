DC_Colony = DC_Colony or {}
DC_Colony.Companion = DC_Colony.Companion or {}

local Internal = DC_Colony.Companion.Internal

function Internal.GetCompanionData(worker)
    if type(worker) ~= "table" then
        return nil
    end

    worker.companion = type(worker.companion) == "table" and worker.companion or {}
    return worker.companion
end

function Internal.GetCompanionUUID(worker)
    local companionData = Internal.GetCompanionData(worker)
    local uuid = companionData and tostring(companionData.uuid or "") or ""
    return uuid ~= "" and uuid or nil
end

function Internal.GetCommandVersion(companionData)
    return math.max(0, math.floor(tonumber(companionData and companionData.commandVersion) or 0))
end
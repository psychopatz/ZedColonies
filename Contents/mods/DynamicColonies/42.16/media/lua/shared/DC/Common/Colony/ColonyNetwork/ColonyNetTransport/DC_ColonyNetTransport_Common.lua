DC_Colony = DC_Colony or {}
DC_Colony.Network = DC_Colony.Network or {}
DC_Colony.Network.Internal = DC_Colony.Network.Internal or {}

local Internal = DC_Colony.Network.Internal
local Transport = Internal.Transport or {}

Transport.Config = DC_Colony.Config or {}
Transport.Registry = DC_Colony.Registry or {}
Transport.Buildings = DC_Buildings or {}
Transport.Resources = DC_Colony.Resources or {}

Transport.MAX_DEBUG_PACKET_SIZE = Transport.MAX_DEBUG_PACKET_SIZE or 24000
Transport.Domains = Transport.Domains or {
    ColonyBootstrap = "Bootstrap",
    BuildingStateUpdated = "Building",
    PlotSafetyChanged = "Building",
    WorkerUpdated = "Worker",
    WorkerListUpdated = "Worker",
    WarehouseSummaryUpdated = "Warehouse",
    ResourcesSummaryUpdated = "Resources",
    FactionStatusSummary = "FactionStatus",
    ColonyNotice = "Notice",
}

function Transport.logTransport(level, message)
    if DynamicTrading and DynamicTrading.LogLevel then
        DynamicTrading.LogLevel(string.lower(tostring(level or "info")), "DynamicColonies", "Network", tostring(level or "Info"), tostring(message or ""))
    elseif DynamicTrading and DynamicTrading.Log then
        DynamicTrading.Log("DynamicColonies", "Network", level or "Info", tostring(message or ""))
    end
end

function Transport.isDebugTransportEnabled(player)
    if DynamicTrading
        and DynamicTrading.ShouldLogLevel
        and DynamicTrading.ShouldLogLevel("debug", "DynamicColonies", "Network") then
        return true
    end
    if isDebugEnabled and isDebugEnabled() then
        return true
    end
    if player and player.getAccessLevel then
        local accessLevel = tostring(player:getAccessLevel() or "")
        if accessLevel ~= "" and accessLevel ~= "None" then
            return true
        end
    end
    return false
end

function Transport.copyShallow(source)
    if type(source) ~= "table" then
        return source
    end

    local copy = {}
    for key, value in pairs(source) do
        copy[key] = value
    end
    return copy
end

function Transport.copyArray(source)
    local copy = {}
    for _, value in ipairs(source or {}) do
        if type(value) == "table" then
            copy[#copy + 1] = Transport.copyShallow(value)
        else
            copy[#copy + 1] = value
        end
    end
    return copy
end

function Transport.getOwnerUsername(subject)
    local Config = Transport.Config or {}
    if Config.GetOwnerUsername then
        return Config.GetOwnerUsername(subject)
    end
    if type(subject) == "table" and subject.getUsername then
        return tostring(subject:getUsername() or "local")
    end
    return tostring(subject or "local")
end

Internal.Transport = Transport

return Transport

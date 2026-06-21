DC_Colony = DC_Colony or {}
DC_Colony.Network = DC_Colony.Network or {}
DC_Colony.Network.Internal = DC_Colony.Network.Internal or {}

local Network = DC_Colony.Network
local NetworkInternal = Network.Internal
local ColonyConfig = DC_Colony.Config or {}
local Buildings = DC_Buildings

Network.Handlers = Network.Handlers or {}
NetworkInternal.BuildingMap = NetworkInternal.BuildingMap or {}

local MapTransport = NetworkInternal.BuildingMap
local modules = MapTransport.Modules or {}
local constants = MapTransport.Constants or {}
local helpers = MapTransport.Helpers or {}

MapTransport.Modules = modules
MapTransport.Constants = constants
MapTransport.Helpers = helpers

if modules.Common then
    return
end

modules.Common = true

MapTransport.CHUNK_PLOT_COUNT = MapTransport.CHUNK_PLOT_COUNT or 10
MapTransport.MAX_CHUNK_SIZE = MapTransport.MAX_CHUNK_SIZE or 16000

function helpers.LogMap(level, message)
    if DynamicTrading and DynamicTrading.LogLevel then
        DynamicTrading.LogLevel(string.lower(tostring(level or "info")), "DynamicColonies", "BuildingMap", tostring(level or "Info"), tostring(message or ""))
    elseif DynamicTrading and DynamicTrading.Log then
        DynamicTrading.Log("DynamicColonies", "BuildingMap", level or "Info", tostring(message or ""))
    end
end

function helpers.IsDebugTransportEnabled(player)
    if DynamicTrading
        and DynamicTrading.ShouldLogLevel
        and DynamicTrading.ShouldLogLevel("debug", "DynamicColonies", "BuildingMap") then
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

function helpers.EstimatePayloadSize(value, seen)
    local valueType = type(value)
    if valueType == "nil" then
        return 0
    end
    if valueType == "string" then
        return #value
    end
    if valueType == "number" or valueType == "boolean" then
        return #tostring(value)
    end
    if valueType ~= "table" then
        return #tostring(value)
    end

    seen = seen or {}
    if seen[value] then
        return 0
    end
    seen[value] = true

    local total = 2
    for key, child in pairs(value) do
        total = total + #tostring(key) + helpers.EstimatePayloadSize(child, seen)
    end

    seen[value] = nil
    return total
end

function helpers.ShallowCopy(source)
    if type(source) ~= "table" then
        return source
    end
    local copy = {}
    for key, value in pairs(source) do
        copy[key] = value
    end
    return copy
end

function helpers.CopyArray(source)
    local copy = {}
    for _, value in ipairs(source or {}) do
        if type(value) == "table" then
            copy[#copy + 1] = helpers.ShallowCopy(value)
        else
            copy[#copy + 1] = value
        end
    end
    return copy
end

function helpers.GetOwnerUsername(subject)
    if ColonyConfig.GetOwnerUsername then
        return ColonyConfig.GetOwnerUsername(subject)
    end
    if type(subject) == "table" and subject.getUsername then
        return tostring(subject:getUsername() or "local")
    end
    return tostring(subject or "local")
end

function helpers.GetPlotKey(plotX, plotY)
    if Buildings.GetPlotKey then
        return Buildings.GetPlotKey(plotX, plotY)
    end
    return tostring(math.floor(tonumber(plotX) or 0)) .. ":" .. tostring(math.floor(tonumber(plotY) or 0))
end

function helpers.NormalizeCoord(plotX, plotY)
    return {
        x = math.floor(tonumber(plotX) or 0),
        y = math.floor(tonumber(plotY) or 0),
    }
end

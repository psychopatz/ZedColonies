DC_Colony = DC_Colony or {}
DC_Colony.Network = DC_Colony.Network or {}
DC_Colony.Network.Internal = DC_Colony.Network.Internal or {}

local Internal = DC_Colony.Network.Internal
local Transport = Internal.Transport or {}
local Config = Transport.Config or {}

Transport.TrustedFastPathCommands = Transport.TrustedFastPathCommands or {
    ColonyBootstrap = true,
    BuildingStateUpdated = true,
    PlotSafetyChanged = true,
    WorkerUpdated = true,
    WorkerListUpdated = true,
    WarehouseSummaryUpdated = true,
    ResourcesSummaryUpdated = true,
    FactionStatusSummary = true,
    ColonyNotice = true,
}

function Transport.sanitizeKey(key)
    local keyType = type(key)
    if keyType == "string" or keyType == "number" then
        return key
    end
    if keyType == "boolean" then
        return tostring(key)
    end
    return nil
end

function Transport.isFlatSerializableArray(value)
    if type(value) ~= "table" then
        return false
    end

    local count = 0
    for index, child in ipairs(value) do
        count = index
        local childType = type(child)
        if childType == "table" then
            for nestedKey, nestedValue in pairs(child) do
                local nestedKeyType = type(nestedKey)
                local nestedValueType = type(nestedValue)
                if not (nestedKeyType == "string" or nestedKeyType == "number") then
                    return false
                end
                if nestedValueType == "table" then
                    return false
                end
            end
        elseif childType ~= "string" and childType ~= "number" and childType ~= "boolean" then
            return false
        end
    end

    if count <= 0 then
        return false
    end

    for key, _value in pairs(value) do
        if type(key) ~= "number" or key < 1 or key > count or math.floor(key) ~= key then
            return false
        end
    end

    return true
end

local function sanitizeFlatArray(value, stats, path)
    local copy = {}
    for index, child in ipairs(value or {}) do
        if type(child) == "table" then
            local childCopy = {}
            for key, nestedValue in pairs(child) do
                local safeKey = Transport.sanitizeKey(key)
                local nestedType = type(nestedValue)
                if safeKey ~= nil and nestedType ~= "table" and nestedType ~= "function" and nestedType ~= "thread" then
                    if nestedType == "number" and nestedValue ~= nestedValue then
                        childCopy[safeKey] = 0
                    elseif nestedType == "userdata" then
                        childCopy[safeKey] = tostring(nestedValue)
                    elseif nestedType == "string" or nestedType == "number" or nestedType == "boolean" then
                        childCopy[safeKey] = nestedValue
                    end
                elseif stats then
                    stats.dropped = stats.dropped + 1
                    stats.paths[#stats.paths + 1] = tostring(path or "<root>") .. "[" .. tostring(index) .. "]." .. tostring(key)
                end
            end
            copy[index] = childCopy
        else
            copy[index] = child
        end
    end
    return copy
end

function Transport.sanitizeValue(value, seen, depth, stats, path)
    local valueType = type(value)
    if valueType == "nil" then
        return nil
    end
    if valueType == "string" or valueType == "boolean" then
        return value
    end
    if valueType == "number" then
        if value ~= value then
            if stats then
                stats.dropped = stats.dropped + 1
            end
            return 0
        end
        return value
    end
    if valueType == "userdata" then
        return tostring(value)
    end
    if valueType ~= "table" then
        if stats then
            stats.dropped = stats.dropped + 1
            stats.paths[#stats.paths + 1] = tostring(path or "<root>")
        end
        return nil
    end

    local safeDepth = math.floor(tonumber(depth) or 0)
    if safeDepth > 24 then
        if stats then
            stats.dropped = stats.dropped + 1
            stats.paths[#stats.paths + 1] = tostring(path or "<root>") .. ":depth"
        end
        return nil
    end

    seen = seen or {}
    if seen[value] then
        if stats then
            stats.dropped = stats.dropped + 1
            stats.paths[#stats.paths + 1] = tostring(path or "<root>") .. ":cycle"
        end
        return nil
    end
    seen[value] = true

    if Transport.isFlatSerializableArray(value) then
        local fastCopy = sanitizeFlatArray(value, stats, path)
        seen[value] = nil
        return fastCopy
    end

    local copy = {}
    for key, child in pairs(value) do
        local safeKey = Transport.sanitizeKey(key)
        if safeKey == nil then
            if stats then
                stats.dropped = stats.dropped + 1
                stats.paths[#stats.paths + 1] = tostring(path or "<root>") .. ".<key>"
            end
        else
            local childPath = tostring(path or "<root>") .. "." .. tostring(safeKey)
            local safeChild = Transport.sanitizeValue(child, seen, safeDepth + 1, stats, childPath)
            if safeChild ~= nil then
                copy[safeKey] = safeChild
            end
        end
    end

    seen[value] = nil
    return copy
end

function Transport.estimatePayloadSize(value, seen)
    local valueType = type(value)
    if valueType == "nil" then
        return 0
    end
    if valueType == "number" or valueType == "boolean" then
        return #tostring(value)
    end
    if valueType == "string" then
        return #value
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
        total = total + #tostring(key) + Transport.estimatePayloadSize(child, seen)
    end

    seen[value] = nil
    return total
end

function Internal.sanitizeNetworkArgs(args, options)
    local stats = {
        dropped = 0,
        paths = {},
    }
    local safeArgs = nil
    if options and options.fastPath == true and type(args) == "table" then
        safeArgs = sanitizeFlatArray(args, stats, "root")
        for key, value in pairs(args or {}) do
            if type(key) ~= "number" then
                safeArgs[key] = Transport.sanitizeValue(value, nil, 1, stats, "root." .. tostring(key))
            end
        end
    else
        safeArgs = Transport.sanitizeValue(args or {}, nil, 0, stats, "root")
    end
    if type(safeArgs) ~= "table" then
        safeArgs = {}
    end
    return safeArgs, stats
end

function Internal.sendResponse(player, module, command, args)
    local fastPath = Transport.TrustedFastPathCommands and Transport.TrustedFastPathCommands[command] == true
    local safeArgs = Internal.sanitizeNetworkArgs and select(1, Internal.sanitizeNetworkArgs(args, { fastPath = fastPath })) or (args or {})
    if DynamicTrading and DynamicTrading.ServerHelpers and DynamicTrading.ServerHelpers.SendResponse then
        DynamicTrading.ServerHelpers.SendResponse(player, module, command, safeArgs)
        return
    end

    if isServer() then
        sendServerCommand(player, module, command, safeArgs)
    else
        triggerEvent("OnServerCommand", module, command, safeArgs)
    end
end

function Internal.sendTransportPacket(player, command, ownerUsername, payload)
    local domain = Transport.Domains[command]
    if not domain then
        Transport.logTransport("Warn", "Blocked non-whitelisted colony packet: " .. tostring(command))
        return false
    end

    local args = payload or {}
    args.ownerUsername = args.ownerUsername or ownerUsername
    args.domain = args.domain or domain

    local fastPath = Transport.TrustedFastPathCommands and Transport.TrustedFastPathCommands[command] == true
    local safeArgs, stats = Internal.sanitizeNetworkArgs(args, { fastPath = fastPath })
    local estimatedSize = fastPath and 0 or Transport.estimatePayloadSize(safeArgs)
    local debugEnabled = Transport.isDebugTransportEnabled(player)

    if debugEnabled and not fastPath and estimatedSize > Transport.MAX_DEBUG_PACKET_SIZE then
        Transport.logTransport(
            "Warn",
            "Rejected oversize colony packet command=" .. tostring(command)
                .. " owner=" .. tostring(ownerUsername or "unknown")
                .. " size=" .. tostring(estimatedSize)
        )
        return false
    end

    if debugEnabled then
        Transport.logTransport(
            "Info",
            "send command=" .. tostring(command)
                .. " domain=" .. tostring(domain)
                .. " owner=" .. tostring(ownerUsername or "unknown")
                .. " version=" .. tostring(safeArgs.version or "n/a")
                .. " size=" .. tostring(estimatedSize)
                .. " dropped=" .. tostring(stats and stats.dropped or 0)
        )
    end

    Internal.sendResponse(player, Config.COMMAND_MODULE or "DColony", command, safeArgs)
    return true
end

return Transport

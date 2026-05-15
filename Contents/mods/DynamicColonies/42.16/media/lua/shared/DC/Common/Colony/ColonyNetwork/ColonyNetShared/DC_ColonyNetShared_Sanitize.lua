DC_Colony = DC_Colony or {}
DC_Colony.Network = DC_Colony.Network or {}

local Network = DC_Colony.Network
local Internal = Network.Internal or {}
local Shared = Internal.ColonyNetShared or {}

if not Internal.sanitizeNetworkArgs then
    local trustedCommands = {
        SyncPlayerWorkers = true,
        SyncWorkerDetails = true,
        SyncWarehouse = true,
        SyncResearchSnapshot = true,
        SyncResources = true,
        SyncRecruitAttemptResult = true,
        SyncOwnedFactionStatus = true,
        ColonyNotice = true,
        SupplyTransferResult = true,
    }

    function Shared.sanitizeNetworkKey(key)
        local keyType = type(key)
        if keyType == "string" or keyType == "number" then
            return key
        end
        if keyType == "boolean" then
            return tostring(key)
        end
        return nil
    end

    function Shared.isFlatSerializableArray(value)
        if type(value) ~= "table" then
            return false
        end

        local count = 0
        for index, child in ipairs(value) do
            count = index
            if type(child) == "table" then
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
            elseif type(child) ~= "string" and type(child) ~= "number" and type(child) ~= "boolean" then
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

    function Shared.sanitizeFlatArray(value)
        local copy = {}
        for index, child in ipairs(value or {}) do
            if type(child) == "table" then
                local childCopy = {}
                for key, nestedValue in pairs(child) do
                    local safeKey = Shared.sanitizeNetworkKey(key)
                    local nestedType = type(nestedValue)
                    if safeKey ~= nil and nestedType ~= "table" and nestedType ~= "function" and nestedType ~= "thread" then
                        if nestedType == "number" and nestedValue ~= nestedValue then
                            childCopy[safeKey] = 0
                        elseif nestedType == "userdata" then
                            childCopy[safeKey] = tostring(nestedValue)
                        elseif nestedType == "string" or nestedType == "number" or nestedType == "boolean" then
                            childCopy[safeKey] = nestedValue
                        end
                    end
                end
                copy[index] = childCopy
            else
                copy[index] = child
            end
        end
        return copy
    end

    function Shared.sanitizeNetworkValue(value, seen, depth)
        local valueType = type(value)
        if valueType == "nil" then
            return nil
        end
        if valueType == "string" or valueType == "boolean" then
            return value
        end
        if valueType == "number" then
            if value ~= value then
                return 0
            end
            return value
        end
        if valueType == "userdata" then
            return tostring(value)
        end
        if valueType ~= "table" then
            return nil
        end

        local safeDepth = math.floor(tonumber(depth) or 0)
        if safeDepth > 32 then
            return nil
        end

        seen = seen or {}
        if seen[value] then
            return nil
        end
        seen[value] = true

        if Shared.isFlatSerializableArray(value) then
            local fastCopy = Shared.sanitizeFlatArray(value)
            seen[value] = nil
            return fastCopy
        end

        local copy = {}
        for key, child in pairs(value) do
            local safeKey = Shared.sanitizeNetworkKey(key)
            local safeChild = Shared.sanitizeNetworkValue(child, seen, safeDepth + 1)
            if safeKey ~= nil and safeChild ~= nil then
                copy[safeKey] = safeChild
            end
        end

        seen[value] = nil
        return copy
    end

    function Internal.sanitizeNetworkArgs(args, options)
        local safeArgs = nil
        if options and options.fastPath == true and type(args) == "table" then
            safeArgs = {}
            for key, value in pairs(args or {}) do
                local safeKey = Shared.sanitizeNetworkKey(key)
                if safeKey ~= nil then
                    if Shared.isFlatSerializableArray(value) then
                        safeArgs[safeKey] = Shared.sanitizeFlatArray(value)
                    else
                        safeArgs[safeKey] = Shared.sanitizeNetworkValue(value, nil, 1)
                    end
                end
            end
        else
            safeArgs = Shared.sanitizeNetworkValue(args or {}, nil, 0)
        end
        if type(safeArgs) == "table" then
            return safeArgs
        end
        return {}
    end
end

if not Internal.sendResponse then
    function Internal.sendResponse(player, module, command, args)
        local safeArgs = Internal.sanitizeNetworkArgs and Internal.sanitizeNetworkArgs(args, {
            fastPath = trustedCommands[command] == true
        }) or (args or {})
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
end

return Shared

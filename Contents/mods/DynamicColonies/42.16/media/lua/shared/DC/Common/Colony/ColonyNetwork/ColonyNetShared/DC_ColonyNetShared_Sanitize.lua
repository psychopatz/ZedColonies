DC_Colony = DC_Colony or {}
DC_Colony.Network = DC_Colony.Network or {}

local Network = DC_Colony.Network
local Internal = Network.Internal or {}
local Shared = Internal.ColonyNetShared or {}

if not Internal.sanitizeNetworkArgs then
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

    function Internal.sanitizeNetworkArgs(args)
        local safeArgs = Shared.sanitizeNetworkValue(args or {}, nil, 0)
        if type(safeArgs) == "table" then
            return safeArgs
        end
        return {}
    end
end

if not Internal.sendResponse then
    function Internal.sendResponse(player, module, command, args)
        local safeArgs = Internal.sanitizeNetworkArgs and Internal.sanitizeNetworkArgs(args) or (args or {})
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
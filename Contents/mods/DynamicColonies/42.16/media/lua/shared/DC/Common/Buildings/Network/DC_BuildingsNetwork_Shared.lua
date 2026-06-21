require "DC/Common/Buildings/Core/DC_Buildings"
require "DC/Common/Colony/ColonyConfig/DC_ColonyConfig"
require "DC/Common/Colony/ColonyRegistry/DC_ColonyRegistry"

DC_Colony = DC_Colony or {}
DC_Colony.Network = DC_Colony.Network or {}
DC_Colony.Network.Internal = DC_Colony.Network.Internal or {}

local ColonyConfig = DC_Colony.Config
local Network = DC_Colony.Network
local Registry = DC_Colony.Registry
local Buildings = DC_Buildings
local Config = Buildings.Config
local Internal = Network.Internal

Network.Handlers = Network.Handlers or {}

if not Internal.sanitizeNetworkArgs then
    local function sanitizeNetworkKey(key)
        local keyType = type(key)
        if keyType == "string" or keyType == "number" then
            return key
        end
        if keyType == "boolean" then
            return tostring(key)
        end
        return nil
    end

    local function sanitizeNetworkValue(value, seen, depth)
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
            local safeKey = sanitizeNetworkKey(key)
            local safeChild = sanitizeNetworkValue(child, seen, safeDepth + 1)
            if safeKey ~= nil and safeChild ~= nil then
                copy[safeKey] = safeChild
            end
        end

        seen[value] = nil
        return copy
    end

    function Internal.sanitizeNetworkArgs(args)
        local safeArgs = sanitizeNetworkValue(args or {}, nil, 0)
        if type(safeArgs) == "table" then
            return safeArgs
        end
        return {}
    end
end

local function buildVersionToken(value, seen)
    local valueType = type(value)
    if valueType ~= "table" then
        return tostring(valueType) .. ":" .. tostring(value)
    end

    seen = seen or {}
    if seen[value] then
        return "<cycle>"
    end
    seen[value] = true

    local keys = {}
    for key, _ in pairs(value) do
        keys[#keys + 1] = key
    end
    table.sort(keys, function(a, b)
        return tostring(a) < tostring(b)
    end)

    local parts = { "{" }
    for _, key in ipairs(keys) do
        parts[#parts + 1] = tostring(key)
        parts[#parts + 1] = "="
        parts[#parts + 1] = buildVersionToken(value[key], seen)
        parts[#parts + 1] = ";"
    end
    parts[#parts + 1] = "}"
    seen[value] = nil
    return table.concat(parts)
end

function Internal.canUseDebug(player)
    if isDebugEnabled and isDebugEnabled() then
        return true
    end

    if player and player.getAccessLevel then
        local accessLevel = player:getAccessLevel()
        if accessLevel and accessLevel ~= "" and accessLevel ~= "None" then
            return true
        end
    end

    return false
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

function Internal.syncBuildingsSnapshot(player, ownerUsername, knownVersion)
    local owner = ColonyConfig.GetOwnerUsername(ownerUsername or player)
    if Buildings.EnsureInitialHeadquartersProject then
        Buildings.EnsureInitialHeadquartersProject(owner)
    end
    local snapshot = Buildings.BuildOwnerSnapshot(owner, player)
    local version = buildVersionToken(snapshot or {})
    if knownVersion and tostring(knownVersion) == version then
        Internal.sendResponse(player, ColonyConfig.COMMAND_MODULE, "SyncBuildingsSnapshot", {
            version = version,
            unchanged = true
        })
        return
    end
    Internal.sendResponse(player, ColonyConfig.COMMAND_MODULE, "SyncBuildingsSnapshot", {
        version = version,
        snapshot = snapshot
    })
end

function Internal.syncProjectPreview(player, ownerUsername, buildingType, mode, plotX, plotY, buildingID, installKey)
    local owner = ColonyConfig.GetOwnerUsername(ownerUsername or player)
    Internal.sendResponse(player, ColonyConfig.COMMAND_MODULE, "SyncBuildingProjectPreview", {
        preview = Buildings.BuildProjectPreview(owner, buildingType, mode, plotX, plotY, buildingID, installKey, player),
        buildingType = buildingType,
        mode = mode,
        plotX = plotX,
        plotY = plotY,
        buildingID = buildingID,
        installKey = installKey
    })
end

function Internal.syncWorkerList(player)
    local owner = ColonyConfig.GetOwnerUsername(player)
    Internal.sendResponse(player, ColonyConfig.COMMAND_MODULE, "SyncPlayerWorkers", {
        workers = Registry.GetWorkerSummariesForOwner(owner)
    })
end

if not Internal.removeInventoryItem then
    function Internal.removeInventoryItem(item)
        if not item then
            return
        end

        local container = item:getContainer()
        if container then
            container:DoRemoveItem(item)
        end
    end
end

if not Internal.addInventoryItem then
    function Internal.addInventoryItem(container, fullType, count)
        if not container or not fullType then
            return nil
        end

        return container:AddItems(fullType, count or 1)
    end
end

function Internal.getInventoryItemQuantity(item)
    if not item then
        return 0
    end

    local count = item.getCount and item:getCount() or nil
    count = math.floor(tonumber(count) or 0)
    if count > 0 then
        return count
    end

    return 1
end

function Internal.collectInventoryItemsRecursive(container, into)
    if not container or not into then
        return
    end

    local items = container:getItems()
    if not items then
        return
    end

    for index = 0, items:size() - 1 do
        local item = items:get(index)
        if item then
            into[#into + 1] = item
            if instanceof(item, "InventoryContainer") then
                Internal.collectInventoryItemsRecursive(item:getItemContainer(), into)
            end
        end
    end
end

return Network

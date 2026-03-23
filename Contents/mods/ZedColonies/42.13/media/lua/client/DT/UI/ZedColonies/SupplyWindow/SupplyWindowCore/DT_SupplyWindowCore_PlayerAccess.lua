DT_SupplyWindow = DT_SupplyWindow or {}
DT_SupplyWindow.Internal = DT_SupplyWindow.Internal or {}

local Internal = DT_SupplyWindow.Internal

function Internal.getCommandModule()
    local config = Internal.Config
    if type(config) == "table" and config.COMMAND_MODULE and config.COMMAND_MODULE ~= "" then
        return config.COMMAND_MODULE
    end
    return "DynamicTrading_V2"
end

function Internal.getLocalPlayer()
    local config = Internal.Config
    if config.GetPlayerObject then
        return config.GetPlayerObject()
    end
    if getSpecificPlayer then
        return getSpecificPlayer(0)
    end
    return getPlayer and getPlayer() or nil
end

function Internal.getPlayerWealth(player)
    local targetPlayer = player or Internal.getLocalPlayer()
    local inventory = targetPlayer and targetPlayer.getInventory and targetPlayer:getInventory() or nil
    if not inventory then
        return 0
    end

    local loose = inventory:getItemsFromType("Base.Money", true)
    local bundles = inventory:getItemsFromType("Base.MoneyBundle", true)
    local looseCount = loose and loose:size() or 0
    local bundleCount = bundles and bundles:size() or 0
    return looseCount + (bundleCount * 100)
end

function Internal.getWarehouseOwnerUsername(window)
    local worker = window and window.workerData or nil
    local warehouse = worker and worker.warehouse or nil
    local config = Internal.Config or {}

    local ownerUsername = warehouse and warehouse.ownerUsername or worker and worker.ownerUsername or nil
    if ownerUsername and ownerUsername ~= "" then
        return config.GetOwnerUsername and config.GetOwnerUsername(ownerUsername) or tostring(ownerUsername)
    end

    local player = Internal.getLocalPlayer()
    return config.GetOwnerUsername and config.GetOwnerUsername(player) or "local"
end

function Internal.getOwnedFactionStatus()
    if DT_System and DT_System.GetOwnedFactionStatus then
        return DT_System.GetOwnedFactionStatus()
    end

    if DT_MainWindow and DT_MainWindow.cachedOwnedFactionStatus then
        return DT_MainWindow.cachedOwnedFactionStatus
    end

    return nil
end

function Internal.getWarehouseDisplayName(window)
    local ownerUsername = tostring(Internal.getWarehouseOwnerUsername(window) or "local")
    local status = Internal.getOwnedFactionStatus()
    local config = Internal.Config or {}

    if status and status.faction then
        local factionOwner = status.ownerUsername or status.faction.leaderUsername or nil
        local normalizedFactionOwner = config.GetOwnerUsername and config.GetOwnerUsername(factionOwner) or tostring(factionOwner or "")
        if normalizedFactionOwner == ownerUsername then
            local factionName = tostring(status.faction.name or "")
            if factionName ~= "" then
                return factionName
            end
        end
    end

    return ownerUsername .. "'s faction"
end

function Internal.resolveWorkerDetail(workerID)
    if not workerID then
        return nil
    end

    if isClient() and not isServer() then
        local cache = DT_MainWindow and DT_MainWindow.cachedDetails or nil
        return cache and cache[workerID] or nil
    end

    if DT_Labour and DT_Labour.Registry and DT_Labour.Registry.GetWorkerDetailsForOwner then
        local owner = nil
        local player = Internal.getLocalPlayer()
        if Internal.Config and Internal.Config.GetOwnerUsername then
            owner = Internal.Config.GetOwnerUsername(player)
        end
        return DT_Labour.Registry.GetWorkerDetailsForOwner(owner or "local", workerID)
    end

    return nil
end

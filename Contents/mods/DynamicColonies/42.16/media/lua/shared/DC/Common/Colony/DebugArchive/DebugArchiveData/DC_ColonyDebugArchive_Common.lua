DC_Colony = DC_Colony or {}
DC_Colony.DebugArchive = DC_Colony.DebugArchive or {}
DC_Colony.DebugArchive.Internal = DC_Colony.DebugArchive.Internal or {}

local DebugArchive = DC_Colony.DebugArchive
local Internal = DebugArchive.Internal

local function copyShallow(source)
    local copied = {}
    for key, value in pairs(source or {}) do
        copied[key] = value
    end
    return copied
end

local function copyArray(source)
    local copied = {}
    for index, value in ipairs(source or {}) do
        copied[index] = value
    end
    return copied
end

local function normalizeOwnerUsername(value)
    local config = DC_Colony and DC_Colony.Config or nil
    if config and config.GetOwnerUsername then
        return config.GetOwnerUsername(value)
    end
    return tostring(value or "")
end

local function canUseDebugPlayer(player)
    local accessLevel = nil
    if player and player.getAccessLevel then
        accessLevel = player:getAccessLevel()
    end

    local hasElevatedAccess = accessLevel and accessLevel ~= "" and accessLevel ~= "None"
    local isSinglePlayer = (not isClient or not isClient()) and not hasElevatedAccess

    if isSinglePlayer then
        return isDebugEnabled and isDebugEnabled() == true
    end

    if isDebugEnabled and isDebugEnabled() then
        return true
    end

    if hasElevatedAccess then
        return true
    end

    return false
end

local function buildVersionToken(value)
    local network = DC_Colony and DC_Colony.Network or nil
    local shared = network and network.Internal and network.Internal.ColonyNetShared or nil
    if shared and shared.buildVersionToken then
        return shared.buildVersionToken(value)
    end
    return tostring(value or "")
end

local function getItemDisplayName(fullType)
    local registry = DC_Colony and DC_Colony.Registry or nil
    local registryInternal = registry and registry.Internal or nil
    if registryInternal and registryInternal.GetDisplayNameForFullType then
        return tostring(registryInternal.GetDisplayNameForFullType(fullType) or fullType or "")
    end
    return tostring(fullType or "")
end

local function getCategoryDefinition(categoryId)
    local config = DC_Colony and DC_Colony.Config or nil
    return config and config.GetItemCategoryDefinition and config.GetItemCategoryDefinition(categoryId) or nil
end

local function getCategoryDisplayName(categoryId)
    local definition = getCategoryDefinition(categoryId) or nil
    return tostring(definition and definition.displayName or categoryId or "")
end

Internal.copyShallow = Internal.copyShallow or copyShallow
Internal.copyArray = Internal.copyArray or copyArray
Internal.normalizeOwnerUsername = Internal.normalizeOwnerUsername or normalizeOwnerUsername
Internal.canUseDebugPlayer = Internal.canUseDebugPlayer or canUseDebugPlayer
Internal.buildVersionToken = Internal.buildVersionToken or buildVersionToken
Internal.getItemDisplayName = Internal.getItemDisplayName or getItemDisplayName
Internal.getCategoryDefinition = Internal.getCategoryDefinition or getCategoryDefinition
Internal.getCategoryDisplayName = Internal.getCategoryDisplayName or getCategoryDisplayName

function DebugArchive.CanUseDebug(player)
    return Internal.canUseDebugPlayer(player)
end

return DebugArchive

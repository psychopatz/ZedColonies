DC_Buildings = DC_Buildings or {}
DC_Buildings.RealBase = DC_Buildings.RealBase or {}

local Buildings = DC_Buildings
local RealBase = Buildings.RealBase

local function trimName(value)
    return tostring(value or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

local function normalizeOwner(ownerUsername)
    local config = DC_Colony and DC_Colony.Config or nil
    if config and config.GetOwnerUsername then
        return config.GetOwnerUsername(ownerUsername)
    end
    return tostring(ownerUsername or "local")
end

local function getDefinitionDisplayName(buildingType)
    local definition = Buildings.Config and Buildings.Config.GetDefinition and Buildings.Config.GetDefinition(buildingType) or nil
    return tostring(definition and definition.displayName or buildingType or "Building")
end

function RealBase.ShouldManageNamedInstance(buildingType)
    local normalized = tostring(buildingType or "")
    return normalized ~= "" and normalized ~= "Headquarters" and normalized ~= "Barricade"
end

function RealBase.GetDefaultInstanceName(ownerUsername, buildingType, buildingID)
    local owner = normalizeOwner(ownerUsername)
    local count = 0
    for _, instance in ipairs(Buildings.GetBuildingsForOwner and Buildings.GetBuildingsForOwner(owner) or {}) do
        if tostring(instance and instance.buildingType or "") == tostring(buildingType or "")
            and math.floor(tonumber(instance and instance.level) or 0) > 0 then
            count = count + 1
        end
    end

    if count <= 0 then
        count = 1
    end

    return getDefinitionDisplayName(buildingType) .. " #" .. tostring(count)
end

function RealBase.GetInstanceDisplayName(instance)
    if type(instance) ~= "table" then
        return "Building"
    end

    local customName = trimName(instance.customName)
    if customName ~= "" then
        return customName
    end

    return getDefinitionDisplayName(instance.buildingType)
end

function RealBase.InitializeInstanceName(ownerUsername, instance)
    if not instance or not RealBase.ShouldManageNamedInstance(instance.buildingType) then
        return nil
    end

    local currentName = trimName(instance.customName)
    if currentName == "" then
        currentName = RealBase.GetDefaultInstanceName(ownerUsername, instance.buildingType, instance.buildingID)
        instance.customName = currentName
    end

    return currentName
end

function RealBase.SetInstanceCustomName(ownerUsername, buildingID, requestedName)
    local owner = normalizeOwner(ownerUsername)
    local instance = Buildings.FindBuildingForOwner and Buildings.FindBuildingForOwner(owner, buildingID) or nil
    if not instance then
        return false, "That building could not be found.", nil
    end

    if not RealBase.ShouldManageNamedInstance(instance.buildingType) then
        return false, "That building does not use a custom world-area name.", nil
    end

    local name = trimName(requestedName)
    if name == "" then
        name = RealBase.GetDefaultInstanceName(owner, instance.buildingType, instance.buildingID)
    end
    if #name > 32 then
        return false, "Building names must be 32 characters or less.", nil
    end

    instance.customName = name
    if DC_ZoneRealBase and DC_ZoneRealBase.RefreshBuildingSlotLabel then
        DC_ZoneRealBase.RefreshBuildingSlotLabel(owner, instance.buildingID, name)
    end
    Buildings.Save()
    return true, nil, instance
end

return RealBase

DC_Buildings = DC_Buildings or {}
DC_Buildings.Internal = DC_Buildings.Internal or {}

local Buildings = DC_Buildings
local Internal = Buildings.Internal
local Materials = Internal.ProjectMaterials or {}

Internal.ProjectMaterials = Materials

function Materials.GetColonyConfig()
    return DC_Colony and DC_Colony.Config or {}
end

function Materials.GetRegistry()
    return DC_Colony and DC_Colony.Registry or nil
end

function Materials.GetWarehouse()
    return DC_Colony and DC_Colony.Warehouse or nil
end

function Materials.GetOwnerUsername(playerOrUsername)
    local labourConfig = Materials.GetColonyConfig()
    return labourConfig.GetOwnerUsername and labourConfig.GetOwnerUsername(playerOrUsername) or tostring(playerOrUsername or "local")
end

function Materials.GetDisplayName(fullType)
    local registry = Materials.GetRegistry()
    local internal = registry and registry.Internal or nil
    return internal and internal.GetDisplayNameForFullType and internal.GetDisplayNameForFullType(fullType) or tostring(fullType or "Unknown")
end

return Buildings
DC_Buildings = DC_Buildings or {}
DC_Buildings.Internal = DC_Buildings.Internal or {}

local Buildings = DC_Buildings
local Presentation = Buildings.Internal.Presentation or {}
local modules = Presentation.Modules or {}
local helpers = Presentation.Helpers or {}

Buildings.Internal.Presentation = Presentation
Presentation.Modules = modules
Presentation.Helpers = helpers

if modules.Common then
    return
end

modules.Common = true

function helpers.ShallowCopy(source)
    local copy = {}
    for key, value in pairs(source or {}) do
        copy[key] = value
    end
    return copy
end

function helpers.GetRegistry()
    return DC_Colony and DC_Colony.Registry or nil
end

function helpers.GetDisplayName(fullType)
    local registry = helpers.GetRegistry()
    local internal = registry and registry.Internal or nil
    return internal and internal.GetDisplayNameForFullType and internal.GetDisplayNameForFullType(fullType) or tostring(fullType or "Unknown")
end

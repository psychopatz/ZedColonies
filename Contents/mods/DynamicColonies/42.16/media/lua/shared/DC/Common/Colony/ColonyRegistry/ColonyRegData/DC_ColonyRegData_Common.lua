DC_Colony = DC_Colony or {}
DC_Colony.Registry = DC_Colony.Registry or {}
DC_Colony.Registry.Internal = DC_Colony.Registry.Internal or {}

local Config = DC_Colony.Config
local Registry = DC_Colony.Registry
local Internal = Registry.Internal
local Data = Internal.ColonyRegData or {}

Internal.Runtime = Internal.Runtime or {}
Internal.ColonyRegData = Data

Data.Config = Config
Data.Registry = Registry
Data.Internal = Internal
Data.Runtime = Internal.Runtime

function Data.ensureTable(value)
    return type(value) == "table" and value or {}
end

function Data.clearTable(target)
    for key, _ in pairs(target or {}) do
        target[key] = nil
    end
end

function Data.ensureModDataTable(key, defaults)
    if not ModData.exists(key) then
        ModData.add(key, defaults or {})
    end

    local data = ModData.get(key)
    if type(data) == "table" then
        return data
    end

    if ModData.remove then
        ModData.remove(key)
    end

    ModData.add(key, defaults or {})
    return ModData.get(key)
end

function Data.normalizeID(value, fallback)
    local text = tostring(value or fallback or "")
    if text == "" then
        return tostring(fallback or "0")
    end
    return text
end

function Data.getAuthorityOwner(ownerUsername)
    return Config.GetOwnerUsername(ownerUsername)
end

Internal.EnsureModDataTable = Data.ensureModDataTable

return Data
DC_Buildings = DC_Buildings or {}
DC_Buildings.Internal = DC_Buildings.Internal or {}

local Buildings = DC_Buildings
local Internal = Buildings.Internal

local function copyDeep(value)
    if type(value) ~= "table" then
        return value
    end

    local copy = {}
    for key, entry in pairs(value) do
        copy[key] = copyDeep(entry)
    end
    return copy
end

local function ensureArray(value)
    return type(value) == "table" and value or {}
end

local function clearTable(target)
    for key, _ in pairs(target or {}) do
        target[key] = nil
    end
end

Internal.CopyDeep = copyDeep
Internal.EnsureArray = ensureArray
Internal.ClearTable = clearTable

return Internal
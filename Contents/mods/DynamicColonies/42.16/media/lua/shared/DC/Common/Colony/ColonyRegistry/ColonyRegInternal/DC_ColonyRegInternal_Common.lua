DC_Colony = DC_Colony or {}
DC_Colony.Registry = DC_Colony.Registry or {}
DC_Colony.Registry.Internal = DC_Colony.Registry.Internal or {}

local Config = DC_Colony.Config
local Registry = DC_Colony.Registry
local Internal = Registry.Internal
local Data = Internal.ColonyRegInternal or {}

Internal.ColonyRegInternal = Data

function Internal.EnsureArray(value)
    return type(value) == "table" and value or {}
end

function Internal.CopyShallow(source)
    local copy = {}
    for key, value in pairs(source or {}) do
        copy[key] = value
    end
    return copy
end

function Internal.CopyDeep(source)
    if type(source) ~= "table" then
        return source
    end

    local copy = {}
    for key, value in pairs(source) do
        copy[key] = Internal.CopyDeep(value)
    end
    return copy
end

function Internal.GenerateLedgerEntryID(prefix)
    local randomPart = ZombRand and ZombRand(1000000000) or math.random(1, 1000000000)
    local timePart = (Config.GetCurrentWorldHours and Config.GetCurrentWorldHours()) or Config.GetCurrentHour and Config.GetCurrentHour() or os.time()
    return table.concat({
        tostring(prefix or "ledger"),
        tostring(math.floor((tonumber(timePart) or 0) * 1000)),
        tostring(randomPart)
    }, "-")
end

function Internal.GetDisplayNameForFullType(fullType)
    if not fullType or not getScriptManager then
        return tostring(fullType or "Unknown Item")
    end

    local item = getScriptManager():getItem(fullType)
    if item and item.getDisplayName then
        return item:getDisplayName()
    end

    return tostring(fullType or "Unknown Item")
end

return Data
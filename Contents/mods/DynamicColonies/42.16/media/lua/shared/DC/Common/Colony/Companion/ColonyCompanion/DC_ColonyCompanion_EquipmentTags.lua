DC_Colony = DC_Colony or {}
DC_Colony.Companion = DC_Colony.Companion or {}

local Internal = DC_Colony.Companion.Internal

function Internal.HasTag(entry, targetTag)
    if type(entry) ~= "table" or type(entry.tags) ~= "table" then
        return false
    end

    for _, tag in ipairs(entry.tags) do
        if tag == targetTag or string.find(tostring(tag), "^" .. targetTag .. "%.") then
            return true
        end
    end

    return false
end
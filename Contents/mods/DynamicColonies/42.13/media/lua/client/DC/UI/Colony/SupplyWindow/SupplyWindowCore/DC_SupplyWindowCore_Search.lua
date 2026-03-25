DC_SupplyWindow = DC_SupplyWindow or {}
DC_SupplyWindow.Internal = DC_SupplyWindow.Internal or {}

local Internal = DC_SupplyWindow.Internal

function Internal.formatEntryLabel(entry)
    if not entry then
        return "Unknown Item"
    end

    if Internal.isGroupEntry and Internal.isGroupEntry(entry) then
        local baseName = tostring(entry.displayName or entry.fullType or "Unknown Item")
        return baseName .. " x" .. tostring(math.max(1, tonumber(entry.childCount) or 1))
    end

    return tostring(entry.displayName or entry.fullType or "Unknown Item")
end

function Internal.normalizeFilterText(text)
    local value = string.lower(tostring(text or ""))
    value = string.gsub(value, "^%s+", "")
    value = string.gsub(value, "%s+$", "")
    return value
end

function Internal.matchesFilter(entry, filterText)
    local filter = Internal.normalizeFilterText(filterText)
    if filter == "" then
        return true
    end

    local haystacks = {
        string.lower(tostring(entry.displayName or "")),
        string.lower(tostring(entry.fullType or "")),
        string.lower(tostring(entry.hintText or "")),
        string.lower(tostring(entry.searchText or "")),
    }

    for _, haystack in ipairs(haystacks) do
        if haystack ~= "" and string.find(haystack, filter, 1, true) then
            return true
        end
    end

    return false
end

function Internal.compareEntries(a, b)
    local kindOrder = {
        money = 0,
        tool = 1,
        worker = 1,
        output = 1,
        placeholder = 2,
    }
    local aOrder = kindOrder[tostring(a and a.kind or "")] or 1
    local bOrder = kindOrder[tostring(b and b.kind or "")] or 1
    if aOrder ~= bOrder then
        return aOrder < bOrder
    end

    local aName = string.lower(Internal.formatEntryLabel(a))
    local bName = string.lower(Internal.formatEntryLabel(b))
    if aName == bName then
        return tostring(a.fullType or "") < tostring(b.fullType or "")
    end
    return aName < bName
end

function Internal.getSearchText(box)
    if not box then
        return ""
    end
    if box.getInternalText then
        return box:getInternalText()
    end
    if box.getText then
        return box:getText()
    end
    return ""
end

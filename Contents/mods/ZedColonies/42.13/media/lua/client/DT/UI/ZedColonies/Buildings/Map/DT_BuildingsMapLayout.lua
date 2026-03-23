DT_BuildingsMapLayout = DT_BuildingsMapLayout or {}

function DT_BuildingsMapLayout.Calculate(panelWidth, panelHeight, bounds)
    local width = math.max(1, math.floor(panelWidth or 1))
    local height = math.max(1, math.floor(panelHeight or 1))
    local minX = math.floor(tonumber(bounds and bounds.minX) or -1)
    local maxX = math.floor(tonumber(bounds and bounds.maxX) or 1)
    local minY = math.floor(tonumber(bounds and bounds.minY) or -1)
    local maxY = math.floor(tonumber(bounds and bounds.maxY) or 1)
    local columns = math.max(1, (maxX - minX) + 1)
    local rows = math.max(1, (maxY - minY) + 1)
    local gap = 10
    local availableW = width - ((columns + 1) * gap)
    local availableH = height - ((rows + 1) * gap)
    local cell = math.max(48, math.floor(math.min(availableW / columns, availableH / rows)))
    local contentW = (columns * cell) + ((columns - 1) * gap)
    local contentH = (rows * cell) + ((rows - 1) * gap)
    local offsetX = math.floor((width - contentW) / 2)
    local offsetY = math.floor((height - contentH) / 2)

    return {
        cell = cell,
        gap = gap,
        offsetX = offsetX,
        offsetY = offsetY,
        minX = minX,
        minY = minY
    }
end

return DT_BuildingsMapLayout

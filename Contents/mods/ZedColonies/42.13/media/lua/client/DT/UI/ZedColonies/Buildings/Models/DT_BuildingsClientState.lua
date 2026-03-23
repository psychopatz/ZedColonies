DT_BuildingsClientState = DT_BuildingsClientState or {}

local function sortPlots(plots)
    table.sort(plots, function(a, b)
        if tonumber(a.y) == tonumber(b.y) then
            return tonumber(a.x) < tonumber(b.x)
        end
        return tonumber(a.y) < tonumber(b.y)
    end)
end

function DT_BuildingsClientState.Normalize(snapshot)
    local state = snapshot or {}
    state.map = type(state.map) == "table" and state.map or {}
    state.map.plots = type(state.map.plots) == "table" and state.map.plots or {}
    state.map.bounds = type(state.map.bounds) == "table" and state.map.bounds or {
        minX = -1,
        maxX = 1,
        minY = -1,
        maxY = 1
    }
    sortPlots(state.map.plots)
    return state
end

return DT_BuildingsClientState

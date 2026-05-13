DC_ZoneSelectorState = DC_ZoneSelectorState or {}

local State = DC_ZoneSelectorState

State.STATE_IDLE = State.STATE_IDLE or "idle"
State.STATE_DRAGGING = State.STATE_DRAGGING or "dragging"
State.STATE_PREVIEW = State.STATE_PREVIEW or "preview"
State.STATE_EXPANDING = State.STATE_EXPANDING or "expanding"

function State.GetTitleText(selector)
    if selector and selector.zoneName then
        return "SELECT AREA: " .. tostring(selector.zoneName)
    end
    return "ZONE SELECTOR"
end

function State.GetInstructionText(selector)
    local currentState = tostring(selector and selector.selectorState or State.STATE_IDLE)
    if currentState == State.STATE_IDLE then
        return "Click and drag on the world to select an area"
    end
    if currentState == State.STATE_DRAGGING then
        return "Drag to adjust the selection, then release"
    end
    if currentState == State.STATE_PREVIEW then
        return "Confirm, Reset, or Expand the selection"
    end
    if currentState == State.STATE_EXPANDING then
        return "Click on the world to set the new endpoint"
    end
    return ""
end

function State.GetSelectionBounds(selector)
    if not selector or selector.startingX == nil or selector.endX == nil or selector.startingY == nil or selector.endY == nil then
        return nil
    end

    local x1 = math.min(selector.startingX, selector.endX)
    local x2 = math.max(selector.startingX, selector.endX)
    local y1 = math.min(selector.startingY, selector.endY)
    local y2 = math.max(selector.startingY, selector.endY)

    return x1, y1, x2, y2
end

function State.GetSelectionMetrics(selector)
    local x1, y1, x2, y2 = State.GetSelectionBounds(selector)
    if x1 == nil then
        return nil
    end

    local width = (x2 - x1) + 1
    local height = (y2 - y1) + 1
    return {
        x1 = x1,
        y1 = y1,
        x2 = x2,
        y2 = y2,
        width = width,
        height = height,
        total = width * height
    }
end

function State.GetHighlightColor(selector)
    return {
        r = (selector and selector.highlightColor and selector.highlightColor.r) or 0.2,
        g = (selector and selector.highlightColor and selector.highlightColor.g) or 0.8,
        b = (selector and selector.highlightColor and selector.highlightColor.b) or 0.2,
        a = (selector and selector.highlightColor and selector.highlightColor.a) or 0.5
    }
end

return State
require "DC/UI/Colony/ZoneWindow/ZoneSelector/DC_ZoneSelectorState"

DC_ZoneSelectorInput = DC_ZoneSelectorInput or {}

local Input = DC_ZoneSelectorInput
local State = DC_ZoneSelectorState

function Input.Nudge(selector, dx, dy)
    selector.startingX = (selector.startingX or 0) + dx
    selector.endX = (selector.endX or 0) + dx
    selector.startingY = (selector.startingY or 0) + dy
    selector.endY = (selector.endY or 0) + dy
end

function Input.Scale(selector, edge, amount)
    local x1, y1, x2, y2 = State.GetSelectionBounds(selector)
    if x1 == nil then
        return
    end

    if edge == "W" then
        x1 = x1 - amount
    elseif edge == "E" then
        x2 = x2 + amount
    elseif edge == "N" then
        y1 = y1 - amount
    elseif edge == "S" then
        y2 = y2 + amount
    end

    if x1 > x2 - 1 then x1 = x2 - 1 end
    if y1 > y2 - 1 then y1 = y2 - 1 end

    selector.startingX = x1
    selector.endX = x2
    selector.startingY = y1
    selector.endY = y2
end

function Input.OnCancel(selector)
    ISWorldObjectContextMenu.disableWorldMenu = false
    selector:undisplay()
end

function Input.OnConfirm(selector)
    local x1, y1, x2, y2 = State.GetSelectionBounds(selector)
    if x1 == nil then
        return
    end

    local z = selector.player:getZ()
    if (x2 - x1) < 1 or (y2 - y1) < 1 then
        selector:onReset()
        return
    end

    ISWorldObjectContextMenu.disableWorldMenu = false

    if selector.callback then
        selector.callback(x1, y1, x2, y2, z)
    end

    selector:undisplay()
end

function Input.OnReset(selector)
    selector.startingX = nil
    selector.startingY = nil
    selector.endX = nil
    selector.endY = nil
    selector.startRenderTile = false
    selector.selectorState = State.STATE_IDLE
    selector:setPreviewButtonsVisible(false)
end

function Input.OnExpand(selector)
    selector.selectorState = State.STATE_EXPANDING
    selector:setPreviewButtonsVisible(false)
end

function Input.OnMouseDownOutside(selector, x, y)
    if selector.playerNum ~= 0 then return end
    if selector.selectorState == State.STATE_PREVIEW then return end

    local sq = selector:pickSquare(x + selector:getAbsoluteX(), y + selector:getAbsoluteY())
    if not sq then return end

    if selector.selectorState == State.STATE_IDLE then
        selector.startRenderTile = true
        selector.startingX = sq:getX()
        selector.startingY = sq:getY()
        selector.endX = sq:getX()
        selector.endY = sq:getY()
        selector.selectorState = State.STATE_DRAGGING
        ISWorldObjectContextMenu.disableWorldMenu = true
    elseif selector.selectorState == State.STATE_EXPANDING then
        selector.endX = sq:getX()
        selector.endY = sq:getY()
        selector.selectorState = State.STATE_DRAGGING
    end
end

function Input.OnMouseMoveOutside(selector, dx, dy)
    if selector.playerNum ~= 0 then return end
    if selector.selectorState ~= State.STATE_DRAGGING then return end

    local sq = selector:pickSquare(getMouseX(), getMouseY())
    if sq then
        selector.endX = sq:getX()
        selector.endY = sq:getY()
    end
end

function Input.OnMouseUpOutside(selector, x, y)
    if selector.playerNum ~= 0 then return end
    if selector.selectorState ~= State.STATE_DRAGGING then return end

    selector.selectorState = State.STATE_PREVIEW
    selector:setPreviewButtonsVisible(true)
end

return Input
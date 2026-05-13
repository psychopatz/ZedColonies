require "DC/UI/Colony/ZoneWindow/ZoneSelector/DC_ZoneSelectorState"

DC_ZoneSelectorRender = DC_ZoneSelectorRender or {}

local Render = DC_ZoneSelectorRender
local State = DC_ZoneSelectorState

local FONT = UIFont.Small
local FONT_HGT = getTextManager():getFontHeight(FONT)
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)
local UI_BORDER_SPACING = 10

function Render.SetPreviewButtonsVisible(selector, visible)
    if selector.btnConfirm then selector.btnConfirm:setVisible(visible) end
    if selector.btnReset then selector.btnReset:setVisible(visible) end
    if selector.btnExpand then selector.btnExpand:setVisible(visible) end

    if selector.lblNudge then selector.lblNudge:setVisible(visible) end
    if selector.btnNudgeW then selector.btnNudgeW:setVisible(visible) end
    if selector.btnNudgeE then selector.btnNudgeE:setVisible(visible) end
    if selector.btnNudgeN then selector.btnNudgeN:setVisible(visible) end
    if selector.btnNudgeS then selector.btnNudgeS:setVisible(visible) end

    if selector.lblScale then selector.lblScale:setVisible(visible) end
    if selector.btnScaleW then selector.btnScaleW:setVisible(visible) end
    if selector.btnScaleE then selector.btnScaleE:setVisible(visible) end
    if selector.btnScaleN then selector.btnScaleN:setVisible(visible) end
    if selector.btnScaleS then selector.btnScaleS:setVisible(visible) end
    if selector.btnScaleW_Inner then selector.btnScaleW_Inner:setVisible(visible) end
    if selector.btnScaleE_Inner then selector.btnScaleE_Inner:setVisible(visible) end
    if selector.btnScaleN_Inner then selector.btnScaleN_Inner:setVisible(visible) end
    if selector.btnScaleS_Inner then selector.btnScaleS_Inner:setVisible(visible) end
end

local function drawSelectionInfo(selector, py)
    local metrics = State.GetSelectionMetrics(selector)
    if not metrics then
        return py
    end

    local px = UI_BORDER_SPACING + 1
    selector:drawText("Width: " .. tostring(metrics.width), px, py, 1, 1, 1, 1, UIFont.NewSmall)
    py = py + getTextManager():getFontHeight(UIFont.NewSmall)
    selector:drawText("Height: " .. tostring(metrics.height), px, py, 1, 1, 1, 1, UIFont.NewSmall)
    py = py + getTextManager():getFontHeight(UIFont.NewSmall)
    selector:drawText("Total: " .. tostring(metrics.total) .. " tiles", px, py, 1, 1, 1, 1, UIFont.NewSmall)
    py = py + getTextManager():getFontHeight(UIFont.NewSmall)
    selector:drawText("From: (" .. tostring(math.floor(metrics.x1)) .. ", " .. tostring(math.floor(metrics.y1)) .. ")", px, py, 0.7, 0.7, 0.7, 1, UIFont.NewSmall)
    py = py + getTextManager():getFontHeight(UIFont.NewSmall)
    selector:drawText("To: (" .. tostring(math.floor(metrics.x2)) .. ", " .. tostring(math.floor(metrics.y2)) .. ")", px, py, 0.7, 0.7, 0.7, 1, UIFont.NewSmall)

    local color = State.GetHighlightColor(selector)
    addAreaHighlightForPlayer(selector.playerNum, metrics.x1, metrics.y1, metrics.x2 + 1, metrics.y2 + 1, selector.player:getZ(), color.r, color.g, color.b, color.a)
    return py
end

function Render.Prerender(selector)
    selector:drawRect(0, 0, selector.width, selector.height,
        selector.backgroundColor.a, selector.backgroundColor.r,
        selector.backgroundColor.g, selector.backgroundColor.b)
    selector:drawRectBorder(0, 0, selector.width, selector.height,
        selector.borderColor.a, selector.borderColor.r,
        selector.borderColor.g, selector.borderColor.b)

    local py = UI_BORDER_SPACING + 1
    local px = UI_BORDER_SPACING + 1

    local title = State.GetTitleText(selector)
    selector:drawText(title,
        selector.width / 2 - (getTextManager():MeasureStringX(UIFont.Medium, title) / 2),
        py, 1, 1, 1, 1, UIFont.Medium)
    py = py + FONT_HGT_MEDIUM + UI_BORDER_SPACING

    selector:drawText(State.GetInstructionText(selector), px, py, 0.8, 0.8, 0.8, 1, UIFont.NewSmall)
    py = py + FONT_HGT + UI_BORDER_SPACING

    py = drawSelectionInfo(selector, py)

    local currentState = tostring(selector.selectorState or State.STATE_IDLE)
    if currentState == State.STATE_IDLE or currentState == State.STATE_DRAGGING or currentState == State.STATE_EXPANDING then
        Render.HighlightSquareAtMousePointer(selector)
    end
end

function Render.PickSquare(selector, screenX, screenY)
    local playerIndex = selector.playerNum
    local z = selector.player:getCurrentSquare():getZ()
    local worldX = screenToIsoX(playerIndex, screenX, screenY, z)
    local worldY = screenToIsoY(playerIndex, screenX, screenY, z)
    return getCell():getGridSquare(worldX, worldY, z), worldX, worldY, z
end

function Render.HighlightSquareAtMousePointer(selector)
    if selector.playerNum ~= 0 then return end
    local square, x, y, z = Render.PickSquare(selector, getMouseX(), getMouseY())
    if square then
        addAreaHighlightForPlayer(selector.playerNum, x, y, x + 1, y + 1, z, 1.0, 1.0, 1.0, 0.5)
    end
end

function Render.Undisplay(selector)
    selector.startRenderTile = false
    selector.startingX = nil
    selector.startingY = nil
    selector.endX = nil
    selector.endY = nil
    selector.selectorState = State.STATE_IDLE
    ISWorldObjectContextMenu.disableWorldMenu = false
    selector:setVisible(false)
    selector:removeFromUIManager()
end

return Render
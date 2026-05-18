require "DC/UI/Colony/ZoneWindow/ZoneSelector/DC_ZoneSelectorState"

DC_ZoneSelectorRender = DC_ZoneSelectorRender or {}

local Render = DC_ZoneSelectorRender
local State = DC_ZoneSelectorState

local FONT = UIFont.Small
local FONT_HGT = getTextManager():getFontHeight(FONT)
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)
local UI_BORDER_SPACING = 10

local function renderGuideRects(selector)
    local guideColor = type(selector and selector.guideColor) == "table" and selector.guideColor or nil
    if not selector or not guideColor then
        return
    end

    for _, rect in ipairs(selector.guideRects or {}) do
        if type(rect) == "table" then
            addAreaHighlightForPlayer(
                selector.playerNum,
                rect[1],
                rect[2],
                (rect[3] or rect[1]) + 1,
                (rect[4] or rect[2]) + 1,
                rect[5] or selector.player:getZ(),
                guideColor.r or 0.2,
                guideColor.g or 0.85,
                guideColor.b or 0.25,
                guideColor.a or 0.18
            )
        end
    end
end

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


function Render.Prerender(selector)
    selector:drawRect(0, 0, selector.width, selector.height,
        selector.backgroundColor.a, selector.backgroundColor.r,
        selector.backgroundColor.g, selector.backgroundColor.b)
    selector:drawRectBorder(0, 0, selector.width, selector.height,
        selector.borderColor.a, selector.borderColor.r,
        selector.borderColor.g, selector.borderColor.b)

    -- The highlight logic for the 3D world stays here
    renderGuideRects(selector)
    local metrics = State.GetSelectionMetrics(selector)
    if metrics then
        local color = State.GetHighlightColor(selector)
        addAreaHighlightForPlayer(selector.playerNum, metrics.x1, metrics.y1, metrics.x2 + 1, metrics.y2 + 1, selector.player:getZ(), color.r, color.g, color.b, color.a)
    end

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

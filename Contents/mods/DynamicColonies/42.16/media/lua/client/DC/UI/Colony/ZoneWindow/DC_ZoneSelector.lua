-- ============================================================================
-- DC_ZoneSelector.lua — 3D world area selector for Dynamic Colonies
--
-- Click-and-drag in the isometric world to define a rectangular area.
-- On mouse-up the selection FREEZES and shows Reset/Confirm/Expand buttons.
-- The preview stays highlighted until the user takes action.
--
-- Usage:
--   DC_ZoneSelector:new(0, 0, 320, 240, player, color, callback, zoneName)
--
-- callback(x1, y1, x2, y2, z) fires only when the user clicks Confirm.
-- ============================================================================

require "ISUI/ISPanelJoypad"
require "DC/UI/Colony/ZoneWindow/ZoneSelector/DC_ZoneSelectorState"
require "DC/UI/Colony/ZoneWindow/ZoneSelector/DC_ZoneSelectorInput"
require "DC/UI/Colony/ZoneWindow/ZoneSelector/DC_ZoneSelectorRender"
require "DC/UI/Colony/ZoneWindow/ZoneSelector/DC_ZoneSelectorUI"
require "DC/UI/Colony/ZoneWindow/ZoneSelector/Components/DC_ZoneSelector_Header"
require "DC/UI/Colony/ZoneWindow/ZoneSelector/Components/DC_ZoneSelector_Body"
require "DC/UI/Colony/ZoneWindow/ZoneSelector/Components/DC_ZoneSelector_Footer"

DC_ZoneSelector = ISPanelJoypad:derive("DC_ZoneSelector")

-- ---------------------------------------------------------------------------
-- Constructor
-- ---------------------------------------------------------------------------

function DC_ZoneSelector:new(x, y, width, height, player, highlightColor, callback, zoneName, initialRect, selectionOptions)
    selectionOptions = type(selectionOptions) == "table" and selectionOptions or {}
    if width == 340 or width == 540 then
        if selectionOptions.maxTiles ~= nil or selectionOptions.currentTiles ~= nil then
            width = 540
        else
            width = 480
        end
    end
    if height == 260 or height == 440 then
        if selectionOptions.maxTiles ~= nil or selectionOptions.currentTiles ~= nil then
            height = 320
        else
            height = 260
        end
    end

    local o = ISPanelJoypad.new(self, x, y, width, height)

    if (x == 0 or x == 100) and (y == 0 or y == 50) then
        o.x = 100
        o.y = 50
        o:setX(o.x)
        o:setY(o.y)
    end

    o.borderColor     = { r = 0.4, g = 0.4, b = 0.4, a = 1 }
    o.backgroundColor = { r = 0, g = 0, b = 0, a = 0.85 }
    o.width           = width
    o.height          = height
    o.player          = player
    o.playerNum       = player:getPlayerNum()
    o.highlightColor  = highlightColor or { r = 0.2, g = 0.8, b = 0.2, a = 0.5 }
    o.callback        = callback
    o.zoneName        = zoneName
    o.maxTiles        = selectionOptions.maxTiles ~= nil and math.max(0, math.floor(tonumber(selectionOptions.maxTiles) or 0)) or nil
    o.tileLimitLabel  = tostring(selectionOptions.tileLimitLabel or "Tile cap")
    o.currentTiles    = math.max(0, math.floor(tonumber(selectionOptions.currentTiles) or 0))
    o.currentTilesLabel = tostring(selectionOptions.currentTilesLabel or "Current tiles")
    o.validationMessage = ""
    o.validateRect    = type(selectionOptions.validateRect) == "function" and selectionOptions.validateRect or nil
    o.getSelectionStats = type(selectionOptions.getSelectionStats) == "function" and selectionOptions.getSelectionStats or nil
    o.guideRects      = type(selectionOptions.guideRects) == "table" and selectionOptions.guideRects or {}
    o.guideColor      = type(selectionOptions.guideColor) == "table" and selectionOptions.guideColor or {
        r = 0.2,
        g = 0.85,
        b = 0.25,
        a = 0.18,
    }

    -- State machine
    o.selectorState   = DC_ZoneSelectorState.STATE_IDLE
    o.startRenderTile = false
    o.drawTileMouse   = true

    -- Support editing or pre-defined area
    if initialRect and type(initialRect) == "table" then
        o.startingX = initialRect[1]
        o.startingY = initialRect[2]
        o.endX      = initialRect[3]
        o.endY      = initialRect[4]
        o.startingZ = initialRect[5] or 0
        o.selectorState = DC_ZoneSelectorState.STATE_PREVIEW
    end

    return o
end

function DC_ZoneSelector:initialise()
    DC_ZoneSelectorUI.Build(self)

    if self.selectorState == DC_ZoneSelectorState.STATE_PREVIEW then
        self:setPreviewButtonsVisible(true)
    end
end

function DC_ZoneSelector:nudge(dx, dy)
    DC_ZoneSelectorInput.Nudge(self, dx, dy)
end

function DC_ZoneSelector:scale(edge, amount)
    DC_ZoneSelectorInput.Scale(self, edge, amount)
end

function DC_ZoneSelector:onCancel()
    DC_ZoneSelectorInput.OnCancel(self)
end

function DC_ZoneSelector:onConfirm()
    DC_ZoneSelectorInput.OnConfirm(self)
end

function DC_ZoneSelector:onReset()
    DC_ZoneSelectorInput.OnReset(self)
end

function DC_ZoneSelector:onExpand()
    DC_ZoneSelectorInput.OnExpand(self)
end

function DC_ZoneSelector:setPreviewButtonsVisible(visible)
    DC_ZoneSelectorRender.SetPreviewButtonsVisible(self, visible)
end

function DC_ZoneSelector:onMouseDownOutside(x, y)
    DC_ZoneSelectorInput.OnMouseDownOutside(self, x, y)
end

function DC_ZoneSelector:onMouseMoveOutside(dx, dy)
    DC_ZoneSelectorInput.OnMouseMoveOutside(self, dx, dy)
end

function DC_ZoneSelector:onMouseUpOutside(x, y)
    DC_ZoneSelectorInput.OnMouseUpOutside(self, x, y)
end

function DC_ZoneSelector:prerender()
    DC_ZoneSelectorRender.Prerender(self)
end

function DC_ZoneSelector:pickSquare(screenX, screenY)
    return DC_ZoneSelectorRender.PickSquare(self, screenX, screenY)
end

function DC_ZoneSelector:highlightSquareAtMousePointer()
    DC_ZoneSelectorRender.HighlightSquareAtMousePointer(self)
end

function DC_ZoneSelector:undisplay()
    DC_ZoneSelectorRender.Undisplay(self)
end


return DC_ZoneSelector

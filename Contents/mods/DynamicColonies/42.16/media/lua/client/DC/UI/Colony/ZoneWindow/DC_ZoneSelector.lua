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
require "ISUI/ISButton"

DC_ZoneSelector = ISPanelJoypad:derive("DC_ZoneSelector")

local FONT_HGT_SMALL  = getTextManager():getFontHeight(UIFont.NewSmall)
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.NewMedium)
local UI_BORDER_SPACING = 10
local BUTTON_HGT = FONT_HGT_SMALL + 6
local BUTTON_WID = 100


-- ---------------------------------------------------------------------------
-- State constants
-- ---------------------------------------------------------------------------
local STATE_IDLE      = "idle"       -- waiting for first drag
local STATE_DRAGGING  = "dragging"   -- mouse is held, selection updating
local STATE_PREVIEW   = "preview"    -- selection frozen, buttons visible
local STATE_EXPANDING = "expanding"  -- re-dragging to adjust endpoint


-- ---------------------------------------------------------------------------
-- Initialise
-- ---------------------------------------------------------------------------

function DC_ZoneSelector:initialise()
    ISPanelJoypad.initialise(self)

    local y = self:getHeight() - UI_BORDER_SPACING - BUTTON_HGT

    -- Cancel — always visible
    self.btnCancel = ISButton:new(
        self:getWidth() - BUTTON_WID - UI_BORDER_SPACING, y,
        BUTTON_WID, BUTTON_HGT,
        "Cancel", self, DC_ZoneSelector.onCancel
    )
    self.btnCancel:enableCancelColor()
    self.btnCancel:initialise()
    self.btnCancel:instantiate()
    self:addChild(self.btnCancel)

    -- Confirm — only visible in preview state
    self.btnConfirm = ISButton:new(
        UI_BORDER_SPACING, y,
        BUTTON_WID, BUTTON_HGT,
        "Confirm", self, DC_ZoneSelector.onConfirm
    )
    self.btnConfirm:initialise()
    self.btnConfirm:instantiate()
    self.btnConfirm.backgroundColor = { r = 0.1, g = 0.45, b = 0.1, a = 1 }
    self.btnConfirm.backgroundColorMouseOver = { r = 0.15, g = 0.6, b = 0.15, a = 1 }
    self.btnConfirm:setVisible(false)
    self:addChild(self.btnConfirm)

    -- Reset — only visible in preview state
    self.btnReset = ISButton:new(
        UI_BORDER_SPACING + BUTTON_WID + 10, y,
        BUTTON_WID, BUTTON_HGT,
        "Reset", self, DC_ZoneSelector.onReset
    )
    self.btnReset:initialise()
    self.btnReset:instantiate()
    self.btnReset:setVisible(false)
    self:addChild(self.btnReset)

    -- Expand — only visible in preview state
    self.btnExpand = ISButton:new(
        UI_BORDER_SPACING + (BUTTON_WID + 10) * 2, y,
        BUTTON_WID, BUTTON_HGT,
        "Expand", self, DC_ZoneSelector.onExpand
    )
    self.btnExpand:initialise()
    self.btnExpand:instantiate()
    self.btnExpand:setVisible(false)
    self:addChild(self.btnExpand)
end


-- ---------------------------------------------------------------------------
-- Button handlers
-- ---------------------------------------------------------------------------

function DC_ZoneSelector:onCancel()
    ISWorldObjectContextMenu.disableWorldMenu = false
    self:undisplay()
end


function DC_ZoneSelector:onConfirm()
    if not self.startingX or not self.endX then return end

    local x1 = math.min(self.startingX, self.endX)
    local x2 = math.max(self.startingX, self.endX)
    local y1 = math.min(self.startingY, self.endY)
    local y2 = math.max(self.startingY, self.endY)
    local z  = self.player:getZ()

    -- Minimum 2×2
    if (x2 - x1) < 1 or (y2 - y1) < 1 then
        self:onReset()
        return
    end

    ISWorldObjectContextMenu.disableWorldMenu = false

    if self.callback then
        self.callback(x1, y1, x2, y2, z)
    end

    self:undisplay()
end


function DC_ZoneSelector:onReset()
    self.startingX = nil
    self.startingY = nil
    self.endX = nil
    self.endY = nil
    self.startRenderTile = false
    self.selectorState = STATE_IDLE
    self:setPreviewButtonsVisible(false)
end


function DC_ZoneSelector:onExpand()
    -- Switch to expanding mode: next drag adjusts only the endpoint
    self.selectorState = STATE_EXPANDING
    self:setPreviewButtonsVisible(false)
end


function DC_ZoneSelector:setPreviewButtonsVisible(visible)
    if self.btnConfirm then self.btnConfirm:setVisible(visible) end
    if self.btnReset then self.btnReset:setVisible(visible) end
    if self.btnExpand then self.btnExpand:setVisible(visible) end
end


-- ---------------------------------------------------------------------------
-- Mouse Events — 3D World Interaction
-- ---------------------------------------------------------------------------

function DC_ZoneSelector:onMouseDownOutside(x, y)
    if self.playerNum ~= 0 then return end

    -- In preview state, ignore world clicks (buttons handle it)
    if self.selectorState == STATE_PREVIEW then return end

    local sq = self:pickSquare(x + self:getAbsoluteX(), y + self:getAbsoluteY())
    if not sq then return end

    if self.selectorState == STATE_IDLE then
        -- Start a fresh selection
        self.startRenderTile = true
        self.startingX = sq:getX()
        self.startingY = sq:getY()
        self.endX = sq:getX()
        self.endY = sq:getY()
        self.selectorState = STATE_DRAGGING
        ISWorldObjectContextMenu.disableWorldMenu = true

    elseif self.selectorState == STATE_EXPANDING then
        -- Keep startingX/Y, just update the endpoint on click
        self.endX = sq:getX()
        self.endY = sq:getY()
        self.selectorState = STATE_DRAGGING
    end
end


function DC_ZoneSelector:onMouseMoveOutside(dx, dy)
    if self.playerNum ~= 0 then return end
    if self.selectorState ~= STATE_DRAGGING then return end

    local sq = self:pickSquare(getMouseX(), getMouseY())
    if sq then
        self.endX = sq:getX()
        self.endY = sq:getY()
    end
end


function DC_ZoneSelector:onMouseUpOutside(x, y)
    if self.playerNum ~= 0 then return end
    if self.selectorState ~= STATE_DRAGGING then return end

    -- Freeze the selection → enter preview
    self.selectorState = STATE_PREVIEW
    self:setPreviewButtonsVisible(true)
end


-- ---------------------------------------------------------------------------
-- Rendering
-- ---------------------------------------------------------------------------

function DC_ZoneSelector:prerender()
    self:drawRect(0, 0, self.width, self.height,
        self.backgroundColor.a, self.backgroundColor.r,
        self.backgroundColor.g, self.backgroundColor.b)
    self:drawRectBorder(0, 0, self.width, self.height,
        self.borderColor.a, self.borderColor.r,
        self.borderColor.g, self.borderColor.b)

    local py = UI_BORDER_SPACING + 1
    local px = UI_BORDER_SPACING + 1

    -- Title
    local title = "ZONE SELECTOR"
    if self.zoneName then
        title = "SELECT AREA: " .. tostring(self.zoneName)
    end
    self:drawText(title,
        self.width / 2 - (getTextManager():MeasureStringX(UIFont.Medium, title) / 2),
        py, 1, 1, 1, 1, UIFont.Medium)
    py = py + FONT_HGT_MEDIUM + UI_BORDER_SPACING

    -- Instructions
    local howTo
    if self.selectorState == STATE_IDLE then
        howTo = "Click and drag on the world to select an area"
    elseif self.selectorState == STATE_DRAGGING then
        howTo = "Drag to adjust the selection, then release"
    elseif self.selectorState == STATE_PREVIEW then
        howTo = "Confirm, Reset, or Expand the selection"
    elseif self.selectorState == STATE_EXPANDING then
        howTo = "Click on the world to set the new endpoint"
    end
    self:drawText(howTo or "", px, py, 0.8, 0.8, 0.8, 1, UIFont.NewSmall)
    py = py + FONT_HGT_SMALL + UI_BORDER_SPACING

    -- Selection info
    if self.startingX and self.endX and self.endY then
        local sx1 = math.min(self.startingX, self.endX)
        local sx2 = math.max(self.startingX, self.endX)
        local sy1 = math.min(self.startingY, self.endY)
        local sy2 = math.max(self.startingY, self.endY)

        local w = (sx2 - sx1) + 1
        local h = (sy2 - sy1) + 1
        local total = w * h

        self:drawText("Width: " .. tostring(w), px, py, 1, 1, 1, 1, UIFont.NewSmall)
        py = py + FONT_HGT_SMALL
        self:drawText("Height: " .. tostring(h), px, py, 1, 1, 1, 1, UIFont.NewSmall)
        py = py + FONT_HGT_SMALL
        self:drawText("Total: " .. tostring(total) .. " tiles", px, py, 1, 1, 1, 1, UIFont.NewSmall)
        py = py + FONT_HGT_SMALL
        self:drawText("From: (" .. tostring(math.floor(sx1)) .. ", " .. tostring(math.floor(sy1)) .. ")", px, py, 0.7, 0.7, 0.7, 1, UIFont.NewSmall)
        py = py + FONT_HGT_SMALL
        self:drawText("To: (" .. tostring(math.floor(sx2)) .. ", " .. tostring(math.floor(sy2)) .. ")", px, py, 0.7, 0.7, 0.7, 1, UIFont.NewSmall)

        -- Draw highlight on world
        local cr = self.highlightColor and self.highlightColor.r or 0.2
        local cg = self.highlightColor and self.highlightColor.g or 0.8
        local cb = self.highlightColor and self.highlightColor.b or 0.2
        local ca = self.highlightColor and self.highlightColor.a or 0.5

        addAreaHighlightForPlayer(self.playerNum, sx1, sy1, sx2 + 1, sy2 + 1, self.player:getZ(), cr, cg, cb, ca)
    end

    -- Cursor highlight (only when actively dragging or idle)
    if self.selectorState == STATE_IDLE or self.selectorState == STATE_DRAGGING or self.selectorState == STATE_EXPANDING then
        self:highlightSquareAtMousePointer()
    end
end


-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------

function DC_ZoneSelector:pickSquare(screenX, screenY)
    local playerIndex = self.playerNum
    local z = self.player:getCurrentSquare():getZ()
    local worldX = screenToIsoX(playerIndex, screenX, screenY, z)
    local worldY = screenToIsoY(playerIndex, screenX, screenY, z)
    return getCell():getGridSquare(worldX, worldY, z), worldX, worldY, z
end


function DC_ZoneSelector:highlightSquareAtMousePointer()
    if self.playerNum ~= 0 then return end
    local square, x, y, z = self:pickSquare(getMouseX(), getMouseY())
    if square then
        addAreaHighlightForPlayer(self.playerNum, x, y, x + 1, y + 1, z, 1.0, 1.0, 1.0, 0.5)
    end
end


function DC_ZoneSelector:undisplay()
    self.startRenderTile = false
    self.startingX = nil
    self.startingY = nil
    self.endX = nil
    self.endY = nil
    self.selectorState = STATE_IDLE
    ISWorldObjectContextMenu.disableWorldMenu = false
    self:setVisible(false)
    self:removeFromUIManager()
end


-- ---------------------------------------------------------------------------
-- Constructor
-- ---------------------------------------------------------------------------

function DC_ZoneSelector:new(x, y, width, height, player, highlightColor, callback, zoneName)
    local o = ISPanelJoypad.new(self, x, y, width, height)

    if x == 0 and y == 0 then
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

    -- State machine
    o.selectorState   = STATE_IDLE
    o.startRenderTile = false
    o.drawTileMouse   = true

    return o
end


return DC_ZoneSelector

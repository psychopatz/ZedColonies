-- ============================================================================
-- DC_ZoneSelector.lua — 3D world area selector for Dynamic Colonies
--
-- Inspired by KarasZoneSelector. Allows the player to click-drag in the
-- isometric world view to select a rectangular area. The selection is
-- highlighted in real-time using addAreaHighlightForPlayer.
--
-- Usage:
--   local sel = DC_ZoneSelector:new(0, 0, 320, 180, player, color, callback)
--   sel:initialise()
--   sel:addToUIManager()
--
-- callback(x1, y1, x2, y2, z) fires when the user confirms the selection.
-- ============================================================================

require "ISUI/ISPanelJoypad"

DC_ZoneSelector = ISPanelJoypad:derive("DC_ZoneSelector")

local FONT_HGT_SMALL  = getTextManager():getFontHeight(UIFont.NewSmall)
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.NewMedium)
local UI_BORDER_SPACING = 10
local BUTTON_HGT = FONT_HGT_SMALL + 6


-- ---------------------------------------------------------------------------
-- Initialise
-- ---------------------------------------------------------------------------

function DC_ZoneSelector:initialise()
    ISPanelJoypad.initialise(self)

    local btnWid = 150

    self.cancel = ISButton:new(
        self:getWidth() - btnWid - UI_BORDER_SPACING,
        self:getHeight() - UI_BORDER_SPACING - BUTTON_HGT,
        btnWid, BUTTON_HGT,
        "Cancel", self, DC_ZoneSelector.onClick
    )
    self.cancel.internal = "CANCEL"
    self.cancel.anchorTop = false
    self.cancel.anchorBottom = true
    self.cancel:enableCancelColor()
    self.cancel:initialise()
    self.cancel:instantiate()
    self:addChild(self.cancel)
end


-- ---------------------------------------------------------------------------
-- Mouse Events — 3D World Interaction
-- ---------------------------------------------------------------------------

function DC_ZoneSelector:onMouseDownOutside(x, y)
    if self.playerNum ~= 0 then return end
    if not self.drawTileMouse or self.startingX then return end

    local sq = self:pickSquare(x + self:getAbsoluteX(), y + self:getAbsoluteY())
    if sq then
        self.startRenderTile = true
        self.drawTileMouse = true
        self.startingX = sq:getX()
        self.startingY = sq:getY()
        self.endX = sq:getX()
        self.endY = sq:getY()
        ISWorldObjectContextMenu.disableWorldMenu = true
    end
end


function DC_ZoneSelector:onMouseMoveOutside(dx, dy)
    if self.playerNum ~= 0 then return end

    local sq = self:pickSquare(getMouseX(), getMouseY())
    if not sq then return end

    if self.drawTileMouse and self.startingX then
        self.endX = sq:getX()
        self.endY = sq:getY()
    end
end


function DC_ZoneSelector:onMouseUpOutside(x, y)
    if self.playerNum ~= 0 then return end
    self:confirmSelection()
end


-- ---------------------------------------------------------------------------
-- Selection Confirmation
-- ---------------------------------------------------------------------------

function DC_ZoneSelector:confirmSelection()
    if not self.startingX or not self.startingY or not self.endX or not self.endY then
        self:undisplay()
        return
    end

    local x1 = math.min(self.startingX, self.endX)
    local x2 = math.max(self.startingX, self.endX)
    local y1 = math.min(self.startingY, self.endY)
    local y2 = math.max(self.startingY, self.endY)
    local z  = self.player:getZ()

    -- Minimum 2×2 selection
    if (x2 - x1) < 1 or (y2 - y1) < 1 then
        self:undisplay()
        return
    end

    ISWorldObjectContextMenu.disableWorldMenu = false

    if self.callback then
        self.callback(x1, y1, x2, y2, z)
    end

    self:undisplay()
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

    local z = UI_BORDER_SPACING + 1
    local x = UI_BORDER_SPACING + 1

    -- Title
    local title = "ZONE SELECTOR"
    if self.zoneName then
        title = "SELECT AREA: " .. tostring(self.zoneName)
    end
    self:drawText(title,
        self.width / 2 - (getTextManager():MeasureStringX(UIFont.Medium, title) / 2),
        z, 1, 1, 1, 1, UIFont.Medium)
    z = z + FONT_HGT_MEDIUM + UI_BORDER_SPACING

    -- Instructions
    local howTo = "Click and drag on the world to select an area"
    if self.startingX then
        howTo = "Release to confirm selection"
    end
    self:drawText(howTo, x, z, 0.8, 0.8, 0.8, 1, UIFont.NewSmall)
    z = z + FONT_HGT_SMALL + UI_BORDER_SPACING

    -- Selection info
    if self.startingX and self.startRenderTile and self.endX and self.endY then
        local sx1 = math.min(self.startingX, self.endX)
        local sx2 = math.max(self.startingX, self.endX)
        local sy1 = math.min(self.startingY, self.endY)
        local sy2 = math.max(self.startingY, self.endY)

        local w = (sx2 - sx1) + 1
        local h = (sy2 - sy1) + 1
        local total = w * h

        self:drawText("Width: " .. tostring(w), x, z, 1, 1, 1, 1, UIFont.NewSmall)
        z = z + FONT_HGT_SMALL
        self:drawText("Height: " .. tostring(h), x, z, 1, 1, 1, 1, UIFont.NewSmall)
        z = z + FONT_HGT_SMALL
        self:drawText("Total: " .. tostring(total) .. " tiles", x, z, 1, 1, 1, 1, UIFont.NewSmall)

        -- Draw highlight on world
        local cr = self.highlightColor and self.highlightColor.r or 0.2
        local cg = self.highlightColor and self.highlightColor.g or 0.8
        local cb = self.highlightColor and self.highlightColor.b or 0.2
        local ca = self.highlightColor and self.highlightColor.a or 0.5

        addAreaHighlightForPlayer(self.playerNum, sx1, sy1, sx2 + 1, sy2 + 1, self.player:getZ(), cr, cg, cb, ca)
    end

    -- Cursor highlight
    self:highlightSquareAtMousePointer()
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


function DC_ZoneSelector:reset()
    self.startRenderTile = false
    self.drawTileMouse = false
    self.startingX = nil
    self.startingY = nil
    self.endX = nil
    self.endY = nil
    ISWorldObjectContextMenu.disableWorldMenu = false
end


function DC_ZoneSelector:undisplay()
    self:reset()
    self:setVisible(false)
    self:removeFromUIManager()
end


function DC_ZoneSelector:onClick(button)
    if button.internal == "CANCEL" then
        self:undisplay()
    end
end


-- ---------------------------------------------------------------------------
-- Constructor
-- ---------------------------------------------------------------------------

--- @param x number
--- @param y number
--- @param width number
--- @param height number
--- @param player IsoPlayer
--- @param highlightColor table  {r,g,b,a} for the selection highlight
--- @param callback function     (x1, y1, x2, y2, z)
--- @param zoneName string|nil   Optional label for the selector title
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

    o.drawTileMouse   = true
    o.startRenderTile = false

    return o
end


return DC_ZoneSelector

-- ============================================================================
-- DC_ZoneSelector_Body.lua — Body component with Left/Right split for Zone Selector
-- ============================================================================

local Body = ISPanel:derive("DC_ZoneSelectorBody")

function Body:createChildren()
    ISPanel.createChildren(self)
    
    local sel = self.selector
    if not sel then return end
    
    local splitX = math.floor(self.width * 0.45)
    
    -- Left Panel: Metrics
    self.leftPanel = ISPanel:new(0, 0, splitX, self.height)
    self.leftPanel:initialise()
    self.leftPanel.backgroundColor = { r = 0, g = 0, b = 0, a = 0 }
    self.leftPanel.prerender = function(p)
        ISPanel.prerender(p)
        local State = DC_ZoneSelectorState
        local metrics = State.GetSelectionMetrics(sel)
        if not metrics then return end
        
        local py = 5
        local px = 15
        local fh = getTextManager():getFontHeight(UIFont.Small)
        
        p:drawText("Width:", px, py, 1, 1, 1, 1, UIFont.Small)
        p:drawText(tostring(metrics.width), px + 55, py, 1, 1, 0, 1, UIFont.Medium)
        
        p:drawText("Height:", px + 95, py, 1, 1, 1, 1, UIFont.Small)
        p:drawText(tostring(metrics.height), px + 155, py, 1, 1, 0, 1, UIFont.Medium)
        
        py = py + fh + 8
        p:drawText("Total Area:", px, py, 0.8, 0.8, 0.8, 1, UIFont.Small)
        p:drawText(tostring(metrics.total) .. " tiles", px, py + fh - 2, 1, 1, 1, 1, UIFont.Medium)
        
        py = py + fh * 2 + 10
        p:drawText("Coordinates:", px, py, 0.6, 0.6, 0.6, 1, UIFont.Small)
        p:drawText("From: " .. math.floor(metrics.x1) .. ", " .. math.floor(metrics.y1), px, py + fh, 0.7, 0.7, 0.7, 1, UIFont.NewSmall)
        p:drawText("To:   " .. math.floor(metrics.x2) .. ", " .. math.floor(metrics.y2), px, py + fh * 2 + 2, 0.7, 0.7, 0.7, 1, UIFont.NewSmall)
    end
    self:addChild(self.leftPanel)
    
    -- Right Panel: Controls
    self.rightPanel = ISPanel:new(splitX, 0, self.width - splitX, self.height)
    self.rightPanel:initialise()
    self.rightPanel.backgroundColor = { r = 1, g = 1, b = 1, a = 0.05 }
    self:addChild(self.rightPanel)
    
    local rpx = 10
    local rpy = 5
    local arrowW = 32
    local btnH = 22
    
    -- Scale Section
    self.lblScale = ISLabel:new(rpx, rpy, 18, "Scale Area:", 1, 1, 1, 1, UIFont.Small, true)
    self.lblScale:initialise()
    self.rightPanel:addChild(self.lblScale)
    sel.lblScale = self.lblScale
    
    rpy = rpy + 20
    local sx = rpx
    
    -- Row 1: Positives
    sel.btnScaleW = ISButton:new(sx, rpy, arrowW, btnH, "W", sel, function() sel:scale("W", 1) end)
    sel.btnScaleW:initialise()
    self.rightPanel:addChild(sel.btnScaleW)
    
    sel.btnScaleE = ISButton:new(sx + arrowW + 4, rpy, arrowW, btnH, "E", sel, function() sel:scale("E", 1) end)
    sel.btnScaleE:initialise()
    self.rightPanel:addChild(sel.btnScaleE)
    
    sel.btnScaleN = ISButton:new(sx + (arrowW + 4) * 2, rpy, arrowW, btnH, "N", sel, function() sel:scale("N", 1) end)
    sel.btnScaleN:initialise()
    self.rightPanel:addChild(sel.btnScaleN)
    
    sel.btnScaleS = ISButton:new(sx + (arrowW + 4) * 3, rpy, arrowW, btnH, "S", sel, function() sel:scale("S", 1) end)
    sel.btnScaleS:initialise()
    self.rightPanel:addChild(sel.btnScaleS)
    
    rpy = rpy + btnH + 4
    
    -- Row 2: Negatives
    sel.btnScaleW_Inner = ISButton:new(sx, rpy, arrowW, btnH, "-W", sel, function() sel:scale("W", -1) end)
    sel.btnScaleW_Inner:initialise()
    self.rightPanel:addChild(sel.btnScaleW_Inner)
    
    sel.btnScaleE_Inner = ISButton:new(sx + arrowW + 4, rpy, arrowW, btnH, "-E", sel, function() sel:scale("E", -1) end)
    sel.btnScaleE_Inner:initialise()
    self.rightPanel:addChild(sel.btnScaleE_Inner)
    
    sel.btnScaleN_Inner = ISButton:new(sx + (arrowW + 4) * 2, rpy, arrowW, btnH, "-N", sel, function() sel:scale("N", -1) end)
    sel.btnScaleN_Inner:initialise()
    self.rightPanel:addChild(sel.btnScaleN_Inner)
    
    sel.btnScaleS_Inner = ISButton:new(sx + (arrowW + 4) * 3, rpy, arrowW, btnH, "-S", sel, function() sel:scale("S", -1) end)
    sel.btnScaleS_Inner:initialise()
    self.rightPanel:addChild(sel.btnScaleS_Inner)
    
    -- Nudge Section
    rpy = rpy + btnH + 10
    self.lblNudge = ISLabel:new(rpx, rpy, 18, "Move Area:", 1, 1, 1, 1, UIFont.Small, true)
    self.lblNudge:initialise()
    self.rightPanel:addChild(self.lblNudge)
    sel.lblNudge = self.lblNudge
    
    rpy = rpy + 20
    sel.btnNudgeW = ISButton:new(sx, rpy, arrowW, btnH, "<", sel, function() sel:nudge(-1, 0) end)
    sel.btnNudgeW:initialise()
    self.rightPanel:addChild(sel.btnNudgeW)
    
    sel.btnNudgeE = ISButton:new(sx + arrowW + 4, rpy, arrowW, btnH, ">", sel, function() sel:nudge(1, 0) end)
    sel.btnNudgeE:initialise()
    self.rightPanel:addChild(sel.btnNudgeE)
    
    sel.btnNudgeN = ISButton:new(sx + (arrowW + 4) * 2, rpy, arrowW, btnH, "^", sel, function() sel:nudge(0, -1) end)
    sel.btnNudgeN:initialise()
    self.rightPanel:addChild(sel.btnNudgeN)
    
    sel.btnNudgeS = ISButton:new(sx + (arrowW + 4) * 3, rpy, arrowW, btnH, "v", sel, function() sel:nudge(0, 1) end)
    sel.btnNudgeS:initialise()
    self.rightPanel:addChild(sel.btnNudgeS)
end

function Body:new(x, y, width, height, selector)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.selector = selector
    o.backgroundColor = { r = 0, g = 0, b = 0, a = 0 }
    o:createChildren()
    return o
end

DC_ZoneSelectorBody = Body
return Body

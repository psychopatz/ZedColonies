-- ============================================================================
-- DC_ZoneSelector_Footer.lua — Footer component for Zone Selector
-- ============================================================================

local Footer = ISPanel:derive("DC_ZoneSelectorFooter")

function Footer:createChildren()
    ISPanel.createChildren(self)
    
    local sel = self.selector
    if not sel then return end
    
    local btnH = getTextManager():getFontHeight(UIFont.NewSmall) + 10
    local btnW = 95
    local pad = 6
    
    -- Confirm
    self.btnConfirm = ISButton:new(pad, 5, btnW, btnH, "Confirm", sel, DC_ZoneSelector.onConfirm)
    self.btnConfirm:initialise()
    self.btnConfirm:instantiate()
    self.btnConfirm.backgroundColor = { r = 0.1, g = 0.45, b = 0.1, a = 1 }
    self.btnConfirm.backgroundColorMouseOver = { r = 0.15, g = 0.6, b = 0.15, a = 1 }
    self:addChild(self.btnConfirm)
    sel.btnConfirm = self.btnConfirm

    -- Reset
    self.btnReset = ISButton:new(pad + btnW + pad, 8, btnW, btnH, "Reset", sel, DC_ZoneSelector.onReset)
    self.btnReset:initialise()
    self.btnReset:instantiate()
    self:addChild(self.btnReset)
    sel.btnReset = self.btnReset

    -- Expand
    self.btnExpand = ISButton:new(pad + (btnW + pad) * 2, 8, btnW, btnH, "Expand", sel, DC_ZoneSelector.onExpand)
    self.btnExpand:initialise()
    self.btnExpand:instantiate()
    self:addChild(self.btnExpand)
    sel.btnExpand = self.btnExpand

    -- Cancel (Far right)
    self.btnCancel = ISButton:new(self.width - btnW - pad, 8, btnW, btnH, "Cancel", sel, DC_ZoneSelector.onCancel)
    self.btnCancel:enableCancelColor()
    self.btnCancel:initialise()
    self.btnCancel:instantiate()
    self:addChild(self.btnCancel)
    sel.btnCancel = self.btnCancel
end

function Footer:new(x, y, width, height, selector)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.selector = selector
    o.backgroundColor = { r = 0, g = 0, b = 0, a = 0.2 }
    o:createChildren()
    return o
end

DC_ZoneSelectorFooter = Footer
return Footer

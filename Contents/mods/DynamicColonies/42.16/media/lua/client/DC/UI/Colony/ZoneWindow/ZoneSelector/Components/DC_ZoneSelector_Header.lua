-- ============================================================================
-- DC_ZoneSelector_Header.lua — Header component for Zone Selector
-- ============================================================================

local Header = ISPanel:derive("DC_ZoneSelectorHeader")

function Header:createChildren()
    ISPanel.createChildren(self)
end

function Header:prerender()
    ISPanel.prerender(self)
    
    local sel = self.selector
    if not sel then return end
    
    local State = DC_ZoneSelectorState
    local title = State.GetTitleText(sel)
    
    self:drawText(title, 
        self.width / 2 - (getTextManager():MeasureStringX(UIFont.Medium, title) / 2), 
        8, 1, 1, 1, 1, UIFont.Medium)
    
    local instructions = State.GetInstructionText(sel)
    self:drawText(instructions, 
        self.width / 2 - (getTextManager():MeasureStringX(UIFont.NewSmall, instructions) / 2), 
        28, 0.8, 0.8, 0.8, 1, UIFont.NewSmall)
end

function Header:new(x, y, width, height, selector)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.selector = selector
    o.backgroundColor = { r = 0, g = 0, b = 0, a = 0 }
    return o
end

DC_ZoneSelectorHeader = Header
return Header

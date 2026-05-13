require "ISUI/ISButton"
require "ISUI/ISLabel"

DC_ZoneSelectorUI = DC_ZoneSelectorUI or {}

local UI = DC_ZoneSelectorUI

function UI.Build(selector)
    ISPanelJoypad.initialise(selector)
    
    local headerH = 50
    local footerH = 40
    local bodyH = selector.height - headerH - footerH
    
    -- ===== HEADER =====
    selector.header = DC_ZoneSelectorHeader:new(0, 0, selector.width, headerH, selector)
    selector.header:initialise()
    selector.header:setAnchorRight(true)
    selector:addChild(selector.header)
    
    -- ===== FOOTER =====
    selector.footer = DC_ZoneSelectorFooter:new(0, selector.height - footerH, selector.width, footerH, selector)
    selector.footer:initialise()
    selector.footer:setAnchorRight(true)
    selector.footer:setAnchorTop(false)
    selector.footer:setAnchorBottom(true)
    selector:addChild(selector.footer)
    
    -- ===== BODY =====
    selector.body = DC_ZoneSelectorBody:new(0, headerH, selector.width, bodyH, selector)
    selector.body:initialise()
    selector.body:setAnchorRight(true)
    selector.body:setAnchorBottom(true)
    selector:addChild(selector.body)
    
    -- Sync references for visibility control
    selector.mainPanel = selector.body -- Backward compatibility if needed
end

return UI
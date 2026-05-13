require "ISUI/ISButton"
require "ISUI/ISLabel"

DC_ZoneSelectorUI = DC_ZoneSelectorUI or {}

local UI = DC_ZoneSelectorUI

function UI.Build(selector)
    ISPanelJoypad.initialise(selector)

    local y = selector:getHeight() - 10 - (getTextManager():getFontHeight(UIFont.NewSmall) + 6)

    selector.btnCancel = ISButton:new(
        selector:getWidth() - 100 - 10, y,
        100, getTextManager():getFontHeight(UIFont.NewSmall) + 6,
        "Cancel", selector, DC_ZoneSelector.onCancel
    )
    selector.btnCancel:enableCancelColor()
    selector.btnCancel:initialise()
    selector.btnCancel:instantiate()
    selector:addChild(selector.btnCancel)

    selector.btnConfirm = ISButton:new(
        10, y,
        100, getTextManager():getFontHeight(UIFont.NewSmall) + 6,
        "Confirm", selector, DC_ZoneSelector.onConfirm
    )
    selector.btnConfirm:initialise()
    selector.btnConfirm:instantiate()
    selector.btnConfirm.backgroundColor = { r = 0.1, g = 0.45, b = 0.1, a = 1 }
    selector.btnConfirm.backgroundColorMouseOver = { r = 0.15, g = 0.6, b = 0.15, a = 1 }
    selector.btnConfirm:setVisible(false)
    selector:addChild(selector.btnConfirm)

    selector.btnReset = ISButton:new(
        120, y,
        100, getTextManager():getFontHeight(UIFont.NewSmall) + 6,
        "Reset", selector, DC_ZoneSelector.onReset
    )
    selector.btnReset:initialise()
    selector.btnReset:instantiate()
    selector.btnReset:setVisible(false)
    selector:addChild(selector.btnReset)

    selector.btnExpand = ISButton:new(
        230, y,
        100, getTextManager():getFontHeight(UIFont.NewSmall) + 6,
        "Expand", selector, DC_ZoneSelector.onExpand
    )
    selector.btnExpand:initialise()
    selector.btnExpand:instantiate()
    selector.btnExpand:setVisible(false)
    selector:addChild(selector.btnExpand)

    local fy = y - (getTextManager():getFontHeight(UIFont.NewSmall) + 6) - 8
    local arrowW = 32
    local labelW = 60

    selector.lblNudge = ISLabel:new(10, fy + 4, 18, "Nudge:", 1, 1, 1, 1, UIFont.Small, true)
    selector.lblNudge:initialise()
    selector.lblNudge:setVisible(false)
    selector:addChild(selector.lblNudge)

    local nx = 10 + labelW
    selector.btnNudgeW = ISButton:new(nx, fy, arrowW, 22, "<", selector, function() selector:nudge(-1, 0) end)
    selector.btnNudgeW:initialise()
    selector.btnNudgeW:setVisible(false)
    selector:addChild(selector.btnNudgeW)

    selector.btnNudgeE = ISButton:new(nx + arrowW + 4, fy, arrowW, 22, ">", selector, function() selector:nudge(1, 0) end)
    selector.btnNudgeE:initialise()
    selector.btnNudgeE:setVisible(false)
    selector:addChild(selector.btnNudgeE)

    selector.btnNudgeN = ISButton:new(nx + (arrowW + 4) * 2, fy, arrowW, 22, "^", selector, function() selector:nudge(0, -1) end)
    selector.btnNudgeN:initialise()
    selector.btnNudgeN:setVisible(false)
    selector:addChild(selector.btnNudgeN)

    selector.btnNudgeS = ISButton:new(nx + (arrowW + 4) * 3, fy, arrowW, 22, "v", selector, function() selector:nudge(0, 1) end)
    selector.btnNudgeS:initialise()
    selector.btnNudgeS:setVisible(false)
    selector:addChild(selector.btnNudgeS)

    local sy = fy - 26
    selector.lblScale = ISLabel:new(10, sy + 4, 18, "Scale:", 1, 1, 1, 1, UIFont.Small, true)
    selector.lblScale:initialise()
    selector.lblScale:setVisible(false)
    selector:addChild(selector.lblScale)

    local sx = 10 + labelW
    selector.btnScaleW = ISButton:new(sx, sy, arrowW, 22, "W", selector, function() selector:scale("W", 1) end)
    selector.btnScaleW:initialise()
    selector.btnScaleW:setVisible(false)
    selector:addChild(selector.btnScaleW)

    selector.btnScaleE = ISButton:new(sx + arrowW + 4, sy, arrowW, 22, "E", selector, function() selector:scale("E", 1) end)
    selector.btnScaleE:initialise()
    selector.btnScaleE:setVisible(false)
    selector:addChild(selector.btnScaleE)

    selector.btnScaleN = ISButton:new(sx + (arrowW + 4) * 2, sy, arrowW, 22, "N", selector, function() selector:scale("N", 1) end)
    selector.btnScaleN:initialise()
    selector.btnScaleN:setVisible(false)
    selector:addChild(selector.btnScaleN)

    selector.btnScaleS = ISButton:new(sx + (arrowW + 4) * 3, sy, arrowW, 22, "S", selector, function() selector:scale("S", 1) end)
    selector.btnScaleS:initialise()
    selector.btnScaleS:setVisible(false)
    selector:addChild(selector.btnScaleS)

    selector.btnScaleW_Inner = ISButton:new(sx + 160, sy, arrowW, 22, "-W", selector, function() selector:scale("W", -1) end)
    selector.btnScaleW_Inner:initialise()
    selector.btnScaleW_Inner:setVisible(false)
    selector:addChild(selector.btnScaleW_Inner)

    selector.btnScaleE_Inner = ISButton:new(sx + 160 + arrowW + 4, sy, arrowW, 22, "-E", selector, function() selector:scale("E", -1) end)
    selector.btnScaleE_Inner:initialise()
    selector.btnScaleE_Inner:setVisible(false)
    selector:addChild(selector.btnScaleE_Inner)

    selector.btnScaleN_Inner = ISButton:new(sx + 160 + (arrowW + 4) * 2, sy, arrowW, 22, "-N", selector, function() selector:scale("N", -1) end)
    selector.btnScaleN_Inner:initialise()
    selector.btnScaleN_Inner:setVisible(false)
    selector:addChild(selector.btnScaleN_Inner)

    selector.btnScaleS_Inner = ISButton:new(sx + 160 + (arrowW + 4) * 3, sy, arrowW, 22, "-S", selector, function() selector:scale("S", -1) end)
    selector.btnScaleS_Inner:initialise()
    selector.btnScaleS_Inner:setVisible(false)
    selector:addChild(selector.btnScaleS_Inner)
end

return UI
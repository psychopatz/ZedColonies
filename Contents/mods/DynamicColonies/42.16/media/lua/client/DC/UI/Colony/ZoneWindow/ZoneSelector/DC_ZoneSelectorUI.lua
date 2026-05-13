require "ISUI/ISButton"
require "ISUI/ISLabel"

DC_ZoneSelectorUI = DC_ZoneSelectorUI or {}

local UI = DC_ZoneSelectorUI

function UI.Build(selector)
    ISPanelJoypad.initialise(selector)

    -- Action bar height
    local actionH = getTextManager():getFontHeight(UIFont.NewSmall) + 16
    local y = selector:getHeight() - actionH

    -- ===== ACTION BUTTONS (Bottom) =====
    selector.btnCancel = ISButton:new(
        selector:getWidth() - 100 - 10, y + 5,
        100, getTextManager():getFontHeight(UIFont.NewSmall) + 6,
        "Cancel", selector, DC_ZoneSelector.onCancel
    )
    selector.btnCancel:enableCancelColor()
    selector.btnCancel:initialise()
    selector.btnCancel:instantiate()
    selector:addChild(selector.btnCancel)

    selector.btnConfirm = ISButton:new(
        10, y + 5,
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
        120, y + 5,
        100, getTextManager():getFontHeight(UIFont.NewSmall) + 6,
        "Reset", selector, DC_ZoneSelector.onReset
    )
    selector.btnReset:initialise()
    selector.btnReset:instantiate()
    selector.btnReset:setVisible(false)
    selector:addChild(selector.btnReset)

    selector.btnExpand = ISButton:new(
        230, y + 5,
        100, getTextManager():getFontHeight(UIFont.NewSmall) + 6,
        "Expand", selector, DC_ZoneSelector.onExpand
    )
    selector.btnExpand:initialise()
    selector.btnExpand:instantiate()
    selector.btnExpand:setVisible(false)
    selector:addChild(selector.btnExpand)


    -- ===== MAIN CONTENT PANEL =====
    selector.mainPanel = ISPanel:new(0, 0, selector.width, y)
    selector.mainPanel:initialise()
    selector.mainPanel.backgroundColor = { r = 0, g = 0, b = 0, a = 0 }
    selector.mainPanel:setAnchorRight(true)
    selector.mainPanel:setAnchorBottom(true)
    selector.mainPanel.prerender = function(panel)
        ISPanel.prerender(panel)
        local py = 11
        local px = 11
        local sel = panel.parent
        local State = DC_ZoneSelectorState

        -- Title
        local title = State.GetTitleText(sel)
        panel:drawText(title,
            panel.width / 2 - (getTextManager():MeasureStringX(UIFont.Medium, title) / 2),
            py, 1, 1, 1, 1, UIFont.Medium)
        py = py + getTextManager():getFontHeight(UIFont.Medium) + 10

        -- Instructions
        panel:drawText(State.GetInstructionText(sel), px, py, 0.8, 0.8, 0.8, 1, UIFont.NewSmall)
        py = py + getTextManager():getFontHeight(UIFont.NewSmall) + 10

        -- Metrics
        local metrics = State.GetSelectionMetrics(sel)
        if metrics then
            -- Width and Height side-by-side
            panel:drawText("Width: " .. tostring(metrics.width), px, py, 1, 1, 1, 1, UIFont.Small)
            panel:drawText("Height: " .. tostring(metrics.height), px + 100, py, 1, 1, 1, 1, UIFont.Small)
            py = py + getTextManager():getFontHeight(UIFont.Small) + 4

            panel:drawText("Total: " .. tostring(metrics.total) .. " tiles", px, py, 1, 1, 1, 1, UIFont.Small)
            py = py + getTextManager():getFontHeight(UIFont.Small) + 8

            panel:drawText("From: (" .. tostring(math.floor(metrics.x1)) .. ", " .. tostring(math.floor(metrics.y1)) .. ")", px, py, 0.7, 0.7, 0.7, 1, UIFont.Small)
            py = py + getTextManager():getFontHeight(UIFont.Small) + 2
            panel:drawText("To: (" .. tostring(math.floor(metrics.x2)) .. ", " .. tostring(math.floor(metrics.y2)) .. ")", px, py, 0.7, 0.7, 0.7, 1, UIFont.Small)
        end
    end
    selector:addChild(selector.mainPanel)

    local py = selector.mainPanel:getHeight() - 10
    local arrowW = 32
    local labelW = 60
    local nx = 10 + labelW

    -- Nudge (Bottom row of main panel)
    py = py - 22
    selector.lblNudge = ISLabel:new(10, py + 4, 18, "Nudge:", 1, 1, 1, 1, UIFont.Small, true)
    selector.lblNudge:initialise()
    selector.lblNudge:setVisible(false)
    selector.mainPanel:addChild(selector.lblNudge)

    selector.btnNudgeW = ISButton:new(nx, py, arrowW, 22, "<", selector, function() selector:nudge(-1, 0) end)
    selector.btnNudgeW:initialise()
    selector.btnNudgeW:setVisible(false)
    selector.mainPanel:addChild(selector.btnNudgeW)

    selector.btnNudgeE = ISButton:new(nx + arrowW + 4, py, arrowW, 22, ">", selector, function() selector:nudge(1, 0) end)
    selector.btnNudgeE:initialise()
    selector.btnNudgeE:setVisible(false)
    selector.mainPanel:addChild(selector.btnNudgeE)

    selector.btnNudgeN = ISButton:new(nx + (arrowW + 4) * 2, py, arrowW, 22, "^", selector, function() selector:nudge(0, -1) end)
    selector.btnNudgeN:initialise()
    selector.btnNudgeN:setVisible(false)
    selector.mainPanel:addChild(selector.btnNudgeN)

    selector.btnNudgeS = ISButton:new(nx + (arrowW + 4) * 3, py, arrowW, 22, "v", selector, function() selector:nudge(0, 1) end)
    selector.btnNudgeS:initialise()
    selector.btnNudgeS:setVisible(false)
    selector.mainPanel:addChild(selector.btnNudgeS)

    -- Scale Negative Row (-W, -E, -N, -S)
    py = py - 26
    selector.btnScaleW_Inner = ISButton:new(nx, py, arrowW, 22, "-W", selector, function() selector:scale("W", -1) end)
    selector.btnScaleW_Inner:initialise()
    selector.btnScaleW_Inner:setVisible(false)
    selector.mainPanel:addChild(selector.btnScaleW_Inner)

    selector.btnScaleE_Inner = ISButton:new(nx + arrowW + 4, py, arrowW, 22, "-E", selector, function() selector:scale("E", -1) end)
    selector.btnScaleE_Inner:initialise()
    selector.btnScaleE_Inner:setVisible(false)
    selector.mainPanel:addChild(selector.btnScaleE_Inner)

    selector.btnScaleN_Inner = ISButton:new(nx + (arrowW + 4) * 2, py, arrowW, 22, "-N", selector, function() selector:scale("N", -1) end)
    selector.btnScaleN_Inner:initialise()
    selector.btnScaleN_Inner:setVisible(false)
    selector.mainPanel:addChild(selector.btnScaleN_Inner)

    selector.btnScaleS_Inner = ISButton:new(nx + (arrowW + 4) * 3, py, arrowW, 22, "-S", selector, function() selector:scale("S", -1) end)
    selector.btnScaleS_Inner:initialise()
    selector.btnScaleS_Inner:setVisible(false)
    selector.mainPanel:addChild(selector.btnScaleS_Inner)

    -- Scale Positive Row (W, E, N, S)
    py = py - 26
    selector.lblScale = ISLabel:new(10, py + 4, 18, "Scale:", 1, 1, 1, 1, UIFont.Small, true)
    selector.lblScale:initialise()
    selector.lblScale:setVisible(false)
    selector.mainPanel:addChild(selector.lblScale)

    selector.btnScaleW = ISButton:new(nx, py, arrowW, 22, "W", selector, function() selector:scale("W", 1) end)
    selector.btnScaleW:initialise()
    selector.btnScaleW:setVisible(false)
    selector.mainPanel:addChild(selector.btnScaleW)

    selector.btnScaleE = ISButton:new(nx + arrowW + 4, py, arrowW, 22, "E", selector, function() selector:scale("E", 1) end)
    selector.btnScaleE:initialise()
    selector.btnScaleE:setVisible(false)
    selector.mainPanel:addChild(selector.btnScaleE)

    selector.btnScaleN = ISButton:new(nx + (arrowW + 4) * 2, py, arrowW, 22, "N", selector, function() selector:scale("N", 1) end)
    selector.btnScaleN:initialise()
    selector.btnScaleN:setVisible(false)
    selector.mainPanel:addChild(selector.btnScaleN)

    selector.btnScaleS = ISButton:new(nx + (arrowW + 4) * 3, py, arrowW, 22, "S", selector, function() selector:scale("S", 1) end)
    selector.btnScaleS:initialise()
    selector.btnScaleS:setVisible(false)
    selector.mainPanel:addChild(selector.btnScaleS)
end

return UI
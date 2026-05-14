DC_ZoneWindow = DC_ZoneWindow or {}
DC_ZoneWindow.Internal = DC_ZoneWindow.Internal or {}
DC_ZoneWindow.Internal.RealBase = DC_ZoneWindow.Internal.RealBase or {}

local RealBaseUI = DC_ZoneWindow.Internal.RealBase

local function getConfig()
    return DC_Colony and DC_Colony.Config or nil
end

function RealBaseUI.IsMode(window)
    return window and tostring(window.mode or "") == "realbase"
end

function RealBaseUI.ApplyOptions(window, options)
    if not window then
        return
    end

    options = type(options) == "table" and options or {}
    window.mode = tostring(options.mode or window.mode or "generic")
    window.realBaseContext = type(options.realBaseContext) == "table" and options.realBaseContext or window.realBaseContext or {}

    local config = getConfig()
    if config and config.GetOwnerUsername and window.player then
        window.realBaseContext.ownerUsername = tostring(window.realBaseContext.ownerUsername or config.GetOwnerUsername(window.player) or "local")
    else
        window.realBaseContext.ownerUsername = tostring(window.realBaseContext.ownerUsername or "local")
    end
    window.realBaseContext.colonyId = tostring(window.realBaseContext.colonyId or window.colonyId or "")
    if window.realBaseContext.allowedBaseTiles == nil and window.realBaseContext.activeBarricadeCount ~= nil then
        local tilesPerBarricade = config and config.GetBaseTilesPerBarricade and config.GetBaseTilesPerBarricade() or 30
        window.realBaseContext.allowedBaseTiles = math.max(0, math.floor(tonumber(window.realBaseContext.activeBarricadeCount) or 0))
            * math.max(0, math.floor(tonumber(tilesPerBarricade) or 30))
    end
end

function RealBaseUI.GetValidationOptions(window)
    local context = window and window.realBaseContext or {}
    return {
        allowedBaseTiles = math.max(0, math.floor(tonumber(context and context.allowedBaseTiles) or 0)),
        headquartersLevel = math.max(0, math.floor(tonumber(context and context.headquartersLevel) or 0)),
        completedBarricades = math.max(0, math.floor(tonumber(context and context.completedBarricadeCount) or tonumber(context and context.activeBarricadeCount) or 0)),
        unlockedPlotCount = math.max(0, math.floor(tonumber(context and context.unlockedPlotCount) or 0)),
        areaTileCap = DC_Colony and DC_Colony.Config and DC_Colony.Config.GetBaseAreaSlotTileCap and DC_Colony.Config.GetBaseAreaSlotTileCap() or 100
    }
end

function RealBaseUI.SetStatus(window, message, isError)
    if not window or not window.detailStatusLabel then
        return
    end

    window.detailStatusLabel:setName(tostring(message or ""))
    if isError == true then
        window.detailStatusLabel.r = 0.95
        window.detailStatusLabel.g = 0.62
        window.detailStatusLabel.b = 0.62
        window.detailStatusLabel.a = 1
    else
        window.detailStatusLabel.r = 0.72
        window.detailStatusLabel.g = 0.88
        window.detailStatusLabel.b = 0.72
        window.detailStatusLabel.a = 1
    end
end

function RealBaseUI.ConfigureWindow(window)
    if not RealBaseUI.IsMode(window) then
        return
    end

    window.title = "Base Zone"
    if window.headerPanel then
        window.headerPanel.prerender = function(panel)
            ISPanel.prerender(panel)
            panel:drawTextCentre("BASE ZONE", panel.width / 2, 6, 1, 1, 1, 1, UIFont.Large)
            if panel.btnOptions then
                panel.btnOptions:setX(panel.width - panel.btnOptions:getWidth() - 10)
            end
        end
    end

    if window.btnAddZone then
        window.btnAddZone:setVisible(false)
        window.btnAddZone:setEnable(false)
    end
    if window.btnDeleteZone then
        window.btnDeleteZone:setVisible(false)
        window.btnDeleteZone:setEnable(false)
    end
    if window.detailNameEntry then
        window.detailNameEntry:setEditable(false)
    end
    if window.detailNameLabel then
        window.detailNameLabel:setVisible(false)
    end
    if window.detailNameEntry then
        window.detailNameEntry:setVisible(false)
    end
    if window.detailTypeLabel then
        window.detailTypeLabel:setVisible(false)
    end
    if window.detailTypeCombo then
        window.detailTypeCombo:setVisible(false)
    end
    if window.btnAddArea then
        window.btnAddArea:setVisible(false)
        window.btnAddArea:setEnable(false)
    end
    if window.btnDeleteArea then
        window.btnDeleteArea:setVisible(false)
        window.btnDeleteArea:setEnable(false)
    end
    if window.btnEditArea then
        window.btnEditArea:setTitle("Set Area")
    end
    if window.btnNudgeW_Main then window.btnNudgeW_Main:setVisible(false) end
    if window.btnNudgeE_Main then window.btnNudgeE_Main:setVisible(false) end
    if window.btnNudgeN_Main then window.btnNudgeN_Main:setVisible(false) end
    if window.btnNudgeS_Main then window.btnNudgeS_Main:setVisible(false) end
    if window.btnScaleW_Main then window.btnScaleW_Main:setVisible(false) end
    if window.btnScaleE_Main then window.btnScaleE_Main:setVisible(false) end
    if window.btnScaleN_Main then window.btnScaleN_Main:setVisible(false) end
    if window.btnScaleS_Main then window.btnScaleS_Main:setVisible(false) end
    if window.btnScaleW_Inn_Main then window.btnScaleW_Inn_Main:setVisible(false) end
    if window.btnScaleE_Inn_Main then window.btnScaleE_Inn_Main:setVisible(false) end
    if window.btnScaleN_Inn_Main then window.btnScaleN_Inn_Main:setVisible(false) end
    if window.btnScaleS_Inn_Main then window.btnScaleS_Inn_Main:setVisible(false) end
end

function RealBaseUI.Open(player, colonyId, context)
    if DC_ZoneWindow and DC_ZoneWindow.OpenWithOptions then
        return DC_ZoneWindow.OpenWithOptions(player, colonyId, {
            mode = "realbase",
            realBaseContext = context
        })
    end
    return nil
end

return RealBaseUI

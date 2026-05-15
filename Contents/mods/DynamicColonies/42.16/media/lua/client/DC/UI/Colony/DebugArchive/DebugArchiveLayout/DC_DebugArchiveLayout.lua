DC_DebugArchiveLayout = DC_DebugArchiveLayout or {}

local Layout = DC_DebugArchiveLayout

function Layout.RefreshRichText(panel)
    if not panel then
        return
    end

    panel:paginate()
    if panel.vscroll then
        panel.vscroll:setHeight(panel:getHeight())
    end
end

function Layout.CreateChildren(window)
    ISCollapsableWindow.createChildren(window)

    local th = window:titleBarHeight()
    local pad = 10
    local topY = th + pad
    local sectionY = topY + 34
    local listY = sectionY + 36
    local footerH = 34
    local listWidth = 250
    local rightX = listWidth + (pad * 2)
    local rightWidth = window.width - rightX - pad
    local detailHeight = window.height - listY - footerH - (pad * 2)

    window.btnRefresh = ISButton:new(10, topY, 100, 24, "Refresh", window, window.onRefreshClicked)
    window.btnRefresh:initialise()
    window:addChild(window.btnRefresh)

    local buttonX = 10
    local buttonWidth = 96
    local buttonGap = 8
    local sections = {
        { id = "Overview", label = "Overview" },
        { id = "Workers", label = "Workers" },
        { id = "Items", label = "Items" },
        { id = "Buildings", label = "Buildings" },
        { id = "Raw", label = "Raw" },
    }

    window.sectionButtons = {}
    for _, definition in ipairs(sections) do
        local button = ISButton:new(buttonX, sectionY, buttonWidth, 24, definition.label, window, window.onSectionClicked)
        button:initialise()
        button.sectionID = definition.id
        window:addChild(button)
        window.sectionButtons[definition.id] = button
        buttonX = buttonX + buttonWidth + buttonGap
    end

    window.colonyList = ISScrollingListBox:new(10, listY, listWidth, detailHeight)
    window.colonyList:initialise()
    window.colonyList:instantiate()
    window.colonyList.target = window
    window.colonyList.onMouseDown = function(list, x, y)
        local result = ISScrollingListBox.onMouseDown(list, x, y)
        local row = tonumber(list.selected) or -1
        local item = row > 0 and list.items[row] or nil
        if item and item.item then
            list.target:onColonySelected(item.item)
        end
        return result
    end
    window:addChild(window.colonyList)

    window.detailText = ISRichTextPanel:new(rightX, listY, rightWidth, detailHeight)
    window.detailText:initialise()
    window.detailText.backgroundColor = { r = 0, g = 0, b = 0, a = 0.12 }
    window.detailText.borderColor = { r = 1, g = 1, b = 1, a = 0.08 }
    window.detailText.autosetheight = false
    window.detailText.clip = true
    window.detailText:addScrollBars()
    window:addChild(window.detailText)

    window.statusText = ISRichTextPanel:new(rightX, window.height - footerH - pad, rightWidth, footerH)
    window.statusText:initialise()
    window.statusText.backgroundColor = { r = 0, g = 0, b = 0, a = 0 }
    window.statusText.borderColor = { r = 0, g = 0, b = 0, a = 0 }
    window:addChild(window.statusText)
end

return Layout

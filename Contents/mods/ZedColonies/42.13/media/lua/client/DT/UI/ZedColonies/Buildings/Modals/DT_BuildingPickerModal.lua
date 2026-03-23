require "ISUI/ISCollapsableWindow"
require "ISUI/ISPanel"
require "ISUI/ISRichTextPanel"
require "ISUI/ISButton"
require "DT/UI/ZedColonies/Buildings/Utils/DT_BuildingsUIUtils"

local PickerCarousel = ISPanel:derive("DT_BuildingPickerModal_Carousel")

function PickerCarousel:initialise()
    ISPanel.initialise(self)
end

function PickerCarousel:getCardMetrics()
    return {
        width = 156,
        height = self.height - 26,
        gap = 16,
        pad = 10
    }
end

function PickerCarousel:getTotalContentWidth()
    local metrics = self:getCardMetrics()
    local count = #(self.options or {})
    if count <= 0 then
        return 0
    end
    return (count * metrics.width) + ((count - 1) * metrics.gap) + (metrics.pad * 2)
end

function PickerCarousel:clampScroll()
    local maxScroll = math.max(0, self:getTotalContentWidth() - self.width)
    self.scrollX = math.max(0, math.min(math.floor(self.scrollX or 0), maxScroll))
end

function PickerCarousel:setOptions(options)
    self.options = options or {}
    self.scrollX = 0
    self.selectedIndex = math.min(math.max(1, self.selectedIndex or 1), math.max(1, #self.options))
    self:clampScroll()
end

function PickerCarousel:setSelectedIndex(index)
    if not self.options or not self.options[index] then
        return
    end
    self.selectedIndex = index
    if self.onSelectionChanged then
        self.onSelectionChanged(index, self.options[index])
    end
end

function PickerCarousel:scrollBy(delta)
    self.scrollX = math.floor((self.scrollX or 0) + delta)
    self:clampScroll()
end

function PickerCarousel:onMouseWheel(del)
    self:scrollBy(-(del or 0) * 34)
    return true
end

function PickerCarousel:onMouseDown(x, y)
    local metrics = self:getCardMetrics()
    local localX = x + (self.scrollX or 0) - metrics.pad
    local stride = metrics.width + metrics.gap
    if localX < 0 or y < 8 or y > metrics.height then
        return false
    end

    local index = math.floor(localX / stride) + 1
    local offsetWithin = localX % stride
    if self.options and self.options[index] and offsetWithin <= metrics.width then
        self:setSelectedIndex(index)
        return true
    end
    return false
end

function PickerCarousel:prerender()
    ISPanel.prerender(self)
    self:drawText(tostring(self.headerText or "Browse Buildings"), 10, 6, 1, 1, 1, 1, UIFont.Medium)
    self:drawText("Mouse wheel or arrows to scroll", self.width - 190, 8, 0.72, 0.72, 0.72, 1, UIFont.Small)
end

function PickerCarousel:render()
    ISPanel.render(self)

    local metrics = self:getCardMetrics()
    local startX = metrics.pad - (self.scrollX or 0)
    local cardY = 24

    for index, option in ipairs(self.options or {}) do
        local cardX = startX + ((index - 1) * (metrics.width + metrics.gap))
        if cardX + metrics.width >= 0 and cardX <= self.width then
            local selected = index == self.selectedIndex
            local bg = selected and { r = 0.22, g = 0.22, b = 0.18, a = 0.96 } or { r = 0.08, g = 0.08, b = 0.08, a = 0.96 }
            local border = selected and DT_BuildingsUIUtils.Colors.selectedBorder or DT_BuildingsUIUtils.Colors.defaultBorder
            self:drawRect(cardX, cardY, metrics.width, metrics.height, bg.a, bg.r, bg.g, bg.b)
            self:drawRectBorder(cardX, cardY, metrics.width, metrics.height, border.a, border.r, border.g, border.b)

            local texture = DT_BuildingsUIUtils.GetTexture(option.iconPath)
            if texture then
                self:drawTextureScaledAspect(texture, cardX + 18, cardY + 14, metrics.width - 36, 84, 1, 1, 1, option.enabled == true and 1 or 0.45)
            end

            self:drawTextCentre(
                tostring(option.displayName or option.buildingType or "Building"),
                cardX + (metrics.width / 2),
                cardY + 108,
                option.enabled == true and 1 or 0.6,
                option.enabled == true and 1 or 0.6,
                option.enabled == true and 1 or 0.6,
                1,
                UIFont.Medium
            )

            local subtitle = DT_BuildingsUIUtils.GetOptionStatusLabel and DT_BuildingsUIUtils.GetOptionStatusLabel(option)
                or (option.enabled == true and "Available" or "Unavailable")
            self:drawTextCentre(subtitle, cardX + (metrics.width / 2), cardY + 132, 0.72, 0.72, 0.72, 1, UIFont.Small)
        end
    end
end

function PickerCarousel:new(x, y, width, height)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.backgroundColor = { r = 0, g = 0, b = 0, a = 0.2 }
    o.borderColor = { r = 1, g = 1, b = 1, a = 0.08 }
    o.scrollX = 0
    o.selectedIndex = 1
    o.options = {}
    return o
end

DT_BuildingPickerModal = ISCollapsableWindow:derive("DT_BuildingPickerModal")
DT_BuildingPickerModal.instance = DT_BuildingPickerModal.instance or nil

function DT_BuildingPickerModal:initialise()
    ISCollapsableWindow.initialise(self)
    self:setResizable(false)
end

function DT_BuildingPickerModal:getSelectedOption()
    return self.options and self.options[self.selectedIndex or 1] or nil
end

function DT_BuildingPickerModal:updateDetailText()
    local option = self:getSelectedOption()
    if self.detailText then
        self.detailText:setText(DT_BuildingsUIUtils.BuildOptionDetailText(option))
        self.detailText:paginate()
    end
    if self.btnConfirm then
        self.btnConfirm:setEnable(option and option.enabled == true)
    end
end

function DT_BuildingPickerModal:scrollCards(delta)
    if self.carousel then
        self.carousel:scrollBy(delta)
    end
end

function DT_BuildingPickerModal:createChildren()
    ISCollapsableWindow.createChildren(self)
    local th = self:titleBarHeight()

    self.carousel = PickerCarousel:new(10, th + 10, self.width - 20, 206)
    self.carousel:initialise()
    self.carousel:instantiate()
    self.carousel.onSelectionChanged = function(index)
        self.selectedIndex = index
        self:updateDetailText()
    end
    self.carousel.headerText = tostring(self.carouselHeaderText or "Browse Buildings")
    self.carousel:setOptions(self.options or {})
    self:addChild(self.carousel)

    self.btnScrollLeft = ISButton:new(10, th + 224, 34, 24, "<", self, self.onScrollLeft)
    self.btnScrollLeft:initialise()
    self:addChild(self.btnScrollLeft)

    self.btnScrollRight = ISButton:new(self.width - 44, th + 224, 34, 24, ">", self, self.onScrollRight)
    self.btnScrollRight:initialise()
    self:addChild(self.btnScrollRight)

    self.detailText = ISRichTextPanel:new(10, th + 258, self.width - 20, self.height - th - 302)
    self.detailText:initialise()
    self.detailText:instantiate()
    self.detailText.backgroundColor = { r = 0, g = 0, b = 0, a = 0.16 }
    self.detailText.borderColor = { r = 1, g = 1, b = 1, a = 0.05 }
    self.detailText.clip = true
    self.detailText.autosetheight = false
    self.detailText:addScrollBars()
    self:addChild(self.detailText)

    self.btnConfirm = ISButton:new(10, self.height - 34, 90, 24, tostring(self.confirmLabel or "Choose"), self, self.onConfirmClicked)
    self.btnConfirm:initialise()
    self:addChild(self.btnConfirm)

    self.btnCancel = ISButton:new(self.width - 100, self.height - 34, 90, 24, "Cancel", self, self.onCancelClicked)
    self.btnCancel:initialise()
    self:addChild(self.btnCancel)

    self.selectedIndex = math.min(math.max(1, self.selectedIndex or 1), math.max(1, #(self.options or {})))
    self.carousel:setSelectedIndex(self.selectedIndex)
    self:updateDetailText()
end

function DT_BuildingPickerModal:onScrollLeft()
    self:scrollCards(-180)
end

function DT_BuildingPickerModal:onScrollRight()
    self:scrollCards(180)
end

function DT_BuildingPickerModal:onConfirmClicked()
    local option = self:getSelectedOption()
    if option and option.enabled == true and self.onConfirmCallback then
        self.onConfirmCallback(option)
    end
    self:close()
end

function DT_BuildingPickerModal:onCancelClicked()
    self:close()
end

function DT_BuildingPickerModal:close()
    self:setVisible(false)
    self:removeFromUIManager()
    if DT_BuildingPickerModal.instance == self then
        DT_BuildingPickerModal.instance = nil
    end
end

function DT_BuildingPickerModal:new(x, y, width, height)
    local o = ISCollapsableWindow:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    return o
end

function DT_BuildingPickerModal.Open(args)
    args = args or {}
    if DT_BuildingPickerModal.instance then
        DT_BuildingPickerModal.instance:close()
    end

    local width = 760
    local height = 560
    local x = (getCore():getScreenWidth() - width) / 2
    local y = (getCore():getScreenHeight() - height) / 2
    local modal = DT_BuildingPickerModal:new(x, y, width, height)
    modal.title = tostring(args.title or "Choose Building")
    modal.options = args.options or {}
    modal.selectedIndex = 1
    modal.carouselHeaderText = tostring(args.carouselHeaderText or "Browse Buildings")
    modal.confirmLabel = tostring(args.confirmLabel or "Choose")
    modal.onConfirmCallback = args.onConfirm
    modal:initialise()
    modal:instantiate()
    modal:addToUIManager()
    modal:bringToTop()
    DT_BuildingPickerModal.instance = modal
    return modal
end

return DT_BuildingPickerModal

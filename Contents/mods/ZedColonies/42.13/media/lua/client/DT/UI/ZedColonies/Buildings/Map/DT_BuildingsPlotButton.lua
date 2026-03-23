require "ISUI/ISButton"
require "DT/UI/ZedColonies/Buildings/Utils/DT_BuildingsUIUtils"

DT_BuildingsPlotButton = ISButton:derive("DT_BuildingsPlotButton")

function DT_BuildingsPlotButton:applyPlot(plot, selected)
    self.plot = plot
    local color = DT_BuildingsUIUtils.GetPlotColor(plot)
    self.backgroundColor = { r = color.r, g = color.g, b = color.b, a = color.a }
    self.backgroundColorMouseOver = { r = color.r + 0.08, g = color.g + 0.08, b = color.b + 0.08, a = color.a }
    local border = selected == true and DT_BuildingsUIUtils.Colors.selectedBorder or DT_BuildingsUIUtils.Colors.defaultBorder
    self.borderColor = { r = border.r, g = border.g, b = border.b, a = border.a }
    self:setEnable(plot and plot.state ~= "Locked")
    self:setTitle(DT_BuildingsUIUtils.GetPlotTitle(plot))
end

function DT_BuildingsPlotButton:render()
    ISButton.render(self)
    if not self.plot then
        return
    end

    local imageX = 10
    local imageY = 10
    local imageW = self.width - 20
    local imageH = self.height - 28
    local texturePath = DT_BuildingsUIUtils.GetPlotTexturePath(self.plot)
    local texture = DT_BuildingsUIUtils.GetTexture(texturePath)
    if texture then
        self:drawTextureScaledAspect(texture, imageX, imageY, imageW, imageH, 0.85, 1, 1, 1)
    end

    if self.plot.project and tostring(self.plot.project.materialState or "") == "Stalled" then
        self:drawRect(imageX, imageY, imageW, imageH, 0.42, 0.95, 0.78, 0.18)
        self:drawRect(imageX, imageY + imageH - 12, imageW, 12, 0.58, 0.95, 0.72, 0.12)
    elseif self.plot.project then
        local ratio = math.max(0, math.min(1, tonumber(self.plot.project.progressRatio) or 0))
        local remainingWidth = math.floor(imageW * (1 - ratio))
        if remainingWidth > 0 then
            self:drawRect(imageX, imageY, remainingWidth, imageH, 0.5, 0.18, 0.72, 0.22)
            self:drawRect(imageX, imageY + imageH - 12, remainingWidth, 12, 0.62, 0.12, 0.48, 0.16)
            local edgeX = imageX + remainingWidth - 2
            if edgeX >= imageX then
                self:drawRect(edgeX, imageY, 2, imageH, 0.82, 0.45, 1, 0.48)
            end
        end
    end

    if self.plot.kind == "HQOnly" and not self.plot.building and not self.plot.project then
        self:drawTextCentre("HQ Lot", self.width / 2, self.height / 2 - 8, 1, 0.92, 0.55, 1, UIFont.Small)
    elseif self.plot.state == "Locked" then
        self:drawTextCentre("Locked", self.width / 2, self.height / 2 - 8, 0.45, 0.45, 0.45, 1, UIFont.Small)
    end

    if self.plot.project then
        if tostring(self.plot.project.materialState or "") == "Stalled" then
            self:drawTextCentre("Stalled", self.width / 2, self.height - 22, 0.26, 0.18, 0.05, 1, UIFont.Small)
        else
            local ratio = math.max(0, math.min(1, tonumber(self.plot.project.progressRatio) or 0))
            local percent = math.floor((ratio * 100) + 0.5)
            self:drawTextCentre(tostring(percent) .. "%", self.width / 2, self.height - 22, 0.2, 0.12, 0.05, 1, UIFont.Small)
        end
    elseif self.plot.building and self.plot.building.level then
        self:drawTextCentre("Lv " .. tostring(self.plot.building.level), self.width / 2, self.height - 22, 1, 1, 1, 1, UIFont.Small)
    end
end

function DT_BuildingsPlotButton:new(x, y, width, height, title, target, onclick)
    local o = ISButton:new(x, y, width, height, title or "", target, onclick)
    setmetatable(o, self)
    self.__index = self
    return o
end

return DT_BuildingsPlotButton

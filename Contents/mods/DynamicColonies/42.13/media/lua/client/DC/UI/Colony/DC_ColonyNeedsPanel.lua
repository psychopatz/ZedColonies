require "DC/UI/Colony/MainWindow/MainWindowCore/DC_MainWindowCore_Bootstrap"
require "DC/UI/Colony/MainWindow/MainWindowCore/DC_MainWindowCore_Formatters"
require "DC/UI/Colony/MainWindow/MainWindowCore/DC_MainWindowCore_WorkerPresentation"
require "ISUI/ISPanel"
require "DC/Common/Colony/ColonyEnergy/DC_ColonyEnergy"

DC_ColonyNeedsPanel = ISPanel:derive("DC_ColonyNeedsPanel")

local Internal = DC_MainWindow and DC_MainWindow.Internal or {}

local function isFunction(value)
    return type(value) == "function"
end

local function getJobDisplayName(worker)
    if isFunction(Internal.getJobDisplayName) then
        return Internal.getJobDisplayName(worker)
    end
    return tostring(worker and (worker.jobType or worker.profession) or "Unassigned")
end

local function getWorkerStateLabel(worker)
    if isFunction(Internal.getWorkerStateLabel) then
        return Internal.getWorkerStateLabel(worker)
    end
    return tostring(worker and worker.state or "Idle")
end

local function getPortraitTexture(subject)
    if not subject then
        return nil
    end

    local archetype = tostring(subject.archetypeID or "General")
    local gender = subject.isFemale and "Female" or "Male"
    local seed = tonumber(subject.identitySeed) or 1
    local portraitID = 1
    local pathFolder = "media/ui/Portraits/" .. archetype .. "/" .. gender .. "/"

    if DynamicTrading and DynamicTrading.Portraits then
        if DynamicTrading.Portraits.GetMappedID then
            portraitID = DynamicTrading.Portraits.GetMappedID(archetype, gender, seed)
        end
        if DynamicTrading.Portraits.GetPathFolder then
            pathFolder = DynamicTrading.Portraits.GetPathFolder(archetype, gender)
        end
    end

    return getTexture(pathFolder .. tostring(portraitID) .. ".png") or getTexture("media/ui/Portraits/General/" .. gender .. "/1.png")
end

local function buildNeedsData(worker)
    if not worker then
        return nil
    end

    local needs = {}
    
    if DC_Colony and type(DC_Colony.NeedProviders) == "table" then
        for _, provider in ipairs(DC_Colony.NeedProviders) do
            if provider and provider.label and isFunction(provider.GetBarData) then
                local data = provider.GetBarData(worker)
                if data then
                    needs[#needs + 1] = {
                        label = provider.label,
                        color = provider.color or { r = 0.55, g = 0.55, b = 0.55 },
                        data = data
                    }
                end
            end
        end
    end

    return needs
end

function DC_ColonyNeedsPanel:new(x, y, width, height)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.backgroundColor = { r = 0, g = 0, b = 0, a = 0.22 }
    o.borderColor = { r = 1, g = 1, b = 1, a = 0.08 }
    o.subject = nil
    o.loading = false
    o.headerHeight = 120
    return o
end

function DC_ColonyNeedsPanel:initialise()
    ISPanel.initialise(self)
end

function DC_ColonyNeedsPanel:setWorkerData(worker)
    if not worker then
        self.subject = nil
        self.loading = false
        return
    end

    self.subject = {
        workerID = worker.workerID,
        name = worker.name or worker.workerID,
        archetypeID = worker.archetypeID or worker.profession or "General",
        jobType = getJobDisplayName(worker),
        state = getWorkerStateLabel(worker),
        isFemale = worker.isFemale,
        identitySeed = worker.identitySeed,
        needs = buildNeedsData(worker)
    }
    self.subject.portraitTex = getPortraitTexture(self.subject)
    self.loading = false
end

function DC_ColonyNeedsPanel:drawNeedRow(entry, x, y, width, height)
    local data = entry and entry.data or nil
    local color = entry and entry.color or { r = 0.55, g = 0.55, b = 0.55 }
    local fillRatio = data and data.fillRatio or 0
    local barX = x + 120
    local barY = y + 3
    local barWidth = width - 124
    local barHeight = 16
    local summaryText = data and data.summaryText or "-"
    local captionText = data and data.captionText or ""
    local isPlaceholder = data and data.placeholder == true
    local fillWidth = math.floor((barWidth - 4) * math.max(0, math.min(1, fillRatio)))

    self:drawText(entry.label, x + 4, y + 1, 0.93, 0.93, 0.93, 1, UIFont.Small)
    self:drawTextRight(summaryText, x + width, y + 1, isPlaceholder and 0.60 or 0.82, isPlaceholder and 0.60 or 0.82, isPlaceholder and 0.60 or 0.82, 1, UIFont.Small)

    self:drawRect(barX, barY, barWidth, barHeight, 0.35, 0.10, 0.10, 0.10)
    self:drawRectBorder(barX, barY, barWidth, barHeight, 0.18, 1, 1, 1)
    if fillWidth > 0 then
        self:drawRect(
            barX + 2,
            barY + 2,
            fillWidth,
            barHeight - 4,
            isPlaceholder and 0.35 or 0.92,
            color.r,
            color.g,
            color.b
        )
    end

    self:drawText(captionText, x + 4, y + 22, isPlaceholder and 0.48 or 0.68, isPlaceholder and 0.48 or 0.68, isPlaceholder and 0.48 or 0.68, 1, UIFont.Small)
end

function DC_ColonyNeedsPanel:prerender()
    ISPanel.prerender(self)

    if not self.subject then
        self:drawTextCentre("No character selected.", self.width / 2, self.height / 2 - 10, 0.62, 0.62, 0.62, 1, UIFont.Medium)
        return
    end

    local subject = self.subject
    local portraitSize = 88
    local pad = 14

    self:drawRect(pad, pad, portraitSize, portraitSize, 0.08, 1, 1, 1)
    if subject.portraitTex then
        self:drawTextureScaled(subject.portraitTex, pad + 2, pad + 2, portraitSize - 4, portraitSize - 4, 1, 1, 1, 1)
    end
    self:drawRectBorder(pad, pad, portraitSize, portraitSize, 0.18, 1, 1, 1)

    local textX = pad + portraitSize + 16
    self:drawText(tostring(subject.name or "Worker"), textX, pad + 4, 0.96, 0.96, 0.96, 1, UIFont.Large)
    self:drawText(
        tostring(subject.archetypeID or "General") .. " | " .. tostring(subject.jobType or "Unassigned"),
        textX,
        pad + 32,
        0.70,
        0.78,
        0.94,
        1,
        UIFont.Small
    )
    self:drawText("Current State: " .. tostring(subject.state or "Idle"), textX, pad + 52, 0.88, 0.76, 0.28, 1, UIFont.Small)
    self:drawText("Energy and future need tracks", textX, pad + 72, 0.72, 0.72, 0.72, 1, UIFont.Small)

    local titleY = self.headerHeight
    self:drawText("Needs", pad, titleY, 1, 1, 1, 1, UIFont.Medium)

    if self.loading then
        self:drawTextCentre("Loading character sheet...", self.width / 2, titleY + 42, 0.72, 0.72, 0.72, 1, UIFont.Medium)
        return
    end

    local rowY = titleY + 28
    local rowHeight = 42
    local rowGap = 8
    local rowWidth = self.width - (pad * 2)
    for _, entry in ipairs(subject.needs or {}) do
        self:drawNeedRow(entry, pad, rowY, rowWidth, rowHeight)
        rowY = rowY + rowHeight + rowGap
    end
end

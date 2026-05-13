local Panel = DC_ColonySkillPanel
local Internal = Panel.Internal
local FlavorText = Internal.FlavorText or {}

function Panel:drawMasteryIcon(x, y)
    self:drawRect(x + 5, y + 8, 4, 8, 0.95, 0.94, 0.46, 0.14)
    self:drawRect(x + 3, y + 12, 8, 6, 0.95, 0.88, 0.30, 0.08)
    self:drawRect(x + 6, y + 4, 3, 5, 0.95, 1.00, 0.82, 0.34)
end

function Panel:drawSkillRow(subject, skill, x, y, width, height)
    local barX = x + 190
    local barWidth = width - 200
    local barHeight = 9
    local barY = y + 7
    local level = math.floor(tonumber(skill.level) or 0)
    local baselineLevel = Internal.getBaselineLevel(subject, skill)
    local totalLevel = Internal.clamp(level, 0, 20)
    local baseLevel = Internal.clamp(baselineLevel, 0, totalLevel)
    local baseRatio = baseLevel / 20
    local totalRatio = totalLevel / 20
    local hasMasteryCap = skill.perfectCap == true or (tonumber(skill.cap) or 0) >= 20
    local displayDash = level <= 0 and not hasMasteryCap
    local displayText = displayDash and "-" or tostring(level)
    local baseBarColor = { r = 0.42, g = 0.44, b = 0.47 }
    local addedBarColor = { r = 0.44, g = 0.78, b = 0.98 }
    local valueColor = hasMasteryCap and { r = 0.95, g = 0.86, b = 0.35 }
        or { r = 0.88, g = 0.88, b = 0.88 }
    local remainingXPLabel = Internal.getRemainingXPLabel(skill)

    self:drawText(skill.label, x + 4, y + 4, 0.92, 0.92, 0.92, 1, UIFont.Small)

    if hasMasteryCap then
        self:drawMasteryIcon(x + 138, y + 1)
    end

    self:drawTextRight(displayText, x + 182, y + 4, valueColor.r, valueColor.g, valueColor.b, 1, UIFont.Small)

    if not displayDash then
        self:drawRect(barX, barY, barWidth, barHeight, 0.42, 0.16, 0.17, 0.18)
        local baseFillWidth = math.floor(barWidth * baseRatio)
        local totalFillWidth = math.floor(barWidth * totalRatio)
        local addedFillWidth = math.max(0, totalFillWidth - baseFillWidth)
        if baseFillWidth > 0 then
            self:drawRect(barX, barY, baseFillWidth, barHeight, 0.92, baseBarColor.r, baseBarColor.g, baseBarColor.b)
        end
        if addedFillWidth > 0 then
            self:drawRect(barX + baseFillWidth, barY, addedFillWidth, barHeight, 0.95, addedBarColor.r, addedBarColor.g, addedBarColor.b)
        end
    end

    self:drawTextRight(remainingXPLabel, x + width - 4, y + 18, 0.70, 0.78, 0.94, 1, UIFont.Small)
end

function Panel:prerender()
    ISPanel.prerender(self)

    if not self.subject then
        self:drawTextCentre(tostring(FlavorText.noCharacterSelected or "No character selected."), self.width / 2, self.height / 2 - 10, 0.62, 0.62, 0.62, 1, UIFont.Medium)
        return
    end

    local subject = self.subject
    local portraitSize = 88
    local pad = 14
    local primarySkill = Internal.getPrimarySkill(subject)
    local accentText = primarySkill and (primarySkill.label .. " " .. tostring(primarySkill.level)) or tostring(FlavorText.noSpecialty or "No specialty")

    self:drawRect(pad, pad, portraitSize, portraitSize, 0.08, 1, 1, 1)
    if subject.portraitTex then
        self:drawTextureScaled(subject.portraitTex, pad + 2, pad + 2, portraitSize - 4, portraitSize - 4, 1, 1, 1, 1)
    end
    self:drawRectBorder(pad, pad, portraitSize, portraitSize, 0.18, 1, 1, 1)

    local textX = pad + portraitSize + 16
    self:drawText(tostring(subject.name or FlavorText.unknownName or "Unknown"), textX, pad + 4, 0.96, 0.96, 0.96, 1, UIFont.Large)
    self:drawText(
        tostring(subject.archetypeID or "General") .. " | " .. tostring(subject.jobType or FlavorText.unassignedJob or "Unassigned"),
        textX,
        pad + 32,
        0.70,
        0.78,
        0.94,
        1,
        UIFont.Small
    )
    self:drawText(tostring(FlavorText.specialtyPrefix or "Specialty: ") .. accentText, textX, pad + 52, 0.88, 0.76, 0.28, 1, UIFont.Small)
    self:drawText(
        subject.previewOnly and tostring(FlavorText.seedPreviewOnly or "Seed preview only") or tostring(FlavorText.persistentWorkerSkills or "Persistent recruited worker skills"),
        textX,
        pad + 72,
        0.72,
        0.72,
        0.72,
        1,
        UIFont.Small
    )

    local titleY = self.headerHeight
    self:drawText(tostring(FlavorText.skillsTitle or "Skills"), pad, titleY, 1, 1, 1, 1, UIFont.Medium)

    if self.loading then
        self:drawTextCentre(tostring(FlavorText.loadingCharacterSheet or "Loading character sheet..."), self.width / 2, titleY + 42, 0.72, 0.72, 0.72, 1, UIFont.Medium)
        return
    end

    local rowY = titleY + 26
    local rowHeight = 32
    local rowGap = 4
    local rowWidth = self.width - (pad * 2)
    for _, skillID in ipairs(Internal.DISPLAY_ORDER or {}) do
        local skill = subject.skills and subject.skills[skillID] or nil
        if skill then
            self:drawSkillRow(subject, skill, pad, rowY, rowWidth, rowHeight)
        end
        rowY = rowY + rowHeight + rowGap
    end
end

return Panel
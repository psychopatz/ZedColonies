require "ISUI/ISPanel"
require "DC/Common/Colony/ColonyConfig/DC_ColonyConfig"
require "DC/Common/Colony/ColonySkills/DC_ColonySkills"
require "DC/UI/Colony/MainWindow/MainWindowCore/DC_MainWindowCore_Bootstrap"
require "DC/UI/Colony/MainWindow/MainWindowCore/DC_MainWindowCore_WorkerPresentation"

DC_ColonySkillPanel = ISPanel:derive("DC_ColonySkillPanel")

local Internal = DC_MainWindow and DC_MainWindow.Internal or {}

local DISPLAY_ORDER = {
    "Shooting",
    "Melee",
    "Construction",
    "Mining",
    "Cooking",
    "Plants",
    "Animals",
    "Crafting",
    "Maintenance",
    "Medical",
    "Social",
    "Intellectual"
}

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

local function isFunction(value)
    return type(value) == "function"
end

local function getJobDisplayName(worker)
    if isFunction(Internal.getJobDisplayName) then
        return Internal.getJobDisplayName(worker)
    end
    return tostring(worker and (worker.jobType or worker.profession) or "Unassigned")
end

local function getPrimarySkill(subject)
    for _, skillID in ipairs(DISPLAY_ORDER) do
        local skill = subject and subject.skills and subject.skills[skillID] or nil
        if skill and skill.primary then
            return skill
        end
    end

    local bestSkill = nil
    for _, skillID in ipairs(DISPLAY_ORDER) do
        local skill = subject and subject.skills and subject.skills[skillID] or nil
        if skill and (not bestSkill or (tonumber(skill.level) or 0) > (tonumber(bestSkill.level) or 0)) then
            bestSkill = skill
        end
    end
    return bestSkill
end

function DC_ColonySkillPanel:new(x, y, width, height)
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

function DC_ColonySkillPanel:initialise()
    ISPanel.initialise(self)
end

function DC_ColonySkillPanel:setWorkerData(worker)
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
        isFemale = worker.isFemale,
        identitySeed = worker.identitySeed,
        skills = worker.skills,
        previewOnly = false,
        loading = type(worker.skills) ~= "table"
    }
    self.subject.portraitTex = getPortraitTexture(self.subject)
    self.loading = self.subject.loading == true
end

function DC_ColonySkillPanel:setPreviewSubject(subject)
    if not subject then
        self.subject = nil
        self.loading = false
        return
    end

    self.subject = {
        name = subject.name or "Unknown",
        archetypeID = subject.archetypeID or "General",
        jobType = subject.jobType,
        isFemale = subject.isFemale,
        identitySeed = subject.identitySeed,
        skills = DC_Colony.Skills.BuildPreviewSkillSnapshot(subject.archetypeID, subject.identitySeed),
        previewOnly = true,
        loading = false
    }
    self.subject.portraitTex = getPortraitTexture(self.subject)
    self.loading = false
end

function DC_ColonySkillPanel:drawMasteryIcon(x, y)
    self:drawRect(x + 5, y + 8, 4, 8, 0.95, 0.94, 0.46, 0.14)
    self:drawRect(x + 3, y + 12, 8, 6, 0.95, 0.88, 0.30, 0.08)
    self:drawRect(x + 6, y + 4, 3, 5, 0.95, 1.00, 0.82, 0.34)
end

function DC_ColonySkillPanel:drawSkillRow(skill, x, y, width, height)
    local barX = x + 190
    local barWidth = width - 200
    local barHeight = height - 10
    local barY = y + 5
    local level = math.floor(tonumber(skill.level) or 0)
    local hasMasteryCap = skill.perfectCap == true or (tonumber(skill.cap) or 0) >= 20
    local displayDash = level <= 0 and not hasMasteryCap
    local displayText = displayDash and "-" or tostring(level)
    local barRatio = math.max(0, math.min(1, level / 20))
    local barColor = hasMasteryCap and { r = 0.39, g = 0.56, b = 0.31 }
        or { r = 0.24, g = 0.26, b = 0.28 }
    local valueColor = hasMasteryCap and { r = 0.95, g = 0.86, b = 0.35 }
        or { r = 0.88, g = 0.88, b = 0.88 }

    self:drawText(skill.label, x + 4, y + 5, 0.92, 0.92, 0.92, 1, UIFont.Small)

    if hasMasteryCap then
        self:drawMasteryIcon(x + 138, y + 1)
    end

    self:drawTextRight(displayText, x + 182, y + 5, valueColor.r, valueColor.g, valueColor.b, 1, UIFont.Small)

    if not displayDash then
        self:drawRect(barX, barY, barWidth, barHeight, 0.42, 0.16, 0.17, 0.18)
        local fillWidth = math.floor(barWidth * barRatio)
        if fillWidth > 0 then
            self:drawRect(barX, barY, fillWidth, barHeight, 0.92, barColor.r, barColor.g, barColor.b)
        end
    end
end

function DC_ColonySkillPanel:prerender()
    ISPanel.prerender(self)

    if not self.subject then
        self:drawTextCentre("No character selected.", self.width / 2, self.height / 2 - 10, 0.62, 0.62, 0.62, 1, UIFont.Medium)
        return
    end

    local subject = self.subject
    local portraitSize = 88
    local pad = 14
    local primarySkill = getPrimarySkill(subject)
    local accentText = primarySkill and (primarySkill.label .. " " .. tostring(primarySkill.level)) or "No specialty"

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
    self:drawText("Specialty: " .. accentText, textX, pad + 52, 0.88, 0.76, 0.28, 1, UIFont.Small)
    self:drawText(
        subject.previewOnly and "Seed preview only" or "Persistent recruited worker skills",
        textX,
        pad + 72,
        0.72,
        0.72,
        0.72,
        1,
        UIFont.Small
    )

    local titleY = self.headerHeight
    self:drawText("Skills", pad, titleY, 1, 1, 1, 1, UIFont.Medium)

    if self.loading then
        self:drawTextCentre("Loading character sheet...", self.width / 2, titleY + 42, 0.72, 0.72, 0.72, 1, UIFont.Medium)
        return
    end

    local rowY = titleY + 26
    local rowHeight = 24
    local rowGap = 3
    local rowWidth = self.width - (pad * 2)
    for _, skillID in ipairs(DISPLAY_ORDER) do
        local skill = subject.skills and subject.skills[skillID] or nil
        if skill then
            self:drawSkillRow(skill, pad, rowY, rowWidth, rowHeight)
        end
        rowY = rowY + rowHeight + rowGap
    end
end

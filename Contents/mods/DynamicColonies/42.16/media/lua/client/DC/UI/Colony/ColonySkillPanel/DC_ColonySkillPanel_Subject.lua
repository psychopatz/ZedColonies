local Panel = DC_ColonySkillPanel
local Internal = Panel.Internal
local FlavorText = Internal.FlavorText or {}

function Internal.getPortraitTexture(subject)
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

function Internal.getJobDisplayName(worker)
    if Internal.isFunction(Internal.MainWindow and Internal.MainWindow.getJobDisplayName) then
        return Internal.MainWindow.getJobDisplayName(worker)
    end
    return tostring(worker and (worker.jobType or worker.profession) or FlavorText.unassignedJob or "Unassigned")
end

function Internal.getBaseSkillSnapshot(archetypeID, identitySeed)
    if not (DC_Colony and DC_Colony.Skills and DC_Colony.Skills.BuildPreviewSkillSnapshot) then
        return nil
    end
    return DC_Colony.Skills.BuildPreviewSkillSnapshot(archetypeID, identitySeed)
end

function Panel:setWorkerData(worker)
    if not worker then
        self.subject = nil
        self.loading = false
        return
    end

    self.subject = {
        workerID = worker.workerID,
        name = worker.name or worker.workerID,
        archetypeID = worker.archetypeID or worker.profession or "General",
        jobType = Internal.getJobDisplayName(worker),
        isFemale = worker.isFemale,
        identitySeed = worker.identitySeed,
        skills = worker.skills,
        baseSkills = Internal.getBaseSkillSnapshot(worker.archetypeID or worker.profession or "General", worker.identitySeed),
        previewOnly = false,
        loading = type(worker.skills) ~= "table"
    }
    self.subject.portraitTex = Internal.getPortraitTexture(self.subject)
    self.loading = self.subject.loading == true
end

function Panel:setPreviewSubject(subject)
    if not subject then
        self.subject = nil
        self.loading = false
        return
    end

    self.subject = {
        name = subject.name or FlavorText.unknownName or "Unknown",
        archetypeID = subject.archetypeID or "General",
        jobType = subject.jobType,
        isFemale = subject.isFemale,
        identitySeed = subject.identitySeed,
        skills = DC_Colony.Skills.BuildPreviewSkillSnapshot(subject.archetypeID, subject.identitySeed),
        baseSkills = Internal.getBaseSkillSnapshot(subject.archetypeID, subject.identitySeed),
        previewOnly = true,
        loading = false
    }
    self.subject.portraitTex = Internal.getPortraitTexture(self.subject)
    self.loading = false
end

return Panel
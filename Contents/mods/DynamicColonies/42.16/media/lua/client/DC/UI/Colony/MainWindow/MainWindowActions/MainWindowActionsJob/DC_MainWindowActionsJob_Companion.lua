DC_MainWindow = DC_MainWindow or {}
DC_MainWindow.Internal = DC_MainWindow.Internal or {}

local JobActions = DC_MainWindow.Internal.JobActions or {}
local FlavorText = JobActions.FlavorText or {}

function JobActions.getCompanionCommander(worker)
    local companionData = type(worker and worker.companion) == "table" and worker.companion or {}
    local username = tostring(companionData.commanderUsername or worker and worker.companionCommanderUsername or "")
    return username ~= "" and username or nil
end

function JobActions.getCompanionLootConfig(worker)
    local companionInternal = DC_Colony and DC_Colony.Companion and DC_Colony.Companion.Internal or nil
    if companionInternal and companionInternal.GetCompanionLootConfig then
        return companionInternal.GetCompanionLootConfig(worker)
    end
    local companionData = type(worker and worker.companion) == "table" and worker.companion or {}
    return type(companionData.lootConfig) == "table" and companionData.lootConfig or nil
end

function JobActions.buildCompanionLootStatus(config)
    config = type(config) == "table" and config or {}
    local sourceCount = 0
    local sourceFlags = {
        config.includeLooseWorldItems ~= false,
        config.includeGroundContainers ~= false,
        config.includeFurnitureContainers ~= false,
        config.includeCorpseContainers ~= false,
        config.includeVehicleContainers ~= false,
    }
    for _, enabled in ipairs(sourceFlags) do
        if enabled then
            sourceCount = sourceCount + 1
        end
    end
    return string.format(
        tostring(FlavorText.companionLootStatus or "radius %s, %s sources"),
        tostring(config.radius or 10),
        tostring(sourceCount)
    )
end

function JobActions.addUniqueUsername(list, seen, username)
    username = tostring(username or "")
    if username == "" or seen[username] then
        return
    end
    seen[username] = true
    list[#list + 1] = username
end

function JobActions.getOwnedFactionStatus()
    if DC_System and DC_System.GetOwnedFactionStatus then
        local status = DC_System.GetOwnedFactionStatus()
        if type(status) == "table" then
            return status
        end
    end
    return DC_MainWindow.cachedOwnedFactionStatus
end

function JobActions.getCompanionTransferCandidates()
    local status = JobActions.getOwnedFactionStatus() or {}
    local faction = type(status.faction) == "table" and status.faction or {}
    local localUsername = JobActions.getLocalUsername()
    local candidates = {}
    local seen = {}

    JobActions.addUniqueUsername(candidates, seen, status.authorityOwner or status.ownerUsername or status.leaderUsername)
    JobActions.addUniqueUsername(candidates, seen, faction.authorityOwner or faction.ownerUsername or faction.leaderUsername)

    local memberSources = {
        status.memberUsernames,
        status.members,
        faction.memberUsernames,
        faction.members
    }
    for _, source in ipairs(memberSources) do
        if type(source) == "table" then
            for _, entry in ipairs(source) do
                if type(entry) == "table" then
                    JobActions.addUniqueUsername(candidates, seen, entry.username or entry.name)
                else
                    JobActions.addUniqueUsername(candidates, seen, entry)
                end
            end
        end
    end

    local filtered = {}
    for _, username in ipairs(candidates) do
        if username ~= localUsername then
            filtered[#filtered + 1] = username
        end
    end
    table.sort(filtered)
    return filtered
end

function DC_MainWindow:onCompanionCommand()
    local worker = JobActions.getSelectedWorkerForAction(self)
    if not worker or not worker.workerID then
        self:updateStatus(tostring(FlavorText.selectCompanionWorkerFirst or "Select a companion worker first."))
        return
    end

    local config = JobActions.getConfig()
    local normalizedJob = config.NormalizeJobType and config.NormalizeJobType(worker.jobType) or tostring(worker.jobType or "")
    if normalizedJob ~= tostring((config.JobTypes or {}).TravelCompanion or "TravelCompanion") then
        self:updateStatus(tostring(FlavorText.commandAuthorityTravelCompanionOnly or "Command authority only applies to Travel Companion workers."))
        return
    end
    if worker.jobEnabled ~= true then
        self:updateStatus(tostring(FlavorText.startCompanionDutyFirst or "Start companion duty before assigning command."))
        return
    end

    local commander = JobActions.getCompanionCommander(worker)
    local localUsername = JobActions.getLocalUsername()
    if commander == nil or commander ~= localUsername then
        self:sendColonyCommand("ClaimCompanionCommand", {
            workerID = worker.workerID
        })
        self:updateStatus(tostring(FlavorText.claimCompanionCommand or "Trying to claim companion command. Stand within 6 tiles of the companion."))
        return
    end

    local candidates = JobActions.getCompanionTransferCandidates()
    if #candidates == 0 then
        self:updateStatus(tostring(FlavorText.noTransferCandidates or "No other colony members are available for command transfer."))
        return
    end

    local x = (getMouseX and getMouseX()) or (self:getAbsoluteX() + 20)
    local y = (getMouseY and getMouseY()) or (self:getAbsoluteY() + 40)
    local menu = ISContextMenu.get(0, x, y)
    local heading = menu:addOption(tostring(FlavorText.transferCompanionHeading or "Transfer companion command to..."))
    if heading then
        heading.notAvailable = true
    end

    for _, username in ipairs(candidates) do
        menu:addOption(username, nil, function()
            self:sendColonyCommand("TransferCompanionCommand", {
                workerID = worker.workerID,
                username = username
            })
            self:updateStatus(string.format(tostring(FlavorText.transferCompanionStatus or "Transferring companion command to %s..."), tostring(username)))
        end)
    end
end

function DC_MainWindow:onOpenCompanionLootConfig()
    local worker = JobActions.getSelectedWorkerForAction(self)
    if not worker or not worker.workerID then
        self:updateStatus(tostring(FlavorText.selectCompanionWorkerFirst or "Select a companion worker first."))
        return
    end

    local config = JobActions.getConfig()
    local normalizedJob = config.NormalizeJobType and config.NormalizeJobType(worker.jobType) or tostring(worker.jobType or "")
    if normalizedJob ~= tostring((config.JobTypes or {}).TravelCompanion or "TravelCompanion") then
        self:updateStatus(tostring(FlavorText.lootSetupTravelCompanionOnly or "Loot setup is only available for Travel Companion workers."))
        return
    end

    if not DC_CompanionLootModal or not DC_CompanionLootModal.Open then
        self:updateStatus(tostring(FlavorText.lootSetupUnavailable or "The companion loot setup modal is unavailable right now."))
        return
    end

    local workerName = tostring(worker.name or worker.workerID or FlavorText.companionFallbackName or "Companion")
    DC_CompanionLootModal.Open({
        worker = worker,
        title = tostring(FlavorText.companionLootSetupTitle or "Companion Loot Setup"),
        promptText = string.format(tostring(FlavorText.companionLootSetupPrompt or "Configure how %s should filter nearby loot sources."), workerName),
        onSave = function(lootConfig)
            self:sendColonyCommand("SetWorkerCompanionLootConfig", {
                workerID = worker.workerID,
                lootConfig = lootConfig
            })
            self:updateStatus(string.format(
                tostring(FlavorText.companionLootSaveStatus or "Saving loot setup for %s with %s..."),
                workerName,
                JobActions.buildCompanionLootStatus(lootConfig)
            ))
        end
    })
end

return DC_MainWindow
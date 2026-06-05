require "DC/UI/Colony/MainWindow/MainWindowCore/DC_MainWindowCore_Bootstrap"
require "DC/UI/Colony/MainWindow/MainWindowCore/DC_MainWindowCore_Formatters"
require "DC/UI/Colony/MainWindow/MainWindowCore/DC_MainWindowCore_ReserveData"
require "DC/UI/Colony/MainWindow/MainWindowCore/DC_MainWindowCore_WorkerPresentation"

DC_MainWindow = DC_MainWindow or {}
DC_MainWindow.Internal = DC_MainWindow.Internal or {}

local Internal = DC_MainWindow.Internal
local MainWindowLayout = Internal.MainWindowLayout or {}

local function formatFallback(template, params)
    local text = tostring(template or "")
    if type(params) ~= "table" then
        return text
    end

    return (text:gsub("{([%w_]+)}", function(name)
        local value = params[name]
        return value == nil and ("{" .. name .. "}") or tostring(value)
    end))
end

local function T(key, fallback, params)
    if DC and DC.Text and DC.Text.Get then
        return DC.Text.Get(key, params, fallback)
    end
    return formatFallback(fallback or key, params)
end

local function isFunction(value)
    return type(value) == "function"
end

local function getConfig()
    local config = Internal.Config
    if type(config) ~= "table" then
        config = (DC_Colony and DC_Colony.Config) or {}
        Internal.Config = config
    end
    return config
end

local function formatBool(value)
    if isFunction(Internal.formatBool) then
        return Internal.formatBool(value)
    end
    return value and T("DCCommon_UI_MainWindow_HousedYes", "Yes") or T("DCCommon_UI_MainWindow_HousedNo", "No")
end

local function formatDecimal(value, decimals)
    if isFunction(Internal.formatDecimal) then
        return Internal.formatDecimal(value, decimals)
    end
    local places = tonumber(decimals) or 2
    return string.format("%." .. tostring(places) .. "f", tonumber(value) or 0)
end

local function formatReserveValue(value)
    if isFunction(Internal.formatReserveValue) then
        return Internal.formatReserveValue(value)
    end
    return tostring(math.floor((tonumber(value) or 0) + 0.5))
end

local function formatCoords(x, y, z)
    if isFunction(Internal.formatCoords) then
        return Internal.formatCoords(x, y, z)
    end
    if x == nil or y == nil then
        return T("DCCommon_UI_MainWindow_None", "None")
    end
    return "(" .. tostring(math.floor(tonumber(x) or 0))
        .. ", " .. tostring(math.floor(tonumber(y) or 0))
        .. ", " .. tostring(math.floor(tonumber(z) or 0)) .. ")"
end

local function formatDurationHours(hoursLeft)
    if isFunction(Internal.formatDurationHours) then
        return Internal.formatDurationHours(hoursLeft)
    end
    local safeHours = math.max(0, tonumber(hoursLeft) or 0)
    if safeHours <= 0 then
        return "empty now"
    end
    if safeHours < 1 then
        return "< 1h"
    end
    return tostring(math.floor(safeHours + 0.5)) .. "h"
end

local function getLocalUsername()
    local player = getSpecificPlayer and getSpecificPlayer(0) or getPlayer and getPlayer() or nil
    if player and player.getUsername then
        local username = tostring(player:getUsername() or "")
        if username ~= "" then
            return username
        end
    end
    return nil
end

local function getCompanionCommander(worker)
    local companionData = type(worker and worker.companion) == "table" and worker.companion or {}
    local username = tostring(companionData.commanderUsername or worker and worker.companionCommanderUsername or "")
    return username ~= "" and username or nil
end

local function getCompanionLootConfig(worker)
    local companionInternal = DC_Colony and DC_Colony.Companion and DC_Colony.Companion.Internal or nil
    if companionInternal and companionInternal.GetCompanionLootConfig then
        return companionInternal.GetCompanionLootConfig(worker)
    end
    local companionData = type(worker and worker.companion) == "table" and worker.companion or {}
    return type(companionData.lootConfig) == "table" and companionData.lootConfig or nil
end

local function buildCompanionLootSummary(worker, config)
    local lootConfig = getCompanionLootConfig(worker) or {}
    local sources = {}
    if lootConfig.includeLooseWorldItems ~= false then
        sources[#sources + 1] = T("DCCommon_UI_CompanionLoot_GroundItemsOn", "Ground Items: On"):gsub(": On$", "")
    end
    if lootConfig.includeGroundContainers ~= false then
        sources[#sources + 1] = T("DCCommon_UI_CompanionLoot_GroundBagsOn", "Ground Bags: On"):gsub(": On$", "")
    end
    if lootConfig.includeFurnitureContainers ~= false then
        sources[#sources + 1] = T("DCCommon_UI_CompanionLoot_FurnitureOn", "Furniture: On"):gsub(": On$", "")
    end
    if lootConfig.includeCorpseContainers ~= false then
        sources[#sources + 1] = T("DCCommon_UI_CompanionLoot_CorpsesOn", "Corpses: On"):gsub(": On$", "")
    end
    if lootConfig.includeVehicleContainers ~= false then
        sources[#sources + 1] = T("DCCommon_UI_CompanionLoot_VehiclesOn", "Vehicles: On"):gsub(": On$", "")
    end
    if #sources == 0 then
        sources[#sources + 1] = T("DCCommon_UI_MainWindow_None", "None")
    end

    return T("DCCommon_UI_CompanionLoot_SearchRadius", "Search Radius")
        .. " "
        .. tostring(lootConfig.radius or 10)
        .. " | "
        .. T("DCCommon_UI_CompanionLoot_SearchSources", "Search Sources")
        .. " "
        .. table.concat(sources, ", ")
end

local function buildActivityLogText(worker)
    if isFunction(Internal.buildActivityLogText) then
        return Internal.buildActivityLogText(worker)
    end
    return " <RGB:0.62,0.62,0.62> " .. T("DCCommon_UI_MainWindow_NoRecentActivity", "No recent worker activity yet.") .. " <LINE> "
end

local function formatHousingSummary(worker)
    local housingState = tostring(worker and worker.housingState or "Unhoused")
    local buildingType = tostring(worker and worker.housingBuildingType or "")
    local isHoused = housingState ~= "" and housingState ~= "Unhoused"

    if not isHoused then
        return T("DCCommon_UI_MainWindow_HousedNo", "No")
    end

    if buildingType ~= "" and buildingType ~= "None" then
        return T("DCCommon_UI_MainWindow_HousedYesType", "Yes - {buildingType}", {
            buildingType = buildingType
        })
    end

    return T("DCCommon_UI_MainWindow_HousedYes", "Yes")
end

local function updateRichTextPanel(window, panel, cacheField, nextText, resetScroll)
    if not window or not panel then
        return false
    end

    local changed = window[cacheField] ~= nextText
    if changed then
        window[cacheField] = nextText
        panel:setText(nextText)
        MainWindowLayout.refreshRichTextPanel(panel, resetScroll and 0 or nil)
        return true
    end

    if resetScroll then
        MainWindowLayout.setRichTextPanelScroll(panel, 0)
    end

    return false
end

function DC_MainWindow:updateWorkerDetail(worker)
    local previousWorkerID = self.selectedWorker and self.selectedWorker.workerID or nil
    local nextWorkerID = worker and worker.workerID or nil
    local workerChanged = previousWorkerID ~= nextWorkerID
    local shouldResetScroll = workerChanged

    self.selectedWorker = worker

    if self.reservePanel and self.reservePanel.setWorker then
        self.reservePanel:setWorker(worker)
    end

    if not self.detailText or not self.activityLogText then
        return
    end

    if not worker then
        local detailChanged = updateRichTextPanel(
            self,
            self.detailText,
            "lastRenderedDetailText",
            " <RGB:0.6,0.6,0.6> " .. T("DCCommon_UI_MainWindow_NoWorkerSelected", "No worker selected. Recruit one from ConversationUI or pick an existing labour worker from the list.") .. " ",
            true
        )
        local activityChanged = updateRichTextPanel(
            self,
            self.activityLogText,
            "lastRenderedActivityLogText",
            " <RGB:0.62,0.62,0.62> " .. T("DCCommon_UI_MainWindow_NoRecentActivity", "No recent worker activity yet.") .. " ",
            true
        )
        if self.applyDynamicLayout and (detailChanged or activityChanged or workerChanged) then
            self:applyDynamicLayout({
                refreshDetailText = false,
                refreshActivityText = false,
                refreshStatusText = false
            })
        end
        if self.btnToggleJob then
            self.btnToggleJob:setTitle(T("DCCommon_UI_MainWindow_StartJob", "Start Job"))
            if MainWindowLayout.applyToggleButtonStyle then
                MainWindowLayout.applyToggleButtonStyle(self.btnToggleJob, false)
            end
        end
        if self.btnAutoRepeat then
            self.btnAutoRepeat:setTitle(T("DCCommon_UI_MainWindow_WorkModeContinuous", "Work Mode: Continuous"))
            self.btnAutoRepeat:setEnable(false)
        end
        if self.btnCycleJob then
            self.btnCycleJob:setEnable(false)
        end
        if self.btnWarehouse then
            self.btnWarehouse:setEnable(false)
        end
        if self.btnCompanionCommand then
            self.btnCompanionCommand:setTitle(T("DCCommon_UI_MainWindow_Command", "Command"))
            self.btnCompanionCommand:setEnable(false)
        end
        if self.btnCompanionLootConfig then
            self.btnCompanionLootConfig:setEnable(false)
        end
        return
    end

    local config = getConfig()
    local profile = (isFunction(config.GetJobProfile) and config.GetJobProfile(worker.jobType)) or {}
    local jobSkillEffects = worker.jobSkillEffects or {
        skillID = worker.jobSkillID,
        skillLabel = worker.jobSkillLabel,
        level = worker.jobSkillLevel,
        speedMultiplier = worker.jobSkillSpeedMultiplier or 1
    }
    local bonusMultiplier = tonumber(jobSkillEffects.speedMultiplier) or 1
    local normalizedJobType = isFunction(config.NormalizeJobType) and config.NormalizeJobType(worker.jobType) or worker.jobType
    local stateLabel = tostring(worker.state or "")
    local deadState = tostring((config.States or {}).Dead or "Dead")
    local unemployedJob = tostring((config.JobTypes or {}).Unemployed or "Unemployed")
    local text = ""
    text = text .. " <RGB:1,1,1> <SIZE:Medium> " .. T("DCCommon_UI_MainWindow_WorkerStatus", "Worker Status") .. " <LINE> "
    if stateLabel == deadState and tostring(worker.deathCause or "") ~= "" then
        text = text .. " <RGB:0.88,0.52,0.52> " .. T("DCCommon_UI_MainWindow_CauseOfDeath", "Cause Of Death") .. ": <RGB:1,1,1> " .. tostring(worker.deathCause) .. " <LINE> "
    end
    if normalizedJobType == (config.JobTypes and config.JobTypes.TravelCompanion) and Internal.getCompanionCommandStatus then
        text = text .. " <RGB:0.72,0.72,0.72> " .. T("DCCommon_UI_MainWindow_CompanionCommand", "Companion Command") .. ": <RGB:1,1,1> "
            .. tostring(Internal.getCompanionCommandStatus(worker) or T("DCCommon_UI_MainWindow_NoCommander", "No commander"))
            .. " <LINE> "
        text = text .. " <RGB:0.72,0.72,0.72> " .. T("DCCommon_UI_MainWindow_LootSetup", "Loot Setup") .. ": <RGB:1,1,1> "
            .. buildCompanionLootSummary(worker, config)
            .. " <LINE> "
    end
    if normalizedJobType == (config.JobTypes and config.JobTypes.Gatherer) then
        text = text .. " <RGB:0.72,0.72,0.72> " .. T("DCCommon_UI_MainWindow_Gathering", "Gathering") .. ": <RGB:1,1,1> "
            .. tostring(worker.gathererSelectionLabel or (DC_Colony and DC_Colony.Gatherer and DC_Colony.Gatherer.GetSelectionLabel and DC_Colony.Gatherer.GetSelectionLabel(worker)) or "Wood, Stone, Water")
            .. " <LINE> "
        text = text .. " <RGB:0.72,0.72,0.72> " .. T("DCCommon_UI_MainWindow_Loadout", "Loadout") .. ": <RGB:1,1,1> "
            .. tostring(worker.gathererHasAxe and T("DCCommon_UI_MainWindow_AxeReady", "Axe ready") or T("DCCommon_UI_MainWindow_NoAxe", "No axe"))
            .. " | "
            .. tostring(worker.gathererHasPickaxe and T("DCCommon_UI_MainWindow_PickaxeReady", "Pickaxe ready") or T("DCCommon_UI_MainWindow_NoPickaxe", "No pickaxe"))
            .. " | "
            .. tostring(worker.gathererHasSack and T("DCCommon_UI_MainWindow_SackReady", "Sack ready") or T("DCCommon_UI_MainWindow_NoSack", "No sack"))
            .. " <LINE> "
        text = text .. " <RGB:0.72,0.72,0.72> " .. T("DCCommon_UI_MainWindow_WaterContainers", "Water Containers") .. ": <RGB:1,1,1> "
            .. tostring(math.max(0, tonumber(worker.gathererWaterContainerCount) or 0))
            .. " " .. T("DCCommon_UI_MainWindow_Assigned", "assigned")
            .. " | " .. T("DCCommon_UI_MainWindow_Free", "Free") .. " "
            .. tostring(math.floor((tonumber(worker.gathererWaterCollectableCapacity) or tonumber(worker.gathererWaterFreeCapacity) or 0) + 0.5))
            .. " / "
            .. tostring(math.floor((tonumber(worker.gathererWaterCapacity) or 0) + 0.5))
            .. " <LINE> "
        text = text .. " <RGB:0.72,0.72,0.72> " .. T("DCCommon_UI_MainWindow_WaterCarry", "Water Carry") .. ": <RGB:1,1,1> "
            .. tostring(math.floor((tonumber(worker.gathererWaterCarryAmount) or 0) + 0.5))
            .. " | " .. T("DCCommon_UI_MainWindow_Storage", "Storage") .. " "
            .. tostring(math.floor((tonumber(worker.gathererWaterStorageStored) or 0) + 0.5))
            .. " / "
            .. tostring(math.floor((tonumber(worker.gathererWaterStorageCapacity) or 0) + 0.5))
            .. " <LINE> "
        text = text .. " <RGB:0.72,0.72,0.72> Notes: <RGB:1,1,1> " .. T("DCCommon_UI_MainWindow_GathererNotes", "Wood and stone still work without tools, but much slower. Water uses all assigned fluid containers and needs built water storage with free capacity.") .. " <LINE> "
    end
    if normalizedJobType == (config.JobTypes and config.JobTypes.CorpseRemoval) then
        local graveyardTarget = DC_ZoneRealBase and DC_ZoneRealBase.ResolveGraveyardTarget and DC_ZoneRealBase.ResolveGraveyardTarget(worker) or nil
        text = text .. " <RGB:0.72,0.72,0.72> " .. T("DCCommon_UI_MainWindow_Graveyard", "Graveyard") .. ": <RGB:1,1,1> "
            .. tostring(graveyardTarget and formatCoords(graveyardTarget.x, graveyardTarget.y, graveyardTarget.z) or T("DCCommon_UI_MainWindow_NotSet", "Not set"))
            .. " <LINE> "
        text = text .. " <RGB:0.72,0.72,0.72> " .. T("DCCommon_UI_MainWindow_CorpsesBuried", "Corpses Buried") .. ": <RGB:1,1,1> "
            .. tostring(math.max(0, math.floor(tonumber(worker.corpseRemovalCount) or 0)))
            .. " <LINE> "
    end
    text = text .. " <RGB:0.72,0.72,0.72> " .. T("DCCommon_UI_MainWindow_ToolState", "Tool State") .. ": <RGB:1,1,1> " .. tostring(worker.toolState or T("DCCommon_UI_MainWindow_Missing", "Missing")) .. " <LINE> "
    text = text .. " <RGB:0.72,0.72,0.72> " .. T("DCCommon_UI_MainWindow_Housed", "Housed") .. ": <RGB:1,1,1> " .. formatHousingSummary(worker) .. " <LINE> "
    if jobSkillEffects and jobSkillEffects.skillID then
        text = text .. " <RGB:0.72,0.72,0.72> " .. T("DCCommon_UI_MainWindow_ActiveSkill", "Active Skill") .. ": <RGB:1,1,1> "
            .. tostring(jobSkillEffects.skillLabel or jobSkillEffects.skillID)
            .. " (Lv "
            .. tostring(jobSkillEffects.level or 0)
            .. ") <LINE> "
    else
        text = text .. " <RGB:0.72,0.72,0.72> " .. T("DCCommon_UI_MainWindow_ActiveSkill", "Active Skill") .. ": <RGB:1,1,1> " .. T("DCCommon_UI_MainWindow_None", "None") .. " <LINE> "
    end
    text = text .. " <RGB:0.72,0.72,0.72> " .. T("DCCommon_UI_MainWindow_SkillSpeedBonus", "Skill Speed Bonus") .. ": <RGB:1,1,1> x" .. formatDecimal(bonusMultiplier, 2) .. " <LINE> "

    local activityText = buildActivityLogText(worker)
    local detailChanged = updateRichTextPanel(self, self.detailText, "lastRenderedDetailText", text, shouldResetScroll)
    local activityChanged = updateRichTextPanel(
        self,
        self.activityLogText,
        "lastRenderedActivityLogText",
        activityText,
        shouldResetScroll
    )
    if self.applyDynamicLayout and (detailChanged or activityChanged or workerChanged) then
        self:applyDynamicLayout({
            refreshDetailText = false,
            refreshActivityText = false,
            refreshStatusText = false
        })
    end

    if self.btnToggleJob then
        if stateLabel == deadState then
            self.btnToggleJob:setTitle(T("DCCommon_UI_MainWindow_BuryPerson", "Bury Person"))
            if MainWindowLayout.applyToggleButtonStyle then
                MainWindowLayout.applyToggleButtonStyle(self.btnToggleJob, true)
            end
        elseif normalizedJobType == (config.JobTypes and config.JobTypes.Scavenge)
            or normalizedJobType == (config.JobTypes and config.JobTypes.Gatherer) then
            local presenceState = tostring(worker.presenceState or "")
            local homeState = tostring((config.PresenceStates or {}).Home or "Home")
            if worker.jobEnabled and presenceState ~= homeState then
                self.btnToggleJob:setTitle(T("DCCommon_UI_MainWindow_ReturnHome", "Return Home"))
            elseif worker.jobEnabled then
                self.btnToggleJob:setTitle(T("DCCommon_UI_MainWindow_CancelJob", "Cancel Job"))
            else
                self.btnToggleJob:setTitle(T("DCCommon_UI_MainWindow_StartJob", "Start Job"))
            end
            if MainWindowLayout.applyToggleButtonStyle then
                MainWindowLayout.applyToggleButtonStyle(self.btnToggleJob, worker.jobEnabled == true)
            end
        elseif normalizedJobType == (config.JobTypes and config.JobTypes.TravelCompanion) then
            if worker.jobEnabled then
                self.btnToggleJob:setTitle(T("DCCommon_UI_MainWindow_StopDuty", "Stop Duty"))
            else
                self.btnToggleJob:setTitle(T("DCCommon_UI_MainWindow_StartDuty", "Start Duty"))
            end
            if MainWindowLayout.applyToggleButtonStyle then
                MainWindowLayout.applyToggleButtonStyle(self.btnToggleJob, worker.jobEnabled == true)
            end
        elseif normalizedJobType == unemployedJob then
            self.btnToggleJob:setTitle(T("DCCommon_UI_MainWindow_AssignJob", "Assign Job"))
            if MainWindowLayout.applyToggleButtonStyle then
                MainWindowLayout.applyToggleButtonStyle(self.btnToggleJob, false)
            end
        else
            self.btnToggleJob:setTitle(worker.jobEnabled
                and T("DCCommon_UI_MainWindow_StopJob", "Stop Job")
                or T("DCCommon_UI_MainWindow_StartJob", "Start Job"))
            if MainWindowLayout.applyToggleButtonStyle then
                MainWindowLayout.applyToggleButtonStyle(self.btnToggleJob, worker.jobEnabled == true)
            end
        end
    end

    if self.btnAutoRepeat then
        self.btnAutoRepeat:setTitle(T("DCCommon_UI_MainWindow_WorkModeContinuous", "Work Mode: Continuous"))
        self.btnAutoRepeat:setEnable(false)
    end

    if self.btnCycleJob then
        self.btnCycleJob:setEnable(stateLabel ~= deadState)
    end

    if self.btnWarehouse then
        self.btnWarehouse:setEnable(true)
    end

    if self.btnCompanionCommand then
        local canUseCompanionCommand = normalizedJobType == (config.JobTypes and config.JobTypes.TravelCompanion)
            and worker.jobEnabled == true
            and stateLabel ~= deadState
        if canUseCompanionCommand then
            local commander = getCompanionCommander(worker)
            if commander and commander == getLocalUsername() then
                self.btnCompanionCommand:setTitle(T("DCCommon_UI_MainWindow_TransferCmd", "Transfer Cmd"))
            else
                self.btnCompanionCommand:setTitle(T("DCCommon_UI_MainWindow_ClaimCmd", "Claim Cmd"))
            end
        else
            self.btnCompanionCommand:setTitle(T("DCCommon_UI_MainWindow_Command", "Command"))
        end
        self.btnCompanionCommand:setEnable(canUseCompanionCommand)
    end

    if self.btnCompanionLootConfig then
        local canConfigureLoot = normalizedJobType == (config.JobTypes and config.JobTypes.TravelCompanion)
            and stateLabel ~= deadState
        self.btnCompanionLootConfig:setEnable(canConfigureLoot)
    end
end

DC_Colony = DC_Colony or {}
DC_Colony.Companion = DC_Colony.Companion or {}

local Companion = DC_Colony.Companion
local Config = DC_Colony.Config

local TRAVEL_STAGE_OUTBOUND = "Outbound"
local TRAVEL_STAGE_ACTIVE = "Active"
local TRAVEL_STAGE_DEPARTING = "Departing"
local TRAVEL_STAGE_RETURNING = "Returning"

local function getRegistry()
    return DC_Colony and DC_Colony.Registry or nil
end

local function getInteraction()
    return DC_Colony and DC_Colony.Interaction or nil
end

local function getHealth()
    return DC_Colony and DC_Colony.Health or nil
end

local function saveRegistry()
    local registry = getRegistry()
    if registry and registry.Save then
        registry.Save()
    end
end

local function getCurrentWorldHours()
    return (Config.GetCurrentWorldHours and Config.GetCurrentWorldHours()) or Config.GetCurrentHour()
end

local function getWorkerSkillLevel(worker, skillID)
    local common = Config and Config.Common or nil
    if common and common.GetWorkerSkillLevel then
        return math.max(0, math.floor(tonumber(common.GetWorkerSkillLevel(worker, skillID)) or 0))
    end

    local skills = DC_Colony and DC_Colony.Skills or nil
    local entry = skills and skills.GetSkillEntry and skills.GetSkillEntry(worker, skillID) or nil
    return math.max(0, math.floor(tonumber(entry and entry.level) or 0))
end

local function getTravelHours()
    local internal = DC_Colony and DC_Colony.Sim and DC_Colony.Sim.Internal or nil
    if internal and internal.getScavengeTravelHours then
        return math.max(0, tonumber(internal.getScavengeTravelHours()) or 0)
    end

    return math.max(
        0,
        tonumber(Config.GetScavengeTravelHours and Config.GetScavengeTravelHours())
            or tonumber(Config.DEFAULT_SCAVENGE_TRAVEL_HOURS)
            or 0
    )
end

local function appendLog(worker, text, currentHour, category)
    local internal = DC_Colony and DC_Colony.Sim and DC_Colony.Sim.Internal or nil
    if internal and internal.appendWorkerLog then
        internal.appendWorkerLog(worker, text, currentHour or getCurrentWorldHours(), category or "travel")
    end
end

local function getPlayerFaction(ownerUsername)
    if not DynamicTrading_Factions or not DynamicTrading_Factions.GetPlayerFaction then
        return nil
    end

    return DynamicTrading_Factions.GetPlayerFaction(ownerUsername)
end

local function getCompanionData(worker)
    if type(worker) ~= "table" then
        return nil
    end

    worker.companion = type(worker.companion) == "table" and worker.companion or {}
    return worker.companion
end

local function getCompanionUUID(worker)
    local companionData = getCompanionData(worker)
    local uuid = companionData and tostring(companionData.uuid or "") or ""
    return uuid ~= "" and uuid or nil
end

local function saveSoul(uuid, npcData)
    if uuid and npcData and DynamicTrading_Roster and DynamicTrading_Roster.SaveSoul then
        DynamicTrading_Roster.SaveSoul(uuid, npcData)
    end
end

local function getSoul(uuid)
    if not uuid or not DynamicTrading_Roster or not DynamicTrading_Roster.GetSoul then
        return nil
    end

    return DynamicTrading_Roster.GetSoul(uuid)
end

local function getAmmoTypeForWeapon(fullType)
    local scriptItem = fullType and getScriptManager and getScriptManager():getItem(fullType) or nil
    if scriptItem and scriptItem.getAmmoType then
        local ammoType = scriptItem:getAmmoType()
        if ammoType and ammoType ~= "" then
            return tostring(ammoType)
        end
    end
    return nil
end

local function getFallbackAmmoCount(weaponType)
    local scriptItem = weaponType and getScriptManager and getScriptManager():getItem(weaponType) or nil
    local clipSize = scriptItem and scriptItem.getClipSize and tonumber(scriptItem:getClipSize()) or 0
    clipSize = math.max(1, math.floor(clipSize or 0))
    return clipSize * 3
end

local function hasTag(entry, targetTag)
    if type(entry) ~= "table" or type(entry.tags) ~= "table" then
        return false
    end

    for _, tag in ipairs(entry.tags) do
        if tag == targetTag or string.find(tostring(tag), "^" .. targetTag .. "%.") then
            return true
        end
    end

    return false
end

local function selectEquipmentEntries(worker)
    local selected = {
        ranged = nil,
        melee = nil,
        ammo = nil,
        bag = nil,
    }

    for _, entry in ipairs(worker and worker.toolLedger or {}) do
        local requirementKey = tostring(entry and entry.assignedRequirementKey or "")
        if requirementKey == "Colony.Combat.Ranged" and not selected.ranged then
            selected.ranged = entry
        elseif requirementKey == "Colony.Combat.Melee" and not selected.melee then
            selected.melee = entry
        elseif requirementKey == "Colony.Combat.Ammo" and not selected.ammo then
            selected.ammo = entry
        elseif requirementKey == "Colony.Carry.Backpack" and not selected.bag then
            selected.bag = entry
        end
    end

    for _, entry in ipairs(worker and worker.toolLedger or {}) do
        if not selected.ranged and hasTag(entry, "Weapon.Ranged.Firearm") then
            selected.ranged = entry
        end
        if not selected.melee and hasTag(entry, "Weapon.Melee") then
            selected.melee = entry
        end
        if not selected.ammo and hasTag(entry, "Weapon.Ranged.Ammo") then
            selected.ammo = entry
        end
        if not selected.bag and hasTag(entry, "Colony.Carry.Backpack") then
            selected.bag = entry
        end
    end

    return selected
end

local function buildLoadoutFromWorker(worker)
    local chosen = selectEquipmentEntries(worker)
    local rangedWeapon = chosen.ranged and chosen.ranged.fullType or nil
    local meleeWeapon = chosen.melee and chosen.melee.fullType or nil
    local ammoType = chosen.ammo and chosen.ammo.fullType or getAmmoTypeForWeapon(rangedWeapon)
    local ammoCount = chosen.ammo and 24 or 0

    if rangedWeapon and ammoCount <= 0 then
        ammoCount = getFallbackAmmoCount(rangedWeapon)
    end

    return {
        rangedWeapon = rangedWeapon,
        rangedAmmoType = ammoType,
        ammoCount = math.max(0, tonumber(ammoCount) or 0),
        meleeWeapon = meleeWeapon,
        bag = chosen.bag and chosen.bag.fullType or nil,
        rangedCondition = chosen.ranged and chosen.ranged.condition or nil,
        meleeCondition = chosen.melee and chosen.melee.condition or nil,
    }
end

local function buildHealthSeed(worker, npcData)
    local health = getHealth()
    local maxHp = math.max(
        1,
        tonumber(worker and worker.maxHp)
            or tonumber(worker and worker.healthMax)
            or tonumber(Config.DEFAULT_WORKER_MAX_HP)
            or 100
    )
    local currentHp = math.max(
        0,
        math.min(
            maxHp,
            tonumber(worker and worker.hp)
                or tonumber(worker and worker.health)
                or maxHp
        )
    )

    npcData.combatHealth = type(npcData.combatHealth) == "table" and npcData.combatHealth or {}
    npcData.combatHealth.max = maxHp
    npcData.combatHealth.current = currentHp
    npcData.combatHealth.baseMax = maxHp
    npcData.combatHealth.skillBonus = 0
    npcData.combatHealth.bandageUnlimited = false
    npcData.combatHealth.bandageCharges = 0
    npcData.combatHealth.activeBandage = false
    npcData.combatHealth.bandageDirty = false
    npcData.combatHealth.bandageStatus = "None"
    npcData.combatHealth.bandageHealPool = 0
    npcData.combatHealth.bandageHealRemaining = 0
    npcData.combatHealth.bandageActionUntil = 0
    npcData.combatHealth.bandageRetryAt = 0
    npcData.combatHealth.linkedWorkerMaxHp = maxHp
    npcData.combatHealth.linkedWorkerCurrentHp = currentHp
    npcData.combatHealth.linkedWorkerHealthOverride = true
    npcData.restingRegenMultiplier = health and health.GetSleepHealingRate and health.GetSleepHealingRate(worker) or nil
end

local function setSoulCompanionFlags(worker, npcData, active)
    local companionData = getCompanionData(worker)
    npcData.dcCompanionJob = Config.JobTypes and Config.JobTypes.TravelCompanion or "TravelCompanion"
    npcData.dcCompanionOwner = worker.ownerUsername
    npcData.dcCompanionStage = companionData and companionData.stage or nil
    npcData.dcCompanionActive = active == true
end

local function getMedicalBandageTier(fullType)
    local value = tostring(fullType or "")
    if value == "Base.AlcoholRippedSheets" then
        return "sterilized_rag", "Base.RippedSheetsDirty"
    end
    if value == "Base.RippedSheets" then
        return "clean_rag", "Base.RippedSheetsDirty"
    end
    if value == "Base.Bandage" or value == "Base.BandageBox" or value == "Base.AlcoholBandage" then
        return "bandage", "Base.BandageDirty"
    end
    return "clean_rag", "Base.RippedSheetsDirty"
end

local function removeNutritionEntry(worker, index)
    if not worker or not index then
        return
    end

    table.remove(worker.nutritionLedger, index)
    worker.nutritionCacheDirty = true
end

local function addDirtyMedicalOutput(worker, fullType)
    local registry = getRegistry()
    if not registry or not registry.AddOutputEntry or not fullType or fullType == "" then
        return
    end

    registry.AddOutputEntry(worker, {
        fullType = fullType,
        displayName = registry.Internal and registry.Internal.GetDisplayNameForFullType and registry.Internal.GetDisplayNameForFullType(fullType) or nil,
        qty = 1,
    })
end

local function finalizeReturnTravel(worker, currentHour)
    local companionData = getCompanionData(worker)
    worker.presenceState = Config.PresenceStates.Home
    worker.travelHoursRemaining = 0
    worker.returnReason = nil
    if worker.state ~= Config.States.Dead and worker.state ~= Config.States.Incapacitated then
        worker.state = Config.States.Idle
    end
    companionData.awaitingDespawn = false
    companionData.stage = nil
    companionData.currentOrder = nil
    companionData.returnReason = nil
    companionData.returnTravelHours = nil
    appendLog(worker, "Returned home from companion duty.", currentHour, "travel")
end

function Companion.IsV2Active()
    local activated = getActivatedMods and getActivatedMods() or nil
    return activated and activated.contains and activated:contains("DynamicTradingV2") or false
end

function Companion.IsTravelCompanionWorker(worker)
    return Config.NormalizeJobType and Config.NormalizeJobType(worker and worker.jobType) == ((Config.JobTypes or {}).TravelCompanion)
end

function Companion.CanWorkerBeCompanion(worker)
    if not Companion.IsV2Active() then
        return false, "Travel Companion needs V2."
    end

    local melee = getWorkerSkillLevel(worker, "Melee")
    local shooting = getWorkerSkillLevel(worker, "Shooting")
    if melee <= 0 and shooting <= 0 then
        return false, "Travel Companion requires Melee or Shooting skill."
    end

    return true, nil
end

function Companion.GetWorkerTravelHours(worker)
    return getTravelHours()
end

function Companion.GetHealthSeed(worker)
    if type(worker) ~= "table" then
        return nil
    end

    return {
        hp = math.max(0, tonumber(worker.hp) or tonumber(worker.health) or 0),
        maxHp = math.max(1, tonumber(worker.maxHp) or tonumber(worker.healthMax) or tonumber(Config.DEFAULT_WORKER_MAX_HP) or 100),
    }
end

function Companion.SyncNPCFromWorker(worker, uuid)
    if not worker or not uuid then
        return false
    end

    local npcData = getSoul(uuid)
    if not npcData then
        return false
    end

    npcData.name = worker.name or npcData.name
    npcData.isFemale = worker.isFemale
    npcData.identitySeed = worker.identitySeed or npcData.identitySeed
    npcData.archetypeID = worker.archetypeID or npcData.archetypeID or worker.profession or "General"
    npcData.ownerUsername = worker.ownerUsername
    npcData.linkedWorkerID = worker.workerID
    npcData.isPlayerFactionTrader = true
    npcData.homeCoords = {
        x = worker.homeX or 0,
        y = worker.homeY or 0,
        z = worker.homeZ or 0,
    }
    npcData.loadout = buildLoadoutFromWorker(worker)
    buildHealthSeed(worker, npcData)
    setSoulCompanionFlags(worker, npcData, worker.presenceState == Config.PresenceStates.CompanionActive)
    saveSoul(uuid, npcData)
    return true
end

function Companion.StartWorkerCompanion(player, worker)
    if not player or not worker or not Companion.IsTravelCompanionWorker(worker) then
        return false, "Companion start is unavailable."
    end

    local okay, reason = Companion.CanWorkerBeCompanion(worker)
    if not okay then
        return false, reason
    end

    if not DynamicTrading_Factions or not DynamicTrading_Factions.EnsureTradeSoul then
        return false, "Dynamic Trading V2 is not ready."
    end

    local faction = getPlayerFaction(worker.ownerUsername)
    if not faction or not faction.id then
        return false, "Create a player faction first."
    end

    local uuid, err = DynamicTrading_Factions.EnsureTradeSoul(faction.id, worker.workerID)
    if not uuid then
        return false, err or "Unable to prepare companion soul."
    end

    local companionData = getCompanionData(worker)
    companionData.uuid = uuid
    companionData.stage = TRAVEL_STAGE_OUTBOUND
    companionData.awaitingDespawn = false
    companionData.currentOrder = "Follow"
    companionData.returnReason = nil
    companionData.returnTravelHours = nil

    worker.presenceState = Config.PresenceStates.CompanionToPlayer
    worker.travelHoursRemaining = getTravelHours()
    worker.returnReason = nil
    worker.state = Config.States.Working

    Companion.SyncNPCFromWorker(worker, uuid)

    if isClient() and not isServer() then
        return true, uuid
    end

    if not DTNPCServerCore or not DTNPCServerCore.SpawnOffscreenCompanionByUUID then
        return false, "Dynamic Trading V2 server controls are unavailable."
    end

    local spawned = DTNPCServerCore.SpawnOffscreenCompanionByUUID(uuid, player)
    DTNPCServerCore.IssueOrderByUUID(uuid, player, {
        state = "Follow",
        returnStatus = "Resting",
    })

    appendLog(worker, "Left home to join you as a travel companion.", getCurrentWorldHours(), "travel")
    return spawned == true, uuid
end

function Companion.IssueWorkerCompanionOrder(player, workerID, order, args)
    if isClient() and not isServer() then
        return false, "Server-only companion control."
    end

    local registry = getRegistry()
    local worker = registry and registry.GetWorker and registry.GetWorker(workerID) or nil
    local uuid = worker and getCompanionUUID(worker) or nil
    if not worker or not uuid or not DTNPCServerCore or not DTNPCServerCore.IssueOrderByUUID then
        return false, "Companion is unavailable."
    end

    args = type(args) == "table" and args or {}
    args.state = order
    local changed = DTNPCServerCore.IssueOrderByUUID(uuid, player, args)
    return changed == true, uuid
end

function Companion.BeginWorkerCompanionReturn(player, worker, reason)
    if not worker or not Companion.IsTravelCompanionWorker(worker) then
        return false
    end

    local companionData = getCompanionData(worker)
    local uuid = getCompanionUUID(worker)
    local travelHours = getTravelHours()
    local currentHour = getCurrentWorldHours()
    companionData.returnReason = reason or Config.ReturnReasons.Manual
    companionData.returnTravelHours = travelHours
    worker.returnReason = companionData.returnReason

    if worker.presenceState == Config.PresenceStates.CompanionActive and uuid and DTNPCServerCore and DTNPCServerCore.IssueOrderByUUID then
        companionData.stage = TRAVEL_STAGE_DEPARTING
        companionData.awaitingDespawn = true
        worker.state = Config.States.Working
        local npcData = getSoul(uuid)
        if npcData then
            setSoulCompanionFlags(worker, npcData, false)
            saveSoul(uuid, npcData)
        end
        DTNPCServerCore.IssueOrderByUUID(uuid, player or { ownerUsername = worker.ownerUsername }, {
            state = "Stay",
            returnStatus = "Resting",
            startDeparture = true,
        })
        appendLog(worker, "Heading off to return home.", currentHour, "travel")
        return true
    end

    if worker.presenceState == Config.PresenceStates.Home then
        worker.jobEnabled = false
        worker.returnReason = nil
        companionData.stage = nil
        companionData.awaitingDespawn = false
        return true
    end

    worker.presenceState = Config.PresenceStates.CompanionReturning
    worker.travelHoursRemaining = travelHours
    worker.jobEnabled = false
    companionData.stage = TRAVEL_STAGE_RETURNING
    companionData.awaitingDespawn = false
    appendLog(worker, "Heading back home from companion duty.", currentHour, "travel")
    return true
end

function Companion.MarkCompanionActive(worker)
    if not worker then
        return
    end

    local companionData = getCompanionData(worker)
    companionData.stage = TRAVEL_STAGE_ACTIVE
    companionData.awaitingDespawn = false
    worker.presenceState = Config.PresenceStates.CompanionActive
    worker.travelHoursRemaining = 0
    worker.state = Config.States.Working

    local uuid = getCompanionUUID(worker)
    local npcData = uuid and getSoul(uuid) or nil
    if npcData then
        setSoulCompanionFlags(worker, npcData, true)
        saveSoul(uuid, npcData)
    end
end

function Companion.OnSoulStatusChanged(uuid, status, npcData)
    if not uuid or not status then
        return
    end

    local linkedWorkerID = npcData and npcData.linkedWorkerID or nil
    local registry = getRegistry()
    local worker = linkedWorkerID and registry and registry.GetWorkerRaw and registry.GetWorkerRaw(linkedWorkerID) or nil
    if not worker or not Companion.IsTravelCompanionWorker(worker) then
        return
    end

    local companionData = getCompanionData(worker)
    if tostring(status) == "Dead" then
        worker.state = Config.States.Dead
        worker.jobEnabled = false
        worker.hp = 0
        worker.presenceState = Config.PresenceStates.Home
        worker.travelHoursRemaining = 0
        companionData.stage = nil
        companionData.awaitingDespawn = false
        appendLog(worker, "Died while away on companion duty.", getCurrentWorldHours(), "death")
        saveRegistry()
        return
    end

    if tostring(status) == "Away"
        and (companionData.awaitingDespawn == true
            or worker.presenceState == Config.PresenceStates.CompanionActive
            or worker.presenceState == Config.PresenceStates.CompanionToPlayer) then
        worker.jobEnabled = false
        worker.presenceState = Config.PresenceStates.CompanionReturning
        worker.travelHoursRemaining = math.max(0, tonumber(companionData.returnTravelHours) or getTravelHours())
        worker.returnReason = worker.returnReason or companionData.returnReason or Config.ReturnReasons.Manual
        worker.state = worker.state == Config.States.Incapacitated and Config.States.Incapacitated or Config.States.Idle
        companionData.stage = TRAVEL_STAGE_RETURNING
        companionData.awaitingDespawn = false
        saveRegistry()
    end
end

function Companion.SyncWorkerHealthFromNPC(workerID, npcData)
    local registry = getRegistry()
    local worker = registry and registry.GetWorkerRaw and registry.GetWorkerRaw(workerID) or nil
    if not worker then
        return false
    end

    local current = tonumber(npcData and npcData.combatHealth and npcData.combatHealth.current)
        or tonumber(npcData and npcData.health)
        or nil
    local maxHp = tonumber(npcData and npcData.combatHealth and npcData.combatHealth.max)
        or tonumber(worker.maxHp)
        or tonumber(Config.DEFAULT_WORKER_MAX_HP)
        or 100

    if maxHp and maxHp > 0 then
        worker.maxHp = math.max(1, math.floor(maxHp + 0.5))
    end
    if current ~= nil then
        worker.hp = math.max(0, math.min(worker.maxHp, current))
    end
    saveRegistry()
    return true
end

function Companion.HandleIncapacitatedNPC(npcData)
    local workerID = npcData and npcData.linkedWorkerID or nil
    local registry = getRegistry()
    local worker = workerID and registry and registry.GetWorkerRaw and registry.GetWorkerRaw(workerID) or nil
    if not worker or not Companion.IsTravelCompanionWorker(worker) then
        return false
    end

    Companion.SyncWorkerHealthFromNPC(worker.workerID, npcData)
    worker.state = Config.States.Incapacitated
    worker.jobEnabled = false
    local companionData = getCompanionData(worker)
    companionData.awaitingDespawn = false
    companionData.stage = TRAVEL_STAGE_RETURNING
    worker.presenceState = Config.PresenceStates.CompanionReturning
    worker.travelHoursRemaining = getTravelHours()
    worker.returnReason = Config.ReturnReasons.LowEnergy
    appendLog(worker, "Was incapacitated and is being brought home to recover.", getCurrentWorldHours(), "medical")
    saveRegistry()
    return true
end

function Companion.ResolveBandageSupply(worker)
    if not worker then
        return nil
    end

    for index, entry in ipairs(worker.nutritionLedger or {}) do
        local isMedical = Config.IsMedicalProvisionEntry and Config.IsMedicalProvisionEntry(entry) or false
        local useKind = tostring(entry and entry.medicalUse or "")
        local units = math.max(0, tonumber(entry and entry.treatmentUnitsRemaining) or 0)
        if isMedical and units > 0 and (useKind == "bandage" or useKind == "") then
            local tierID, dirtyFullType = getMedicalBandageTier(entry.fullType)
            return {
                index = index,
                entry = entry,
                tierID = tierID,
                dirtyFullType = dirtyFullType,
            }
        end
    end

    return nil
end

function Companion.ConsumeBandageSupply(workerID)
    local registry = getRegistry()
    local worker = registry and registry.GetWorkerRaw and registry.GetWorkerRaw(workerID) or nil
    if not worker then
        return nil
    end

    local supply = Companion.ResolveBandageSupply(worker)
    if not supply then
        return nil
    end

    local entry = supply.entry
    entry.treatmentUnitsRemaining = math.max(0, tonumber(entry.treatmentUnitsRemaining) or 0) - 1
    if entry.treatmentUnitsRemaining <= 0 then
        removeNutritionEntry(worker, supply.index)
    else
        worker.nutritionCacheDirty = true
    end

    addDirtyMedicalOutput(worker, supply.dirtyFullType)
    return {
        tierID = supply.tierID,
        dirtyFullType = supply.dirtyFullType,
    }
end

function Companion.UpdateTravelCompanionWorker(worker, ctx)
    if not worker or not Companion.IsTravelCompanionWorker(worker) then
        return false
    end

    local deltaHours = math.max(0, tonumber(ctx and ctx.deltaHours) or 0)
    local currentHour = tonumber(ctx and ctx.currentHour) or getCurrentWorldHours()
    local forcedRest = ctx and ctx.forcedRest == true or false
    local hasCalories = ctx and ctx.hasCalories ~= false
    local hasHydration = ctx and ctx.hasHydration ~= false
    local energy = DC_Colony and DC_Colony.Energy or nil
    local profile = ctx and ctx.profile or Config.GetJobProfile(worker.jobType)
    local presenceState = tostring(worker.presenceState or "")
    local companionData = getCompanionData(worker)

    if presenceState == Config.PresenceStates.CompanionToPlayer then
        worker.travelHoursRemaining = math.max(0, tonumber(worker.travelHoursRemaining) or 0)
        if deltaHours > 0 then
            worker.travelHoursRemaining = math.max(0, worker.travelHoursRemaining - deltaHours)
        end
        if energy and deltaHours > 0 then
            energy.ApplyTravelDrain(worker, deltaHours, profile)
        end
        if worker.travelHoursRemaining <= 0 then
            Companion.MarkCompanionActive(worker)
            appendLog(worker, "Arrived and is now traveling with you.", currentHour, "travel")
        else
            worker.state = Config.States.Working
        end
        return true
    end

    if presenceState == Config.PresenceStates.CompanionReturning then
        worker.travelHoursRemaining = math.max(0, tonumber(worker.travelHoursRemaining) or 0)
        if deltaHours > 0 then
            worker.travelHoursRemaining = math.max(0, worker.travelHoursRemaining - deltaHours)
        end
        if energy and deltaHours > 0 then
            energy.ApplyTravelDrain(worker, deltaHours, profile)
        end
        if worker.travelHoursRemaining <= 0 then
            finalizeReturnTravel(worker, currentHour)
        else
            worker.state = worker.state == Config.States.Incapacitated and Config.States.Incapacitated or Config.States.Idle
        end
        return true
    end

    if presenceState == Config.PresenceStates.CompanionActive then
        if companionData.awaitingDespawn == true then
            worker.state = Config.States.Working
            return true
        end

        if energy and deltaHours > 0 then
            energy.ApplyWorkDrain(worker, deltaHours, profile)
        end

        if not worker.jobEnabled then
            Companion.BeginWorkerCompanionReturn(nil, worker, Config.ReturnReasons.Manual)
        elseif not hasHydration then
            Companion.BeginWorkerCompanionReturn(nil, worker, Config.ReturnReasons.LowDrink)
        elseif not hasCalories then
            Companion.BeginWorkerCompanionReturn(nil, worker, Config.ReturnReasons.LowFood)
        elseif forcedRest or (energy and energy.IsDepleted and energy.IsDepleted(worker)) then
            Companion.BeginWorkerCompanionReturn(nil, worker, Config.ReturnReasons.LowEnergy)
        else
            worker.state = Config.States.Working
            companionData.stage = TRAVEL_STAGE_ACTIVE
        end
        return true
    end

    return false
end

return Companion

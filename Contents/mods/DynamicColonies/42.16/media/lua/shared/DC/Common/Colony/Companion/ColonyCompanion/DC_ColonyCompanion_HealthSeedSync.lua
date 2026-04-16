DC_Colony = DC_Colony or {}
DC_Colony.Companion = DC_Colony.Companion or {}

local Internal = DC_Colony.Companion.Internal
local Config = Internal.Config

function Internal.BuildHealthSeed(worker, npcData)
    local health = Internal.GetHealth()
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

function Internal.SetSoulCompanionFlags(worker, npcData, active)
    local companionData = Internal.GetCompanionData(worker)
    npcData.dcCompanionJob = Config.JobTypes and Config.JobTypes.TravelCompanion or "TravelCompanion"
    npcData.dcCompanionOwner = worker.ownerUsername
    npcData.dcCompanionStage = companionData and companionData.stage or nil
    npcData.dcCompanionActive = active == true
    Internal.MirrorCommanderToNPC(worker, npcData)
end
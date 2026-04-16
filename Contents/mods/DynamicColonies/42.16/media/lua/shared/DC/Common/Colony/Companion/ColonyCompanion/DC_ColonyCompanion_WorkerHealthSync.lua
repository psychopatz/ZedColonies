DC_Colony = DC_Colony or {}
DC_Colony.Companion = DC_Colony.Companion or {}

local Internal = DC_Colony.Companion.Internal
local Config = Internal.Config

function Internal.SyncWorkerHealthFromNPC(workerID, npcData)
    local registry = Internal.GetRegistry()
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
    Internal.SaveRegistry()
    return true
end
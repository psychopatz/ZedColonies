require "DC/Common/Colony/ColonyConfig/DC_ColonyConfig"
require "DC/Common/Colony/ColonyRegistry/DC_ColonyRegistry"
pcall(require, "DT/V2/NPC/Sys/DTNPC_Generator")

DC_Colony = DC_Colony or {}
DC_Colony.StarterWorkers = DC_Colony.StarterWorkers or {}

local Config = DC_Colony.Config
local StarterWorkers = DC_Colony.StarterWorkers

local function normalizeOwner(ownerUsername)
    if Config and Config.GetOwnerUsername then
        return Config.GetOwnerUsername(ownerUsername)
    end
    return tostring(ownerUsername or "local")
end

local function isRecruitable(archetypeID)
    return not (Config and Config.IsRecruitableArchetype)
        or Config.IsRecruitableArchetype(archetypeID)
end

function StarterWorkers.PickStarterArchetype()
    local pool = StarterWorkers.GetArchetypePool and StarterWorkers.GetArchetypePool() or {}
    local candidates = {}

    for _, archetypeID in ipairs(pool) do
        if isRecruitable(archetypeID) then
            candidates[#candidates + 1] = archetypeID
        end
    end

    if #candidates <= 0 then
        return "General"
    end

    return candidates[ZombRand(#candidates) + 1]
end

local function buildSourceID(owner, slot)
    return "StarterColony:" .. tostring(owner or "local") .. ":" .. tostring(slot or 0)
end

local function getRecruitBridge()
    return DC_Colony
        and DC_Colony.Network
        and DC_Colony.Network.Internal
        and DC_Colony.Network.Internal.createWorkerFromRecruitArgs
        or nil
end

function StarterWorkers.CreateStarterWorker(ownerUsername, slot, options)
    options = options or {}
    local owner = normalizeOwner(ownerUsername)
    local archetypeID = options.archetypeID or StarterWorkers.PickStarterArchetype()
    local npcData = nil

    if DTNPCGenerator and DTNPCGenerator.Generate then
        npcData = DTNPCGenerator.Generate({ occupation = archetypeID })
    end

    npcData = type(npcData) == "table" and npcData or {
        archetypeID = archetypeID,
        name = "Starter Worker",
        identitySeed = ZombRand(1000) + 1,
        visualID = ZombRand(1000000),
        isFemale = ZombRand(2) == 0
    }

    local sourceID = buildSourceID(owner, slot)
    local args = {
        sourceNPCID = sourceID,
        sourceNPCType = "StarterColony",
        archetypeID = archetypeID,
        profession = archetypeID,
        jobType = Config.JobTypes and Config.JobTypes.Unemployed or nil,
        name = npcData.name,
        isFemale = npcData.isFemale,
        identitySeed = npcData.identitySeed,
        visualID = npcData.visualID,
        hp = npcData.hp or npcData.health or (npcData.combatHealth and npcData.combatHealth.current),
        maxHp = npcData.maxHp or npcData.healthMax or (npcData.combatHealth and npcData.combatHealth.max)
    }

    local bridge = getRecruitBridge()
    if bridge then
        return bridge(owner, args, npcData)
    end

    local Registry = DC_Colony and DC_Colony.Registry or nil
    if not (Registry and Registry.CreateWorker) then
        return nil
    end

    return Registry.CreateWorker(owner, args)
end

return StarterWorkers

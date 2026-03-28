local System = DC_System
local Internal = System.Internal

local function normalizeText(value)
    local text = value and tostring(value) or ""
    return text ~= "" and text or nil
end

local function getConversationNPC(ui)
    return ui and ui.interactionObj or nil
end

local function getConversationNPCData(ui)
    local npc = getConversationNPC(ui)
    return npc and DTNPC and DTNPC.GetData and DTNPC.GetData(npc) or nil
end

local function readNPCWorkerID(ui)
    local npcData = getConversationNPCData(ui)
    local workerID = npcData and normalizeText(npcData.linkedWorkerID) or nil
    if workerID then
        return workerID, npcData
    end

    return nil, npcData
end

local function getLocalOwnerUsername()
    local config = Internal.GetConfig()
    if config and config.GetOwnerUsername then
        return config.GetOwnerUsername(Internal.GetLocalPlayer())
    end
    return nil
end

local function isOwnedByLocalPlayer(npcData)
    local ownerUsername = normalizeText(npcData and npcData.ownerUsername)
    local localOwner = normalizeText(getLocalOwnerUsername())
    if not ownerUsername or not localOwner then
        return false
    end
    return ownerUsername == localOwner
end

local function workerMatchesNPC(worker, npcData, sourceNPCID)
    if type(worker) ~= "table" then
        return false
    end

    local npcUUID = npcData and normalizeText(npcData.uuid) or nil
    if npcUUID then
        local candidates = {
            worker.companionNPCUUID,
            worker.recruitedTraderUUID,
            worker.sourceNPCUUID,
            worker.sourceNPCID,
            worker.tradeSoulUUID,
        }
        for _, candidate in ipairs(candidates) do
            if normalizeText(candidate) == npcUUID then
                return true
            end
        end
    end

    if sourceNPCID then
        return normalizeText(worker.sourceNPCID) == sourceNPCID
    end

    return false
end

local function resolveWorkerFromCaches(workerID, npcData, sourceNPCID)
    local detailCache = DC_MainWindow and DC_MainWindow.cachedDetails or nil
    if workerID and type(detailCache) == "table" and type(detailCache[workerID]) == "table" then
        return detailCache[workerID]
    end

    local summaries = DC_MainWindow and DC_MainWindow.cachedWorkers or {}
    for _, worker in ipairs(summaries) do
        if normalizeText(worker and worker.workerID) == workerID then
            return worker
        end
        if workerMatchesNPC(worker, npcData, sourceNPCID) then
            return worker
        end
    end

    if type(detailCache) == "table" then
        for _, worker in pairs(detailCache) do
            if workerMatchesNPC(worker, npcData, sourceNPCID) then
                return worker
            end
        end
    end

    return nil
end

local function resolveWorkerFromRegistry(workerID, npcData, sourceNPCID)
    if isClient() and not isServer() then
        return nil
    end

    local owner = Internal.GetConfig() and Internal.GetConfig().GetOwnerUsername
        and Internal.GetConfig().GetOwnerUsername(Internal.GetLocalPlayer())
        or nil

    if workerID
        and DC_Colony
        and DC_Colony.Registry
        and DC_Colony.Registry.GetWorkerDetailsForOwner
        and owner then
        local detail = DC_Colony.Registry.GetWorkerDetailsForOwner(owner, workerID, false, true)
        if detail then
            return detail
        end
    end

    if DC_Colony and DC_Colony.Registry and DC_Colony.Registry.GetWorkersForOwner and owner then
        for _, worker in ipairs(DC_Colony.Registry.GetWorkersForOwner(owner)) do
            if workerMatchesNPC(worker, npcData, sourceNPCID) then
                return worker
            end
        end
    end

    return nil
end

function System.GetConversationSourceNPCID(ui)
    if not ui or not ui.interactionObj then
        return nil
    end

    local npc = getConversationNPC(ui)
    local target = ui.target or {}
    local npcData = getConversationNPCData(ui)

    if npcData and npcData.uuid then
        return tostring(npcData.uuid)
    end
    if target.id then
        return tostring(target.id)
    end
    if npc.getPersistentOutfitID then
        return tostring(npc:getPersistentOutfitID())
    end
    if npc.getID then
        return tostring(npc:getID())
    end

    return nil
end

function System.GetConversationTraderID(ui)
    local npcData = getConversationNPCData(ui)
    if npcData and npcData.uuid then
        return tostring(npcData.uuid)
    end

    local target = ui and ui.target or nil
    local traderID = target and (target.uuid or target.traderID or target.id) or nil
    return traderID and tostring(traderID) or nil
end

function System.GetConversationEffectiveReputation(ui)
    local traderID = System.GetConversationTraderID(ui)
    local npcData = getConversationNPCData(ui)
    local factionID = (npcData and npcData.factionID) or (ui and ui.target and ui.target.factionID) or nil
    if not traderID or not DC_Reputation or not DC_Reputation.GetEffectiveRep then
        return 0
    end
    return DC_Reputation.GetEffectiveRep(traderID, factionID)
end

function System.GetCurrentDay()
    local config = Internal.GetConfig()
    local gt = getGameTime and getGameTime() or nil
    local hours = gt and gt:getWorldAgeHours() or 0
    return math.floor((tonumber(hours) or 0) / (config.HOURS_PER_DAY or 24))
end

function System.ResolveArchetype(trader)
    local rawRole = trader and (trader.archetype or trader.profession or trader.role) or ""
    local role = string.lower(tostring(rawRole))

    if string.find(role, "farm", 1, true) then
        return "Farmer"
    end

    if string.find(role, "angler", 1, true) or string.find(role, "fish", 1, true) then
        return "Angler"
    end

    return "General"
end

function System.GetConversationCompanionWorker(ui)
    if not ui or not ui.interactionObj then
        return nil
    end

    local workerID, npcData = readNPCWorkerID(ui)
    local sourceNPCID = System.GetConversationSourceNPCID(ui)

    return resolveWorkerFromCaches(workerID, npcData, sourceNPCID)
        or resolveWorkerFromRegistry(workerID, npcData, sourceNPCID)
        or (workerID and isOwnedByLocalPlayer(npcData) and {
            workerID = workerID,
            name = (npcData and npcData.name) or (ui.target and ui.target.name) or workerID,
            linkedFromCompanion = true
        } or nil)
end

function System.IsConversationWithCompanion(ui)
    return System.GetConversationCompanionWorker(ui) ~= nil
end

function System.BuildRecruitArgs(ui, archetypeID)
    if not ui or not ui.interactionObj then
        return nil
    end

    local config = Internal.GetConfig()
    local npc = ui.interactionObj
    local target = ui.target or {}
    local npcData = getConversationNPCData(ui)
    local player = Internal.GetLocalPlayer()

    local sourceNPCID = System.GetConversationSourceNPCID(ui)
    if not sourceNPCID then
        return nil
    end

    local x = nil
    local y = nil
    local z = 0
    local homeX = nil
    local homeY = nil
    local homeZ = 0
    if npc.getX and npc.getY then
        x = math.floor(npc:getX())
        y = math.floor(npc:getY())
        z = math.floor((npc.getZ and npc:getZ()) or 0)
    end

    if player then
        homeX = math.floor(player:getX())
        homeY = math.floor(player:getY())
        homeZ = math.floor(player:getZ())
        if x == nil or y == nil then
        x = math.floor(player:getX())
        y = math.floor(player:getY())
        z = math.floor(player:getZ())
        end
    end

    local normalizedArchetype = config.NormalizeArchetypeID(
        archetypeID or target.archetype or (npcData and (npcData.archetypeID or npcData.occupation)) or System.ResolveArchetype(target)
    )
    local defaultJobType = config.GetDefaultJobForArchetype(normalizedArchetype)
    local traderUUID = (npcData and npcData.uuid) or System.GetConversationTraderID(ui)
    local factionID = (npcData and npcData.factionID) or target.factionID
    local identitySeed = (npcData and npcData.identitySeed) or target.identitySeed or nil
    local isFemale = nil
    if npcData and npcData.isFemale ~= nil then
        isFemale = npcData.isFemale
    elseif npc and npc.isFemale then
        isFemale = npc:isFemale()
    else
        isFemale = target.gender == "Female"
    end

    return {
        jobType = defaultJobType,
        profession = defaultJobType,
        name = (npcData and npcData.name) or target.name or "Worker",
        archetypeID = normalizedArchetype,
        traderUUID = traderUUID and tostring(traderUUID) or nil,
        factionID = factionID,
        identitySeed = identitySeed,
        isFemale = isFemale,
        sourceNPCID = tostring(sourceNPCID),
        sourceNPCType = "ConversationUI",
        homeX = homeX,
        homeY = homeY,
        homeZ = homeZ,
        x = x,
        y = y,
        z = z
    }
end

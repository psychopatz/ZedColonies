local System = DC_System
local Internal = System.Internal

local function getReputationAPI()
    if DT_Reputation and DT_Reputation.GetEffectiveRep then
        return DT_Reputation
    end
    if DC_Reputation and DC_Reputation.GetEffectiveRep then
        return DC_Reputation
    end
    return nil
end

local function isIndependentFactionID(factionID)
    return string.lower(tostring(factionID or "")) == "independent"
end

function System.GetConversationSourceNPCID(ui)
    if not ui or not ui.interactionObj then
        return nil
    end

    local npc = ui.interactionObj
    local target = ui.target or {}
    local npcData = DTNPC and DTNPC.GetData and DTNPC.GetData(npc) or nil

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
    local npc = ui and ui.interactionObj or nil
    local npcData = npc and DTNPC and DTNPC.GetData and DTNPC.GetData(npc) or nil
    if npcData and npcData.uuid then
        return tostring(npcData.uuid)
    end

    local target = ui and ui.target or nil
    local traderID = target and (target.uuid or target.traderID or target.id) or nil
    return traderID and tostring(traderID) or nil
end

function System.GetConversationEffectiveReputation(ui)
    local traderID = System.GetConversationTraderID(ui)
    local npc = ui and ui.interactionObj or nil
    local npcData = npc and DTNPC and DTNPC.GetData and DTNPC.GetData(npc) or nil
    local factionID = (npcData and npcData.factionID) or (ui and ui.target and ui.target.factionID) or nil
    local reputationAPI = getReputationAPI()
    if traderID and reputationAPI then
        if isIndependentFactionID(factionID) and reputationAPI.GetPersonalRep then
            return reputationAPI.GetPersonalRep(traderID)
        end
        if reputationAPI.GetEffectiveRep then
            return reputationAPI.GetEffectiveRep(traderID, factionID)
        end
    end

    local target = ui and ui.target or nil
    return tonumber(target and target.reputation) or 0
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

function System.BuildRecruitArgs(ui, archetypeID)
    if not ui or not ui.interactionObj then
        return nil
    end

    local config = Internal.GetConfig()
    local npc = ui.interactionObj
    local target = ui.target or {}
    local npcData = DTNPC and DTNPC.GetData and DTNPC.GetData(npc) or nil
    local player = Internal.GetLocalPlayer()
    local ownedStatus = System.GetOwnedFactionStatus and System.GetOwnedFactionStatus() or nil
    local factionHome = ownedStatus and ownedStatus.faction and ownedStatus.faction.homeCoords or nil

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

    local baseX = nil
    local baseY = nil
    local baseZ = nil
    if factionHome and factionHome.x ~= nil and factionHome.y ~= nil then
        baseX = math.floor(tonumber(factionHome.x) or 0)
        baseY = math.floor(tonumber(factionHome.y) or 0)
        baseZ = math.floor(tonumber(factionHome.z) or 0)
        homeX = baseX
        homeY = baseY
        homeZ = baseZ
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
        baseX = baseX,
        baseY = baseY,
        baseZ = baseZ,
        homeX = homeX,
        homeY = homeY,
        homeZ = homeZ,
        x = x,
        y = y,
        z = z
    }
end

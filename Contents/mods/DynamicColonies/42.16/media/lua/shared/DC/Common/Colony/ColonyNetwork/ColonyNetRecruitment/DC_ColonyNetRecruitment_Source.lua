DC_Colony = DC_Colony or {}
DC_Colony.Network = DC_Colony.Network or {}

local Network = DC_Colony.Network
local Recruit = Network.Recruitment or {}

function Recruit.normalizeRecruitID(value)
    if value == nil then
        return nil
    end

    local text = tostring(value)
    if text == "" then
        return nil
    end

    return text
end

function Recruit.getRecruitSourceSoul(uuid)
    if not uuid or not DynamicTrading_Roster then
        return nil
    end

    if DynamicTrading_Roster.GetSoul then
        local soul = DynamicTrading_Roster.GetSoul(uuid)
        if soul then
            return soul
        end
    end

    if DynamicTrading_Roster.GetSoulRegistry then
        return DynamicTrading_Roster.GetSoulRegistry(uuid)
    end

    return nil
end

function Recruit.resolveRecruitSourceUUID(args)
    if type(args) ~= "table" then
        return nil
    end

    local traderUUID = Recruit.normalizeRecruitID(args.traderUUID)
    local sourceNPCID = Recruit.normalizeRecruitID(args.sourceNPCID)

    if traderUUID and Recruit.getRecruitSourceSoul(traderUUID) then
        return traderUUID
    end
    if sourceNPCID and Recruit.getRecruitSourceSoul(sourceNPCID) then
        return sourceNPCID
    end

    return traderUUID or sourceNPCID
end

function Recruit.resolveRecruitSourceHealth(args, sourceSoul)
    local config = Recruit.getConfig()
    local defaultMax = math.max(1, tonumber(config and config.DEFAULT_WORKER_MAX_HP) or 100)
    local combatHealth = sourceSoul and sourceSoul.combatHealth or nil

    local maxHp = tonumber(args and args.maxHp)
        or tonumber(args and args.healthMax)
        or tonumber(combatHealth and combatHealth.max)
        or tonumber(sourceSoul and sourceSoul.combatHealthMax)
        or nil
    local hp = tonumber(args and args.hp)
        or tonumber(args and args.health)
        or tonumber(combatHealth and combatHealth.current)
        or tonumber(sourceSoul and sourceSoul.combatHealthCurrent)
        or nil

    if hp == nil then
        local fallbackHealth = tonumber(sourceSoul and sourceSoul.health)
        if fallbackHealth and fallbackHealth > 1 then
            hp = fallbackHealth
        end
    end

    if maxHp ~= nil then
        maxHp = math.max(1, math.floor(maxHp + 0.5))
    end
    if hp ~= nil then
        local clampMax = maxHp or defaultMax
        hp = math.max(0, math.min(clampMax, math.floor(hp + 0.5)))
    end

    return hp, maxHp
end

function Recruit.isRecruitableRequest(args, sourceSoul)
    local Config = Recruit.getConfig()
    if not Config or not Config.IsRecruitableArchetype then
        return true
    end

    local archetypeID = args and (args.archetypeID or args.profession) or nil
    if not archetypeID and sourceSoul then
        archetypeID = sourceSoul.archetypeID or sourceSoul.profession
    end

    return Config.IsRecruitableArchetype(archetypeID)
end

return Recruit
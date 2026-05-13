DC_Colony = DC_Colony or {}
DC_Colony.Network = DC_Colony.Network or {}

local Network = DC_Colony.Network
local Internal = Network.Internal or {}
local Recruit = Network.Recruitment or {}

function Recruit.getRecruitDepartureTarget(args, sourceSoul)
    args = type(args) == "table" and args or {}
    sourceSoul = type(sourceSoul) == "table" and sourceSoul or {}

    local x = tonumber(args.baseX)
        or tonumber(args.homeX)
        or tonumber(sourceSoul.homeX)
        or tonumber(sourceSoul.homeCoords and sourceSoul.homeCoords.x)
        or tonumber(args.x)
    local y = tonumber(args.baseY)
        or tonumber(args.homeY)
        or tonumber(sourceSoul.homeY)
        or tonumber(sourceSoul.homeCoords and sourceSoul.homeCoords.y)
        or tonumber(args.y)
    local z = tonumber(args.baseZ)
        or tonumber(args.homeZ)
        or tonumber(sourceSoul.homeZ)
        or tonumber(sourceSoul.homeCoords and sourceSoul.homeCoords.z)
        or tonumber(args.z)
        or 0

    if not x or not y then
        return nil, nil, nil
    end

    return math.floor(x), math.floor(y), math.floor(z)
end

function Recruit.getAdjustedRecruitDepartureTarget(targetX, targetY, targetZ, zombie, sourceSoul)
    if not zombie or not targetX or not targetY then
        return targetX, targetY, targetZ
    end

    local zx = zombie:getX()
    local zy = zombie:getY()
    local zz = zombie:getZ()
    local dx = targetX - zx
    local dy = targetY - zy
    local dist = math.sqrt(dx * dx + dy * dy)
    if dist > 3 then
        return targetX, targetY, targetZ
    end

    local soulHomeX = tonumber(sourceSoul and sourceSoul.homeCoords and sourceSoul.homeCoords.x)
        or tonumber(sourceSoul and sourceSoul.homeX)
    local soulHomeY = tonumber(sourceSoul and sourceSoul.homeCoords and sourceSoul.homeCoords.y)
        or tonumber(sourceSoul and sourceSoul.homeY)
    local soulHomeZ = tonumber(sourceSoul and sourceSoul.homeCoords and sourceSoul.homeCoords.z)
        or tonumber(sourceSoul and sourceSoul.homeZ)
        or targetZ
    if soulHomeX and soulHomeY then
        local homeDx = soulHomeX - zx
        local homeDy = soulHomeY - zy
        local homeDist = math.sqrt(homeDx * homeDx + homeDy * homeDy)
        if homeDist > 3 then
            return math.floor(soulHomeX), math.floor(soulHomeY), math.floor(soulHomeZ or 0)
        end
    end

    local nearestPlayer = nil
    local nearestDist = nil
    local activePlayers = DTNPCManager and DTNPCManager.GetActivePlayers and DTNPCManager.GetActivePlayers() or {}
    for _, player in ipairs(activePlayers) do
        if player and math.abs((player:getZ() or 0) - zz) <= 1 then
            local pdx = zx - player:getX()
            local pdy = zy - player:getY()
            local playerDist = math.sqrt(pdx * pdx + pdy * pdy)
            if not nearestDist or playerDist < nearestDist then
                nearestDist = playerDist
                nearestPlayer = player
            end
        end
    end

    if nearestPlayer then
        local awayX = zx - nearestPlayer:getX()
        local awayY = zy - nearestPlayer:getY()
        local awayLen = math.sqrt(awayX * awayX + awayY * awayY)
        if awayLen > 0.001 then
            local travel = 12
            return math.floor(zx + ((awayX / awayLen) * travel)),
                math.floor(zy + ((awayY / awayLen) * travel)),
                math.floor(zz or targetZ or 0)
        end
    end

    return math.floor(zx + 12), math.floor(zy), math.floor(zz or targetZ or 0)
end

function Recruit.getRecruitGoodbyeText(args, sourceSoul)
    local lines = Recruit.FlavorText.goodbyeLines or {
        "I'll head to your base now.",
        "I'll meet you back at base.",
        "I'll get moving. See you at the base.",
        "Alright. I'll make my way there.",
    }
    local seed = tonumber(args and args.identitySeed)
        or tonumber(sourceSoul and sourceSoul.identitySeed)
        or 1
    local index = (math.abs(math.floor(seed)) % #lines) + 1
    return lines[index]
end

function Recruit.markRecruitmentDeparture(uuid, args, sourceSoul, owner, pendingResult)
    if not uuid or not DTNPCManager or not DTNPCManager.TryStartLiveDeparture then
        return false
    end

    local targetX, targetY, targetZ = Recruit.getRecruitDepartureTarget(args, sourceSoul)
    if not targetX or not targetY then
        return false
    end

    local npcData = (DTNPCManager.Data and DTNPCManager.Data[uuid]) or sourceSoul
    if not npcData then
        return false
    end

    npcData.colonyRecruitmentDeparture = true
    npcData.colonyRecruitmentOwner = owner and tostring(owner) or nil
    npcData.colonyRecruitmentOwnerOnlineID = pendingResult and pendingResult.ownerOnlineID or nil
    npcData.colonyRecruitmentSourceFactionID = npcData.factionID or (args and args.factionID) or nil
    npcData.colonyRecruitmentRemoveSource = true
    npcData.colonyRecruitmentPending = true
    npcData.colonyRecruitmentPendingArgs = Recruit.copyRecruitArgs(args)
    npcData.colonyRecruitmentPendingResult = Recruit.copyRecruitArgs(pendingResult)

    local walkHours = SandboxVars
        and SandboxVars.DynamicTrading
        and SandboxVars.DynamicTrading.NPCTradingWalkHours
        or 1.0

    local zombie = DTNPCServerCore and DTNPCServerCore.FindZombieByUUID and DTNPCServerCore.FindZombieByUUID(uuid) or nil
    targetX, targetY, targetZ = Recruit.getAdjustedRecruitDepartureTarget(targetX, targetY, targetZ, zombie, sourceSoul)

    local recruitReturnStatus = DTNPCManager
        and DTNPCManager.COLONY_RECRUITMENT_RETURN_STATUS
        or "ColonyRecruitment"

    if DTNPCManager.TryStartLiveDeparture(uuid, recruitReturnStatus, walkHours, targetX, targetY, targetZ) == true then
        if zombie and (not DTNPCProtect or not DTNPCProtect.PushCompanionNotice) then
            pcall(require, "DT/V2/NPC/Sys/DTNPC_Protect")
        end
        if zombie and DTNPCProtect and DTNPCProtect.PushCompanionNotice then
            DTNPCProtect.PushCompanionNotice(zombie, npcData, Recruit.getRecruitGoodbyeText(args, sourceSoul), "positive")
        end
        return true
    end

    npcData.colonyRecruitmentDeparture = nil
    npcData.colonyRecruitmentOwner = nil
    npcData.colonyRecruitmentOwnerOnlineID = nil
    npcData.colonyRecruitmentSourceFactionID = nil
    npcData.colonyRecruitmentRemoveSource = nil
    npcData.colonyRecruitmentPending = nil
    npcData.colonyRecruitmentPendingArgs = nil
    npcData.colonyRecruitmentPendingResult = nil
    return false
end

function Recruit.detachRecruitedSourceNPC(args, owner, pendingResult)
    local traderUUID = Recruit.resolveRecruitSourceUUID(args)
    if not traderUUID then
        return nil, nil
    end

    local soul = Recruit.getRecruitSourceSoul(traderUUID)
    local factionID = soul and soul.factionID or (args and args.factionID) or nil
    local removed = false

    if Recruit.markRecruitmentDeparture(traderUUID, args, soul, owner, pendingResult) then
        return traderUUID, soul, true
    end

    if DTNPCManager and DTNPCManager.SetNPCStatus then
        DTNPCManager.SetNPCStatus(traderUUID, "Away", nil, nil)
    end

    if DynamicTrading_Stock and DynamicTrading_Stock.ClearStock then
        DynamicTrading_Stock.ClearStock(traderUUID)
    end

    if DynamicTrading_Roster and DynamicTrading_Roster.RemoveSpecificSoul and DynamicTrading_Roster.RemoveSpecificSoul(traderUUID) then
        removed = true
    end

    if DynamicTrading_Roster and DynamicTrading_Roster.RemoveTrader and DynamicTrading_Roster.RemoveTrader(traderUUID) then
        removed = true
    end

    if removed and factionID and DynamicTrading_Factions and DynamicTrading_Factions.GetFaction then
        local faction = DynamicTrading_Factions.GetFaction(factionID)
        if faction and not faction.playerOwned then
            faction.memberCount = math.max(0, (tonumber(faction.memberCount) or 0) - 1)
        end
    end

    if removed then
        ModData.transmit("DynamicTrading_Roster")
        ModData.transmit("DynamicTrading_Stock")
        if factionID then
            ModData.transmit("DynamicTrading_Factions")
        end
    end

    return traderUUID, soul
end

Internal.detachRecruitedSourceNPC = Recruit.detachRecruitedSourceNPC

return Recruit
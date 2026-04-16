DC_Colony = DC_Colony or {}
DC_Colony.Companion = DC_Colony.Companion or {}

local Internal = DC_Colony.Companion.Internal
local Config = Internal.Config

function Internal.SaveSoul(uuid, npcData)
    if uuid and npcData and DynamicTrading_Roster and DynamicTrading_Roster.SaveSoul then
        DynamicTrading_Roster.SaveSoul(uuid, npcData)
    end
end

function Internal.GetSoul(uuid)
    if not uuid or not DynamicTrading_Roster or not DynamicTrading_Roster.GetSoul then
        return nil
    end

    return DynamicTrading_Roster.GetSoul(uuid)
end

function Internal.FindExistingCompanionSoul(worker)
    if not worker or not DynamicTrading_Roster or not DynamicTrading_Roster.GetSoul then
        return nil
    end

    local companionData = Internal.GetCompanionData(worker)
    local existingUUID = companionData and companionData.uuid or nil
    if existingUUID and DynamicTrading_Roster.GetSoul(existingUUID) then
        return existingUUID, false
    end

    local rosterData = Internal.GetRosterRegistry()
    local souls = rosterData and rosterData.Souls or nil
    if type(souls) ~= "table" then
        return nil
    end

    local ownerUsername = tostring(worker.ownerUsername or "")
    for uuid, soul in pairs(souls) do
        if soul
            and soul.linkedWorkerID == worker.workerID
            and tostring(soul.ownerUsername or "") == ownerUsername then
            local liveSoul = DynamicTrading_Roster.GetSoul(uuid)
            if liveSoul and tostring(liveSoul.dcCompanionJob or "") == tostring((Config.JobTypes and Config.JobTypes.TravelCompanion) or "TravelCompanion") then
                if companionData then
                    companionData.uuid = uuid
                end
                return uuid, false
            end
        end
    end

    return nil
end
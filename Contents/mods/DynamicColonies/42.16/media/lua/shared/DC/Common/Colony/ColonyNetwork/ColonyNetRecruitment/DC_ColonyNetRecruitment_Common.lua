DC_Colony = DC_Colony or {}
DC_Colony.Network = DC_Colony.Network or {}

local Network = DC_Colony.Network
local Internal = Network.Internal or {}
local Recruit = Network.Recruitment or {}

local Sites = DC_Colony.Sites

Network.Internal = Internal
Network.Recruitment = Recruit
Recruit.FlavorText = DC_Colony.Network.ColonyNetRecruitmentFlavorText or {}
Recruit.Sites = Sites

function Recruit.getConfig()
    return DC_Colony and DC_Colony.Config or nil
end

function Recruit.getRegistry()
    return DC_Colony and DC_Colony.Registry or nil
end

function Recruit.getSim()
    return DC_Colony and DC_Colony.Sim or nil
end

function Recruit.getPresentation()
    return DC_Colony and DC_Colony.Presentation or nil
end

function Recruit.getCurrentDay()
    local Config = Recruit.getConfig()
    if not Config then
        return 0
    end

    return math.floor((Config.GetCurrentHour() or 0) / Config.HOURS_PER_DAY)
end

function Recruit.syncRadarRoster(player)
    if not player or not Internal.sendResponse then
        return
    end

    local rosterData = ModData.get("DynamicTrading_Roster") or {}
    local factionData = ModData.get("DynamicTrading_Factions") or {}
    local minimalSouls = {}

    if rosterData.Souls then
        for uuid, soul in pairs(rosterData.Souls) do
            if soul.status == "Trading" then
                minimalSouls[uuid] = soul
            end
        end
    end

    Internal.sendResponse(player, "DynamicTrading_V2", "SyncRoster", {
        roster = {
            FactionMembers = rosterData.FactionMembers,
            Souls = minimalSouls,
            Traders = rosterData.Traders
        },
        factions = factionData
    })
end

function Recruit.copyRecruitArgs(args)
    local copy = {}
    if type(args) ~= "table" then
        return copy
    end

    for key, value in pairs(args) do
        copy[key] = value
    end

    return copy
end

Internal.syncRadarRoster = Recruit.syncRadarRoster

return Recruit
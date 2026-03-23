require "DT/Common/ZedColonies/LabourConfig/DT_LabourConfig"

DT_Labour = DT_Labour or {}
DT_Labour.Network = DT_Labour.Network or {}

local Config = DT_Labour.Config
local Network = DT_Labour.Network
local Internal = Network.Internal or {}

Network.Internal = Internal

local function clampReputation(value)
    local rep = tonumber(value) or 0
    if rep > 100 then return 100 end
    if rep < -100 then return -100 end
    return math.floor(rep + (rep >= 0 and 0.5 or -0.5))
end

local function sanitizeReputationKey(text)
    return tostring(text or "unknown"):gsub("[^%w_%-]", "_")
end

local function getReputationCharacterKey(player)
    if not player then return nil end

    local modData = player:getModData()
    if modData and modData.DT_ReputationCharacterKey and modData.DT_ReputationCharacterKey ~= "" then
        return modData.DT_ReputationCharacterKey
    end

    local desc = player.getDescriptor and player:getDescriptor() or nil
    local first = desc and desc:getForename() or "Survivor"
    local last = desc and desc:getSurname() or "Unknown"
    local username = (player.getUsername and player:getUsername()) or "local"
    local steamID = "0"
    if player.getSteamID then
        local rawSteamID = player:getSteamID()
        if rawSteamID and rawSteamID ~= 0 and rawSteamID ~= "0" then
            if type(rawSteamID) == "number" then
                steamID = string.format("%.0f", rawSteamID)
            else
                steamID = tostring(rawSteamID)
            end
        end
    end

    local mode = isServer() and "MP" or ((isClient() and not isServer()) and "MP" or "SP")
    return table.concat({
        mode,
        sanitizeReputationKey(username),
        sanitizeReputationKey(steamID),
        sanitizeReputationKey(first),
        sanitizeReputationKey(last),
    }, "_")
end

local function getPlayerReputationEntry(player)
    local modData = player and player:getModData() or nil
    if not modData then return nil end

    local store = modData.DT_ReputationState
    if type(store) ~= "table" then
        return nil
    end

    local characterKey = getReputationCharacterKey(player)
    if not characterKey then return nil end

    local entry = store[characterKey]
    if type(entry) ~= "table" then
        return nil
    end

    return entry
end

local function getEffectiveRecruitReputation(player, traderUUID, factionID)
    local entry = getPlayerReputationEntry(player)
    if type(entry) ~= "table" then
        return 0
    end

    local personalRep = type(entry.personalRep) == "table" and (entry.personalRep[tostring(traderUUID or "")] or 0) or 0
    local factionBias = type(entry.factionBias) == "table" and (entry.factionBias[tostring(factionID or "")] or 0) or 0
    return clampReputation(personalRep + factionBias)
end

Internal.getEffectiveRecruitReputation = getEffectiveRecruitReputation

return Network

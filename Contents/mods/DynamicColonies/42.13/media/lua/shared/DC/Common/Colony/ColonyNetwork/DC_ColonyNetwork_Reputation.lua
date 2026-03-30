require "DC/Common/Colony/ColonyConfig/DC_ColonyConfig"

DC_Colony = DC_Colony or {}
DC_Colony.Network = DC_Colony.Network or {}

local Config = DC_Colony.Config
local Network = DC_Colony.Network
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

local function isIndependentFactionID(factionID)
    return string.lower(tostring(factionID or "")) == "independent"
end

local function getReputationCharacterKey(player)
    if not player then return nil end

    local modData = player:getModData()
    if modData then
        if modData.DT_ReputationCharacterKey and modData.DT_ReputationCharacterKey ~= "" then
            return modData.DT_ReputationCharacterKey
        end
        if modData.DC_ReputationCharacterKey and modData.DC_ReputationCharacterKey ~= "" then
            return modData.DC_ReputationCharacterKey
        end
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

    local characterKey = getReputationCharacterKey(player)
    if not characterKey then return nil end

    local stores = {
        modData.DT_ReputationState,
        modData.DC_ReputationState
    }

    for _, store in ipairs(stores) do
        if type(store) == "table" then
            local entry = store[characterKey]
            if type(entry) == "table" then
                return entry
            end
        end
    end

    return nil
end

local function getOrCreatePlayerReputationEntry(player)
    local modData = player and player:getModData() or nil
    if not modData then return nil end

    local characterKey = getReputationCharacterKey(player)
    if not characterKey then return nil end

    if type(modData.DT_ReputationState) ~= "table" then
        modData.DT_ReputationState = {}
    end

    local store = modData.DT_ReputationState
    local entry = store[characterKey]
    if type(entry) ~= "table" then
        local legacyStore = type(modData.DC_ReputationState) == "table" and modData.DC_ReputationState or nil
        local legacyEntry = legacyStore and legacyStore[characterKey] or nil
        entry = type(legacyEntry) == "table" and legacyEntry or {}
        store[characterKey] = entry
    end

    entry.personalRep = type(entry.personalRep) == "table" and entry.personalRep or {}
    entry.factionBias = type(entry.factionBias) == "table" and entry.factionBias or {}
    entry.tradeProgress = type(entry.tradeProgress) == "table" and entry.tradeProgress or {}
    entry.totalBought = type(entry.totalBought) == "table" and entry.totalBought or {}
    entry.totalSold = type(entry.totalSold) == "table" and entry.totalSold or {}

    return entry
end

local function getEffectiveRecruitReputation(player, traderUUID, factionID)
    local entry = getPlayerReputationEntry(player)
    if type(entry) ~= "table" then
        return 0
    end

    local personalRep = type(entry.personalRep) == "table" and (entry.personalRep[tostring(traderUUID or "")] or 0) or 0
    if isIndependentFactionID(factionID) then
        return clampReputation(personalRep)
    end

    local factionBias = type(entry.factionBias) == "table" and (entry.factionBias[tostring(factionID or "")] or 0) or 0
    return clampReputation(personalRep + factionBias)
end

local function modifyRecruitReputation(player, traderUUID, factionID, amount)
    if not player then
        return 0
    end

    local entry = getOrCreatePlayerReputationEntry(player)
    if type(entry) ~= "table" then
        return 0
    end

    local delta = tonumber(amount) or 0
    local newValue = 0

    if isIndependentFactionID(factionID) or not factionID then
        local key = tostring(traderUUID or "")
        entry.personalRep[key] = clampReputation((entry.personalRep[key] or 0) + delta)
        newValue = entry.personalRep[key]
    else
        local key = tostring(factionID)
        entry.factionBias[key] = clampReputation((entry.factionBias[key] or 0) + delta)
        newValue = entry.factionBias[key]
    end

    if player.transmitModData then
        player:transmitModData()
    end

    return newValue
end

Internal.getEffectiveRecruitReputation = getEffectiveRecruitReputation
Internal.modifyRecruitReputation = modifyRecruitReputation
Internal.isIndependentFactionID = isIndependentFactionID

return Network

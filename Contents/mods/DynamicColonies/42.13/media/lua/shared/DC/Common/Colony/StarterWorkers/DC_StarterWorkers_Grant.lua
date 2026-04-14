require "DC/Common/Colony/ColonyConfig/DC_ColonyConfig"
require "DC/Common/Colony/ColonyRegistry/DC_ColonyRegistry"

DC_Colony = DC_Colony or {}
DC_Colony.StarterWorkers = DC_Colony.StarterWorkers or {}

local Config = DC_Colony.Config
local Registry = DC_Colony.Registry
local StarterWorkers = DC_Colony.StarterWorkers

local function normalizeOwner(ownerUsername)
    if Config and Config.GetOwnerUsername then
        return Config.GetOwnerUsername(ownerUsername)
    end
    return tostring(ownerUsername or "local")
end

local function getOwnerFromPlayer(player)
    if type(player) == "string" then
        return player
    end
    if player and player.getUsername then
        local username = player:getUsername()
        if username and username ~= "" then
            return username
        end
    end
    return normalizeOwner(player)
end

local function isFactionMember(owner)
    if not (DynamicTrading_Factions and DynamicTrading_Factions.GetPlayerFaction) then
        return false
    end

    local faction = DynamicTrading_Factions.GetPlayerFaction(owner)
    if not faction then
        return false
    end

    local leader = normalizeOwner(faction.leaderUsername)
    return leader ~= "" and leader ~= owner
end

local function ensureGrantState(colonyData)
    colonyData.starterWorkers = type(colonyData.starterWorkers) == "table" and colonyData.starterWorkers or {}
    colonyData.starterWorkers.grantedSlots = type(colonyData.starterWorkers.grantedSlots) == "table"
        and colonyData.starterWorkers.grantedSlots
        or {}
    return colonyData.starterWorkers
end

local function isSlotGranted(grantState, slot)
    return grantState.grantedSlots[tostring(slot)] == true
end

function StarterWorkers.EnsureForOwner(ownerUsername, player, options)
    options = options or {}
    local owner = normalizeOwner(ownerUsername or player)
    if owner == "" then
        return { created = 0, skipped = true, reason = "missing_owner" }
    end

    if options.allowFactionMember ~= true and isFactionMember(owner) then
        return { created = 0, skipped = true, reason = "member_colony" }
    end

    local targetCount = Config.GetStarterWorkerCount and Config.GetStarterWorkerCount() or 0
    if targetCount <= 0 then
        return { created = 0, skipped = true, reason = "disabled" }
    end

    if not (Registry and Registry.GetColonyData and Registry.GetWorkerSummariesForOwner) then
        return { created = 0, skipped = true, reason = "registry_unavailable" }
    end

    local colonyData = Registry.GetColonyData(owner, true)
    if type(colonyData) ~= "table" then
        return { created = 0, skipped = true, reason = "missing_colony" }
    end

    local grantState = ensureGrantState(colonyData)
    local created = 0
    local workers = {}

    for slot = 1, targetCount do
        if not isSlotGranted(grantState, slot) then
            local worker = StarterWorkers.CreateStarterWorker and StarterWorkers.CreateStarterWorker(owner, slot, options) or nil
            if worker and worker.workerID then
                grantState.grantedSlots[tostring(slot)] = true
                grantState.grantedCount = math.max(tonumber(grantState.grantedCount) or 0, slot)
                grantState.lastGrantedWorldHour = Config.GetCurrentWorldHours and Config.GetCurrentWorldHours() or nil
                workers[#workers + 1] = worker
                created = created + 1
            end
        end
    end

    if created > 0 then
        if Registry.TouchColonyVersion then
            Registry.TouchColonyVersion(owner)
        end
        if Registry.Save then
            Registry.Save()
        end
    end

    return {
        created = created,
        targetCount = targetCount,
        workers = workers
    }
end

function StarterWorkers.EnsureForPlayer(player, options)
    return StarterWorkers.EnsureForOwner(getOwnerFromPlayer(player), player, options)
end

return StarterWorkers

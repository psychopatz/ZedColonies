DC_Colony = DC_Colony or {}
DC_Colony.Network = DC_Colony.Network or {}

local Config = DC_Colony.Config
local Registry = DC_Colony.Registry
local Network = DC_Colony.Network
local Internal = Network.Internal or {}

Network.Handlers = Network.Handlers or {}

local function getCurrentWorldHours()
    return (Config and Config.GetCurrentWorldHours and Config.GetCurrentWorldHours())
        or (Config and Config.GetCurrentHour and Config.GetCurrentHour())
        or 0
end

local function appendStarterActivity(worker, message)
    local registryInternal = Registry and Registry.Internal or nil
    if registryInternal and registryInternal.AppendActivityLog then
        registryInternal.AppendActivityLog(worker, tostring(message or ""), getCurrentWorldHours(), "job")
    end
end

local function shouldCreateStarterFollowers()
    return Config
        and Config.IsDynamicTradingV2Active
        and Config.IsDynamicTradingV2Active() == true
        and Config.JobTypes
        and Config.JobTypes.FollowPlayer ~= nil
        and Config.EnsureWorkerCompanionUUID
        and Config.SyncWorkerCompanionFollow
end

local function getRequestedStarterCount(args)
    local configuredCount = Config.GetStarterColonistCount and Config.GetStarterColonistCount() or 0
    local requestedCount = math.max(0, math.floor(tonumber(args and args.starterCount) or 0))
    return math.max(configuredCount, requestedCount)
end

local function getStarterGrantKey(player, owner)
    if type(player) == "string" and player ~= "" then
        return tostring(player)
    end

    if player and player.getUsername then
        local username = player:getUsername()
        if username and username ~= "" then
            return tostring(username)
        end
    end

    return tostring(owner or "local")
end

local function ensureStarterGrantTables(colonyData)
    if type(colonyData) ~= "table" then
        return {}, {}
    end

    colonyData.starterColonistsGrantedPlayers = type(colonyData.starterColonistsGrantedPlayers) == "table"
        and colonyData.starterColonistsGrantedPlayers
        or {}
    colonyData.starterColonistsGrantedCounts = type(colonyData.starterColonistsGrantedCounts) == "table"
        and colonyData.starterColonistsGrantedCounts
        or {}
    return colonyData.starterColonistsGrantedPlayers, colonyData.starterColonistsGrantedCounts
end

local function hasGrantedEntries(entries)
    if type(entries) ~= "table" then
        return false
    end

    for _, _ in pairs(entries) do
        return true
    end

    return false
end

local function applyLegacyStarterGrantState(colonyData, owner, starterCount, existingCount)
    local grantedPlayers, grantedCounts = ensureStarterGrantTables(colonyData)
    if colonyData.starterColonistsGranted == true
        and not hasGrantedEntries(grantedCounts)
        and math.max(0, tonumber(existingCount) or 0) > 0 then
        local ownerKey = getStarterGrantKey(owner, owner)
        grantedPlayers[ownerKey] = true
        grantedCounts[ownerKey] = math.max(
            tonumber(grantedCounts[ownerKey]) or 0,
            math.min(math.max(0, tonumber(existingCount) or 0), math.max(0, tonumber(starterCount) or 0))
        )
    end
    return grantedPlayers, grantedCounts
end

local function getStarterSourceSoul(uuid)
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

local function getStarterArchetypePool()
    local pool = {}
    local seen = {}
    local registry = DynamicTrading and DynamicTrading.ArchetypeSkills or nil
    if type(registry) == "table" then
        for archetypeID, _ in pairs(registry) do
            local id = tostring(archetypeID or "")
            if id ~= ""
                and id ~= "General"
                and id ~= "Player"
                and id ~= "Demo"
                and not seen[id] then
                pool[#pool + 1] = id
                seen[id] = true
            end
        end
    end

    table.sort(pool)
    if #pool == 0 then
        pool[1] = "General"
    end

    return pool
end

local function getStableStarterArchetypeID(seedText)
    local pool = getStarterArchetypePool()
    if #pool == 1 then
        return pool[1]
    end

    local seed = tostring(seedText or "")
    if seed == "" then
        return pool[ZombRand(#pool) + 1]
    end

    local hash = 0
    for index = 1, #seed do
        hash = ((hash * 33) + string.byte(seed, index)) % 2147483647
    end

    return pool[(hash % #pool) + 1]
end

local function createStarterSoul(owner, template)
    if not DynamicTrading_Roster or not DynamicTrading_Roster.AddSoul then
        return nil, nil
    end

    local factionID = nil
    if DynamicTrading_Factions and DynamicTrading_Factions.GetPlayerFaction then
        local faction = DynamicTrading_Factions.GetPlayerFaction(owner)
        factionID = faction and faction.id or nil
    end
    if not factionID then
        factionID = "ColonyCompanion_" .. tostring(owner):gsub("[^%w_]", "_")
    end

    local uuid = DynamicTrading_Roster.AddSoul(factionID, template.archetypeID or "General", {
        x = template.homeX,
        y = template.homeY,
        z = template.homeZ or 0
    })
    if not uuid then
        return nil, nil
    end

    local soul = getStarterSourceSoul(uuid)
    if soul then
        soul.ownerUsername = owner
        soul.isPlayerFactionTrader = true
        soul.status = "Resting"
        soul.homeCoords = {
            x = template.homeX,
            y = template.homeY,
            z = template.homeZ or 0
        }
        if DynamicTrading_Roster.SaveSoul then
            DynamicTrading_Roster.SaveSoul(uuid, soul)
        end
    end

    return uuid, soul
end

local function buildStarterWorkerTemplate(player, index)
    local spawnX = math.floor(player:getX())
    local spawnY = math.floor(player:getY())
    local spawnZ = math.floor(player:getZ())
    local createFollower = shouldCreateStarterFollowers()
    local defaultJobType = createFollower
        and (Config.JobTypes and Config.JobTypes.FollowPlayer or "FollowPlayer")
        or (Config.JobTypes and Config.JobTypes.Unemployed or "Unemployed")
    local defaultState = createFollower
        and (Config.States and Config.States.Working or "Working")
        or (Config.States and Config.States.Idle or "Idle")

    return {
        name = createFollower and nil or ("Colonist " .. tostring(index)),
        jobType = defaultJobType,
        profession = defaultJobType,
        archetypeID = getStableStarterArchetypeID(
            tostring(player and player.getUsername and player:getUsername() or "local")
                .. ":" .. tostring(index)
        ),
        state = defaultState,
        jobEnabled = createFollower,
        presenceState = Config.PresenceStates and Config.PresenceStates.Home or "Home",
        homeX = spawnX,
        homeY = spawnY,
        homeZ = spawnZ,
        x = spawnX,
        y = spawnY,
        z = spawnZ,
        sourceNPCType = createFollower and "StarterColonist" or nil
    }
end

local function createStarterWorker(player, owner, index)
    local template = buildStarterWorkerTemplate(player, index)

    if shouldCreateStarterFollowers() and Internal.createWorkerFromRecruitArgs then
        local starterUUID, sourceSoul = createStarterSoul(owner, template)
        if starterUUID then
            local recruitArgs = {
                traderUUID = starterUUID,
                sourceNPCID = starterUUID,
                sourceNPCUUID = starterUUID,
                recruitedTraderUUID = starterUUID,
                sourceNPCType = "StarterColonist",
                jobType = Config.JobTypes and Config.JobTypes.FollowPlayer or "FollowPlayer",
                archetypeID = template.archetypeID,
                name = template.name,
                isFemale = template.isFemale,
                identitySeed = template.identitySeed,
                homeX = template.homeX,
                homeY = template.homeY,
                homeZ = template.homeZ,
                spawnX = template.x,
                spawnY = template.y,
                spawnZ = template.z,
                x = template.x,
                y = template.y,
                z = template.z
            }
            local worker = Internal.createWorkerFromRecruitArgs(owner, recruitArgs, sourceSoul)
            if worker then
                worker.sourceNPCID = tostring(starterUUID)
                worker.sourceNPCUUID = tostring(starterUUID)
                worker.recruitedTraderUUID = tostring(starterUUID)
                worker.companionNPCUUID = tostring(starterUUID)
                worker.tradeSoulUUID = tostring(starterUUID)
                return worker
            end
        end
    end

    return Registry.CreateWorker(owner, template)
end

local function syncStarterWorkerIdentity(worker)
    if type(worker) ~= "table" or tostring(worker.sourceNPCType or "") ~= "StarterColonist" then
        return false
    end

    local sourceUUID = tostring(
        worker.sourceNPCUUID
            or worker.recruitedTraderUUID
            or worker.companionNPCUUID
            or worker.tradeSoulUUID
            or worker.sourceNPCID
            or ""
    )
    if sourceUUID == "" then
        return false
    end

    local sourceSoul = getStarterSourceSoul(sourceUUID)
    if not sourceSoul then
        return false
    end

    local changed = false
    local soulChanged = false
    local sourceArchetypeID = tostring(sourceSoul.archetypeID or "")
    if sourceArchetypeID == "" or sourceArchetypeID == "General" then
        local derivedArchetypeID = getStableStarterArchetypeID(sourceUUID)
        if derivedArchetypeID ~= "" and derivedArchetypeID ~= sourceArchetypeID then
            sourceSoul.archetypeID = derivedArchetypeID
            sourceArchetypeID = derivedArchetypeID
            soulChanged = true
        end
    end

    if soulChanged and DynamicTrading_Roster and DynamicTrading_Roster.SaveSoul then
        DynamicTrading_Roster.SaveSoul(sourceUUID, sourceSoul)
    end

    if sourceSoul.name and sourceSoul.name ~= "" and worker.name ~= sourceSoul.name then
        worker.name = sourceSoul.name
        changed = true
    end
    if sourceSoul.isFemale ~= nil and worker.isFemale ~= sourceSoul.isFemale then
        worker.isFemale = sourceSoul.isFemale
        changed = true
    end
    if sourceSoul.identitySeed and worker.identitySeed ~= sourceSoul.identitySeed then
        worker.identitySeed = sourceSoul.identitySeed
        changed = true
    end
    if sourceArchetypeID ~= "" and worker.archetypeID ~= sourceArchetypeID then
        worker.archetypeID = sourceArchetypeID
        changed = true
    end

    return changed or soulChanged
end

local function bootstrapStarterFollower(player, worker)
    if not player or not worker or not shouldCreateStarterFollowers() then
        return false
    end

    local companionUUID = Config.EnsureWorkerCompanionUUID(worker)
    if not companionUUID then
        worker.jobEnabled = false
        worker.state = Config.States and Config.States.Idle or "Idle"
        worker.jobType = Config.JobTypes and Config.JobTypes.Unemployed or "Unemployed"
        worker.profession = worker.jobType
        appendStarterActivity(worker, "Starter colonist arrived, but companion control could not be prepared yet.")
        return false
    end

    worker.sourceNPCID = tostring(worker.sourceNPCID or companionUUID)
    worker.sourceNPCUUID = tostring(worker.sourceNPCUUID or companionUUID)
    worker.recruitedTraderUUID = tostring(worker.recruitedTraderUUID or companionUUID)
    worker.companionNPCUUID = tostring(worker.companionNPCUUID or companionUUID)
    worker.tradeSoulUUID = tostring(worker.tradeSoulUUID or companionUUID)
    if Registry and Registry.Internal and Registry.Internal.Runtime and Registry.Internal.Runtime.sourceNPCToWorkerID then
        Registry.Internal.Runtime.sourceNPCToWorkerID[tostring(worker.sourceNPCID)] = worker.workerID
    end
    worker.jobType = Config.JobTypes and Config.JobTypes.FollowPlayer or "FollowPlayer"
    worker.profession = worker.jobType
    worker.jobEnabled = true
    worker.state = Config.States and Config.States.Working or "Working"
    worker.presenceState = Config.PresenceStates and Config.PresenceStates.Home or "Home"

    if DTNPCServerCore and DTNPCServerCore.SpawnNearbyCompanionByUUID then
        DTNPCServerCore.SpawnNearbyCompanionByUUID(companionUUID, player, 2, 6)
    end

    Config.SyncWorkerCompanionLoadout(worker)
    local followed, reason = Config.SyncWorkerCompanionFollow(worker)
    if not followed then
        appendStarterActivity(worker, "Starter colonist joined the roster, but could not begin following yet: " .. tostring(reason or "unknown") .. ".")
        return false
    end

    appendStarterActivity(worker, "Joined your colony and is now following you.")
    return true
end

local function ensureStarterColonists(player, args)
    if not player or not Config or not Registry or not Registry.CreateWorker then
        return
    end

    local starterCount = getRequestedStarterCount(args)
    if starterCount <= 0 then
        return
    end

    local owner = Config.GetOwnerUsername and Config.GetOwnerUsername(player) or "local"
    local colonyData = Registry.GetColonyData and Registry.GetColonyData(owner, true) or nil
    local workersData = Registry.GetWorkersData and Registry.GetWorkersData(owner, true) or nil
    if not colonyData or not workersData then
        return
    end

    local existingWorkerIDs = (workersData and workersData.workerIDs) or {}
    local existingCount = #existingWorkerIDs
    local identityChanged = false
    for _, workerID in ipairs(existingWorkerIDs) do
        local existingWorker = Registry.GetWorkerForOwner and Registry.GetWorkerForOwner(owner, workerID) or nil
        if existingWorker and syncStarterWorkerIdentity(existingWorker) then
            identityChanged = true
        end
    end
    local playerGrantKey = getStarterGrantKey(player, owner)
    local grantedPlayers, grantedCounts = applyLegacyStarterGrantState(colonyData, owner, starterCount, existingCount)
    local grantedCount = math.max(0, math.floor(tonumber(grantedCounts[playerGrantKey]) or 0))
    local missingCount = math.max(0, starterCount - grantedCount)
    if missingCount <= 0 then
        grantedPlayers[playerGrantKey] = true
        colonyData.starterColonistsGranted = true
        if identityChanged and Registry and Registry.TouchWorkersVersion then
            Registry.TouchWorkersVersion(owner)
        end
        if Registry.Save then
            Registry.Save()
        end
        return
    end

    local createdAny = identityChanged
    for index = 1, missingCount do
        local worker = createStarterWorker(player, owner, grantedCount + index)
        if worker and DynamicTrading_Factions and DynamicTrading_Factions.OnColonyWorkerCreated then
            DynamicTrading_Factions.OnColonyWorkerCreated(owner, worker)
        end
        if worker then
            bootstrapStarterFollower(player, worker)
            grantedCount = grantedCount + 1
            grantedCounts[playerGrantKey] = grantedCount
            createdAny = true
        end
    end

    grantedPlayers[playerGrantKey] = grantedCount >= starterCount
    colonyData.starterColonistsGranted = true
    if createdAny and Registry and Registry.TouchWorkersVersion then
        Registry.TouchWorkersVersion(owner)
    end
    if Registry.Save then
        Registry.Save()
    end
end

Network.Handlers.RequestPlayerWorkers = function(player, args)
    ensureStarterColonists(player, args)
    Network.Internal.syncWorkerList(player, args and args.knownVersion)
end

Internal.EnsureStarterColonists = ensureStarterColonists

Network.Handlers.RequestWorkerDetails = function(player, args)
    if not args or not args.workerID then return end
    Network.Internal.syncWorkerDetail(
        player,
        args.workerID,
        args.knownVersion,
        args.includeWorkerLedgers == true
    )
end

Network.Handlers.RequestWarehouse = function(player, args)
    Network.Internal.syncWarehouse(
        player,
        args and args.knownVersion,
        args and args.includeLedgers == true
    )
end

return Network

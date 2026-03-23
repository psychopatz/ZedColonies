require "DT/Common/Map/DT_MapDisplaySystem"
require "DT/Common/ZedColonies/LabourConfig/DT_LabourConfig"

DT_Labour = DT_Labour or {}
DT_Labour.MapProvider = DT_Labour.MapProvider or {}

local Config = DT_Labour.Config or {}
local Provider = DT_Labour.MapProvider
local MapDisplay = DynamicTrading and DynamicTrading.MapDisplay or nil

if isServer() and not isClient() then
    return Provider
end

Provider.ID = Provider.ID or "LabourScavengeSite"
Provider.updateIntervalTicks = Provider.updateIntervalTicks or 90
Provider.requestIntervalTicks = Provider.requestIntervalTicks or 600
Provider.SymbolIDs = Provider.SymbolIDs or {
    ScavengeSite = "Target"
}

local function getWorkerList(playerObj, state)
    if isClient() and not isServer() then
        return state and state.cachedWorkers or {}
    end

    if DT_Labour and DT_Labour.Registry and DT_Labour.Registry.GetWorkerSummariesForOwner then
        local owner = Config.GetOwnerUsername and Config.GetOwnerUsername(playerObj) or "local"
        return DT_Labour.Registry.GetWorkerSummariesForOwner(owner) or {}
    end

    return {}
end

local function isTrackedScavengeWorker(worker)
    if not worker then
        return false
    end

    local normalizedJob = Config.NormalizeJobType and Config.NormalizeJobType(worker.jobType) or tostring(worker.jobType or "")
    if normalizedJob ~= ((Config.JobTypes or {}).Scavenge) then
        return false
    end

    if worker.workX == nil or worker.workY == nil or not worker.assignedSiteID then
        return false
    end

    if worker.jobEnabled ~= true then
        return false
    end

    local presenceState = tostring(worker.presenceState or "")
    local states = Config.PresenceStates or {}
    return presenceState == tostring(states.AwayToSite or "")
        or presenceState == tostring(states.Scavenging or "")
end

local function getWorkerTint(worker)
    local presenceState = tostring(worker and worker.presenceState or "")
    local states = Config.PresenceStates or {}

    if presenceState == tostring(states.Scavenging or "") then
        return 0.18, 0.78, 0.32, 0.95
    end

    return 0.95, 0.70, 0.16, 0.92
end

function Provider.getOwnedSymbolIDs(state)
    return {
        Provider.SymbolIDs.ScavengeSite
    }
end

function Provider.shouldRequestSync(playerObj, state)
    return #((state and state.cachedWorkers) or {}) <= 0
        and not (state and state.awaitingWorkerSync)
end

function Provider.requestSync(playerObj, state)
    if not (isClient() and not isServer()) or not playerObj then
        return
    end

    if state then
        state.awaitingWorkerSync = true
    end
    sendClientCommand(playerObj, Config.COMMAND_MODULE or "DynamicTrading_V2", "RequestPlayerWorkers", {})
end

function Provider.onServerCommand(module, command, args, state)
    if module ~= (Config.COMMAND_MODULE or "DynamicTrading_V2") then
        return
    end

    if command == "SyncPlayerWorkers" then
        if not state then
            return
        end
        state.awaitingWorkerSync = false
        state.cachedWorkers = args and args.workers or {}
    end
end

function Provider.getMarkers(playerObj, state)
    local markers = {}

    for _, worker in ipairs(getWorkerList(playerObj, state)) do
        if isTrackedScavengeWorker(worker) then
            local r, g, b, a = getWorkerTint(worker)
            markers[#markers + 1] = {
                symbolID = Provider.SymbolIDs.ScavengeSite,
                x = worker.workX,
                y = worker.workY,
                r = r,
                g = g,
                b = b,
                a = a,
                scale = ((ISMap and ISMap.SCALE) or 1) * 0.85,
                anchorX = 0.5,
                anchorY = 0.5
            }
        end
    end

    return markers
end

if MapDisplay and MapDisplay.RegisterProvider then
    MapDisplay.RegisterProvider(Provider.ID, Provider)
end

return Provider

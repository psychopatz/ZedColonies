DT_Labour = DT_Labour or {}
DT_Labour.Network = DT_Labour.Network or {}

local Config = DT_Labour.Config
local Registry = DT_Labour.Registry
local Network = DT_Labour.Network
local Shared = (Network.Workers or {}).Shared or {}

Network.Handlers = Network.Handlers or {}

local function buildNaturalList(values)
    local count = #(values or {})
    if count <= 0 then
        return ""
    end
    if count == 1 then
        return tostring(values[1])
    end
    if count == 2 then
        return tostring(values[1]) .. " and " .. tostring(values[2])
    end
    return tostring(values[1]) .. ", " .. tostring(values[2]) .. ", and " .. tostring(count - 2) .. " more"
end

local function dropWorkerHaulEntries(worker, indexes)
    local droppedCount = 0
    local droppedWeight = 0
    local sampleNames = {}
    local hiddenNames = 0

    table.sort(indexes or {}, function(a, b)
        return (tonumber(a) or 0) > (tonumber(b) or 0)
    end)

    for _, index in ipairs(indexes or {}) do
        local entry = worker and worker.haulLedger and worker.haulLedger[index] or nil
        if entry and entry.fullType then
            local qty = math.max(1, tonumber(entry.qty) or 1)
            local displayName = Registry.Internal.GetDisplayNameForFullType(entry.fullType) or tostring(entry.fullType)
            local unitWeight = math.max(0, tonumber(Config.GetItemWeight and Config.GetItemWeight(entry.fullType)) or 0)
            local entryName = qty > 1 and (displayName .. " x" .. tostring(qty)) or displayName
            droppedCount = droppedCount + qty
            droppedWeight = droppedWeight + (unitWeight * qty)
            if #sampleNames < 2 then
                sampleNames[#sampleNames + 1] = entryName
            else
                hiddenNames = hiddenNames + 1
            end
            table.remove(worker.haulLedger, index)
        end
    end

    return droppedCount, droppedWeight, sampleNames, hiddenNames
end

Network.Handlers.DropWorkerHaulEntries = function(player, args)
    if not args or not args.workerID then return end

    local owner = Config.GetOwnerUsername(player)
    local worker = Registry.GetWorkerForOwner(owner, args.workerID)
    if not worker then return end

    local normalizedJob = Config.NormalizeJobType and Config.NormalizeJobType(worker.jobType) or tostring(worker.jobType or "")
    if normalizedJob ~= ((Config.JobTypes or {}).Scavenge) then
        return
    end

    local droppedCount, droppedWeight, sampleNames, hiddenNames = dropWorkerHaulEntries(worker, Shared.normalizeLedgerIndexes(args))
    if droppedCount <= 0 then
        return
    end

    local logText = "Dropped " .. tostring(droppedCount) .. " hauled item" .. (droppedCount == 1 and "" or "s")
        .. " (" .. string.format("%.2f", math.max(0, droppedWeight)) .. " weight)"
    local nameText = buildNaturalList(sampleNames)
    if hiddenNames > 0 then
        if nameText ~= "" then
            nameText = nameText .. ", and " .. tostring(hiddenNames) .. " more"
        else
            nameText = tostring(hiddenNames) .. " more"
        end
    end
    if nameText ~= "" then
        logText = logText .. ": " .. nameText .. "."
    else
        logText = logText .. "."
    end
    Registry.Internal.AppendActivityLog(worker, logText, Shared.getCurrentWorldHours(), "haul")

    Shared.saveAndRefreshProcessed(player, worker, false)
end

return Network

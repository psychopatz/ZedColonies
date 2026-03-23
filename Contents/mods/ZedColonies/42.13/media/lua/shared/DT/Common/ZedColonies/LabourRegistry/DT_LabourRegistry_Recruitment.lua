DT_Labour = DT_Labour or {}
DT_Labour.Registry = DT_Labour.Registry or {}
DT_Labour.Registry.Internal = DT_Labour.Registry.Internal or {}

local Config = DT_Labour.Config
local Registry = DT_Labour.Registry
local Internal = Registry.Internal

function Registry.GetRecruitAttempt(ownerUsername, sourceNPCID)
    if not sourceNPCID then return nil end
    local ownerData = Registry.EnsureOwner(ownerUsername)
    return ownerData.recruitAttempts[tostring(sourceNPCID)]
end

function Registry.SetRecruitAttempt(ownerUsername, sourceNPCID, attemptData)
    if not sourceNPCID then return nil end
    local ownerData = Registry.EnsureOwner(ownerUsername)
    local key = tostring(sourceNPCID)
    if attemptData == nil then
        ownerData.recruitAttempts[key] = nil
        return nil
    end

    ownerData.recruitAttempts[key] = Internal.CopyShallow(attemptData)
    return ownerData.recruitAttempts[key]
end

function Registry.FindWorkerBySourceID(ownerUsername, sourceNPCID)
    if not sourceNPCID then return nil end

    local owner = Config.GetOwnerUsername(ownerUsername)
    for _, worker in ipairs(Registry.GetWorkersForOwner(owner)) do
        if worker.sourceNPCID and tostring(worker.sourceNPCID) == tostring(sourceNPCID) then
            return worker
        end
    end

    return nil
end

return Registry

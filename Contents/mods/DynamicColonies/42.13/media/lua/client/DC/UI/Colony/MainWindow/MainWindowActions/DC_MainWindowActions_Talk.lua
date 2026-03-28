DC_MainWindow = DC_MainWindow or {}

pcall(require, "DT/V2/NPC/DTNPC_ClientVisuals")
pcall(require, "DT/V2/NPC/UI/DTNPC_TraderDialogue_Hub")

local function normalizeUUID(value)
    local text = value and tostring(value) or ""
    return text ~= "" and text or nil
end

local function getSelectedWorker(window)
    return window and (window.selectedWorker or window.selectedWorkerSummary) or nil
end

local function getWorkerCompanionUUID(worker)
    if type(worker) ~= "table" then
        return nil
    end

    local candidates = {
        worker.companionNPCUUID,
        worker.tradeSoulUUID,
        worker.sourceNPCUUID,
        worker.recruitedTraderUUID,
        worker.sourceNPCID,
    }

    for _, candidate in ipairs(candidates) do
        local uuid = normalizeUUID(candidate)
        if uuid then
            return uuid
        end
    end

    return nil
end

function DC_MainWindow:onOpenTalk()
    local worker = getSelectedWorker(self)
    if not worker then
        self:updateStatus("Select a worker first.")
        return
    end

    local uuid = getWorkerCompanionUUID(worker)
    if not uuid then
        self:updateStatus("That worker does not have a recruited companion to talk to.")
        return
    end

    local zombie = DTNPCClient and DTNPCClient.FindZombieByUUID and DTNPCClient.FindZombieByUUID(uuid) or nil
    if not zombie then
        self:updateStatus("That companion is not nearby to talk to right now.")
        return
    end

    local player = getSpecificPlayer and getSpecificPlayer(0) or getPlayer and getPlayer() or nil
    if not player then
        self:updateStatus("Player not ready yet.")
        return
    end

    if not DTNPC_TraderDialogue_Hub or not DTNPC_TraderDialogue_Hub.Init then
        self:updateStatus("Companion dialogue is not available right now.")
        return
    end

    DTNPC_TraderDialogue_Hub.Init(nil, zombie, player)
    self:updateStatus("Opening companion dialogue...")
end

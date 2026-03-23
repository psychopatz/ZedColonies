require "ISUI/ISModalDialog"

DT_SupplyWindow = DT_SupplyWindow or {}
DT_SupplyWindow.Internal = DT_SupplyWindow.Internal or {}
DT_Labour = DT_Labour or {}
DT_Labour.UI = DT_Labour.UI or {}

local Internal = DT_SupplyWindow.Internal

if not DT_Labour.UI.ShowNoticeModal then
    function DT_Labour.UI.ShowNoticeModal(message)
        local text = tostring(message or "")
        if text == "" then
            return
        end

        if DT_Labour.UI.activeNoticeText == text then
            return
        end

        DT_Labour.UI.activeNoticeText = text

        local function onClose()
            DT_Labour.UI.activeNoticeText = nil
        end

        local modal = ISModalDialog:new(0, 0, 420, 180, text, true, nil, onClose, nil)
        modal:initialise()
        modal:addToUIManager()
        modal:setX((getCore():getScreenWidth() - modal:getWidth()) / 2)
        modal:setY((getCore():getScreenHeight() - modal:getHeight()) / 2)
        modal:bringToTop()
    end
end

local function onServerCommand(module, command, args)
    if module ~= Internal.getCommandModule() then
        return
    end
    if not DT_SupplyWindow.instance or not DT_SupplyWindow.instance:getIsVisible() then
        return
    end
    if command == "SyncWorkerDetails" then
        local worker = args and args.worker or nil
        if worker and worker.workerID == DT_SupplyWindow.instance.workerID then
            local cache = DT_MainWindow and DT_MainWindow.cachedDetails or nil
            local cachedWorker = cache and cache[worker.workerID] or nil
            local currentWorker = DT_SupplyWindow.instance.workerData
            local mergeWorkerDetail = DT_MainWindow and DT_MainWindow.MergeWorkerDetail or nil
            local mergedWorker = worker

            if mergeWorkerDetail then
                mergedWorker = mergeWorkerDetail(cachedWorker or currentWorker, worker)
            end

            if cache then
                cache[worker.workerID] = mergedWorker
            end

            DT_SupplyWindow.instance:setWorkerData(mergedWorker)
            if DT_SupplyWindow.instance.autoRefreshPending then
                DT_SupplyWindow.instance.autoRefreshPending = nil
            else
                DT_SupplyWindow.instance:updateStatus("Supply reserves refreshed for " .. tostring(worker.name or worker.workerID) .. ".")
            end
        elseif args and args.workerID and args.workerID == DT_SupplyWindow.instance.workerID then
            DT_SupplyWindow.instance:updateStatus("This worker record was removed.")
            DT_SupplyWindow.instance:close()
        end
    elseif command == "LabourNotice" then
        if args and args.message then
            DT_SupplyWindow.instance:updateStatus(args.message)
        end
        if args and args.popup == true and DT_Labour.UI and DT_Labour.UI.ShowNoticeModal then
            DT_Labour.UI.ShowNoticeModal(args.message)
        end
    end
end

if not DT_SupplyWindow.EventsAdded then
    Events.OnServerCommand.Add(onServerCommand)
    DT_SupplyWindow.EventsAdded = true
end

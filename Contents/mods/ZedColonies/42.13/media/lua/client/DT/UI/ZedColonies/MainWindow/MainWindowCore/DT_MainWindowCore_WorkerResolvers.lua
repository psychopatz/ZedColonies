DT_MainWindow = DT_MainWindow or {}
DT_MainWindow.Internal = DT_MainWindow.Internal or {}

local Internal = DT_MainWindow.Internal

function Internal.resolveWorkerSummaries()
    if isClient() and not isServer() then
        return DT_MainWindow.cachedWorkers or {}
    end

    if DT_Labour and DT_Labour.Registry and DT_Labour.Registry.GetWorkerSummariesForOwner then
        return DT_Labour.Registry.GetWorkerSummariesForOwner(Internal.getOwnerUsername())
    end

    return {}
end

function Internal.resolveWorkerDetail(workerID)
    if not workerID then
        return nil
    end

    if isClient() and not isServer() then
        local cache = DT_MainWindow.cachedDetails or {}
        return cache[workerID]
    end

    if DT_Labour and DT_Labour.Registry and DT_Labour.Registry.GetWorkerDetailsForOwner then
        return DT_Labour.Registry.GetWorkerDetailsForOwner(Internal.getOwnerUsername(), workerID)
    end

    return nil
end

